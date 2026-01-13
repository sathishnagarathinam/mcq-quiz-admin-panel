import { ref, uploadBytesResumable, getDownloadURL, deleteObject } from 'firebase/storage';
import { storage } from '../config/firebase';
import { FileAttachment, UploadProgress } from '../types/examHub';
import { Timestamp } from 'firebase/firestore';
import { PDFCompressionService, CompressionOptions } from '../utils/pdfCompression';

// Allowed file types for exam hub
const ALLOWED_FILE_TYPES = {
  'application/pdf': '.pdf',
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'application/msword': '.doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
};

// Maximum file size (50MB for PDFs, 10MB for others)
const MAX_FILE_SIZE = 10 * 1024 * 1024;
const MAX_PDF_SIZE = 50 * 1024 * 1024;

export interface UploadOptions {
  category: 'news' | 'tips' | 'papers' | 'results';
  onProgress?: (progress: UploadProgress) => void;
  onError?: (error: string) => void;
  onSuccess?: (attachment: FileAttachment) => void;
  compression?: CompressionOptions;
  enableCompression?: boolean; // Default: true for PDFs
  saveToFirestore?: boolean; // Default: true - automatically save to Firestore
  createdBy?: string; // Required if saveToFirestore is true
  metadata?: {
    title?: string;
    description?: string;
    examType?: string;
    examYear?: number;
  };
}

export class FileUploadService {
  /**
   * Validate file before upload
   */
  static validateFile(file: File): { isValid: boolean; error?: string } {
    // Check file type
    if (!ALLOWED_FILE_TYPES[file.type as keyof typeof ALLOWED_FILE_TYPES]) {
      return {
        isValid: false,
        error: `File type ${file.type} is not allowed. Please upload PDF, DOC, DOCX, or image files.`,
      };
    }

    // Check file size (different limits for PDFs vs other files)
    const maxSize = file.type === 'application/pdf' ? MAX_PDF_SIZE : MAX_FILE_SIZE;
    if (file.size > maxSize) {
      const maxSizeMB = (maxSize / (1024 * 1024)).toFixed(1);
      const fileSizeMB = (file.size / 1024 / 1024).toFixed(2);
      return {
        isValid: false,
        error: `File size ${fileSizeMB}MB exceeds the maximum limit of ${maxSizeMB}MB for ${file.type === 'application/pdf' ? 'PDF files' : 'this file type'}.`,
      };
    }

    return { isValid: true };
  }

  /**
   * Generate unique file name
   */
  static generateFileName(originalName: string, category: string): string {
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(2, 15);
    const extension = originalName.substring(originalName.lastIndexOf('.'));
    return `${category}_${timestamp}_${randomString}${extension}`;
  }

  /**
   * Upload file to Firebase Storage
   */
  static async uploadFile(
    file: File,
    options: UploadOptions
  ): Promise<FileAttachment> {
    return new Promise(async (resolve, reject) => {
      // Set up timeout for the entire upload process
      const uploadTimeout = setTimeout(() => {
        reject(new Error('Upload timeout - the upload took too long to complete'));
      }, 5 * 60 * 1000); // 5 minutes timeout

      try {
        // Validate file
        const validation = this.validateFile(file);
        if (!validation.isValid) {
          clearTimeout(uploadTimeout);
          const error = validation.error || 'File validation failed';
          options.onError?.(error);
          reject(new Error(error));
          return;
        }

        // Initial progress
        options.onProgress?.({
          fileName: file.name,
          progress: 1,
          status: 'preparing',
        });

        // Compress PDF if enabled and applicable
        let fileToUpload = file;
        const shouldCompress = options.enableCompression !== false &&
                              PDFCompressionService.shouldCompress(file);

        if (shouldCompress) {
          console.log(`Starting compression for ${file.name} (${PDFCompressionService.formatFileSize(file.size)})`);

          options.onProgress?.({
            fileName: file.name,
            progress: 5,
            status: 'compressing',
          });

          const compressionOptions = options.compression ||
                                   PDFCompressionService.getCompressionRecommendation(file.size / (1024 * 1024));

          try {
            const compressionResult = await Promise.race([
              PDFCompressionService.compressPDF(file, {
                ...compressionOptions,
                onProgress: (progress) => {
                  // Map compression progress to 5-25% of total progress
                  const mappedProgress = 5 + (progress * 0.2);
                  options.onProgress?.({
                    fileName: file.name,
                    progress: mappedProgress,
                    status: 'compressing',
                  });
                },
              }),
              // Compression timeout (2 minutes for large files)
              new Promise<never>((_, reject) =>
                setTimeout(() => reject(new Error('Compression timeout')), 2 * 60 * 1000)
              )
            ]);

            if (compressionResult.success) {
              fileToUpload = compressionResult.compressedFile;
              console.log(`PDF compressed: ${PDFCompressionService.formatFileSize(compressionResult.originalSize)} → ${PDFCompressionService.formatFileSize(compressionResult.compressedSize)} (${compressionResult.compressionRatio.toFixed(1)}% reduction)`);
            } else {
              console.warn(`Compression failed for ${file.name}, uploading original file`);
            }
          } catch (compressionError) {
            console.warn(`Compression failed for ${file.name}:`, compressionError);
            // Continue with original file if compression fails
            fileToUpload = file;
          }
        }

        // Generate file path and name
        const fileName = this.generateFileName(file.name, options.category);
        const filePath = `exam_hub/${options.category}/${fileName}`;
        const storageRef = ref(storage, filePath);

        console.log(`Starting upload for ${fileName} (${PDFCompressionService.formatFileSize(fileToUpload.size)})`);

        // Create upload task with the (possibly compressed) file
        const uploadTask = uploadBytesResumable(storageRef, fileToUpload);

        // Track upload progress with timeout detection
        let lastProgressTime = Date.now();
        let lastBytesTransferred = 0;

        const progressInterval = setInterval(() => {
          const now = Date.now();
          const timeSinceLastProgress = now - lastProgressTime;

          // If no progress for 30 seconds, consider it stuck
          if (timeSinceLastProgress > 30000) {
            clearInterval(progressInterval);
            clearTimeout(uploadTimeout);
            uploadTask.cancel();
            reject(new Error('Upload appears to be stuck - no progress for 30 seconds'));
          }
        }, 5000); // Check every 5 seconds

        // Track upload progress
        uploadTask.on(
          'state_changed',
          (snapshot) => {
            const currentBytes = snapshot.bytesTransferred;

            // Update progress tracking
            if (currentBytes > lastBytesTransferred) {
              lastProgressTime = Date.now();
              lastBytesTransferred = currentBytes;
            }

            // Map upload progress to 25-100% of total progress (if compression was done)
            const uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            const totalProgress = shouldCompress ? 25 + (uploadProgress * 0.75) : uploadProgress;

            console.log(`Upload progress for ${file.name}: ${uploadProgress.toFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)`);

            options.onProgress?.({
              fileName: file.name,
              progress: totalProgress,
              status: 'uploading',
            });
          },
          (error) => {
            clearInterval(progressInterval);
            clearTimeout(uploadTimeout);
            console.error('Upload error:', error);
            const errorMessage = this.getUploadErrorMessage(error);
            options.onError?.(errorMessage);
            reject(new Error(errorMessage));
          },
          async () => {
            try {
              clearInterval(progressInterval);
              clearTimeout(uploadTimeout);

              console.log(`Upload completed for ${file.name}`);

              // Upload completed successfully
              const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);

              const attachment: FileAttachment = {
                id: fileName.split('.')[0], // Use filename without extension as ID
                name: fileName,
                originalName: file.name,
                url: downloadURL,
                size: fileToUpload.size, // Use compressed file size
                type: file.type,
                uploadedAt: Timestamp.now(),
              };

              // Automatically save to Firestore if enabled
              if (options.saveToFirestore !== false && options.createdBy) {
                try {
                  const { ExamHubService } = await import('./examHubService');
                  const documentId = await ExamHubService.saveUploadedFile(
                    attachment,
                    options.category,
                    options.createdBy,
                    options.metadata
                  );
                  console.log(`File saved to Firestore with document ID: ${documentId}`);
                } catch (firestoreError) {
                  console.warn('Failed to save file to Firestore:', firestoreError);
                  // Don't fail the upload if Firestore save fails
                }
              }

              options.onProgress?.({
                fileName: file.name,
                progress: 100,
                status: 'completed',
              });

              options.onSuccess?.(attachment);
              resolve(attachment);
            } catch (error) {
              clearInterval(progressInterval);
              clearTimeout(uploadTimeout);
              console.error('Error getting download URL:', error);
              const errorMessage = 'Failed to get download URL';
              options.onError?.(errorMessage);
              reject(new Error(errorMessage));
            }
          }
        );
      } catch (error) {
        clearTimeout(uploadTimeout);
        console.error('Upload preparation error:', error);
        const errorMessage = error instanceof Error ? error.message : 'Upload preparation failed';
        options.onError?.(errorMessage);
        reject(new Error(errorMessage));
      }
    });
  }

  /**
   * Upload multiple files with optimized strategy
   */
  static async uploadMultipleFiles(
    files: File[],
    options: UploadOptions,
    onOverallProgress?: (progress: number) => void
  ): Promise<FileAttachment[]> {
    const results: FileAttachment[] = [];
    const totalFiles = files.length;
    let completedFiles = 0;

    // Process files sequentially for better performance and progress tracking
    for (let i = 0; i < files.length; i++) {
      const file = files[i];

      try {
        const attachment = await this.uploadFile(file, {
          ...options,
          onProgress: (progress) => {
            // Calculate overall progress
            const fileProgress = progress.progress / 100;
            const overallProgress = ((completedFiles + fileProgress) / totalFiles) * 100;
            onOverallProgress?.(overallProgress);

            // Call original progress callback
            options.onProgress?.(progress);
          },
        });

        results.push(attachment);
        completedFiles++;

        // Update overall progress
        const overallProgress = (completedFiles / totalFiles) * 100;
        onOverallProgress?.(overallProgress);

      } catch (error) {
        console.error(`Failed to upload ${file.name}:`, error);
        // Continue with other files even if one fails
        completedFiles++;
        throw error; // Re-throw to maintain original behavior
      }
    }

    return results;
  }

  /**
   * Upload files with queue management (concurrent uploads)
   */
  static async uploadFilesWithQueue(
    files: File[],
    options: UploadOptions,
    maxConcurrent: number = 2,
    onOverallProgress?: (progress: number) => void,
    onFileComplete?: (fileName: string, success: boolean, error?: string) => void
  ): Promise<{ successful: FileAttachment[]; failed: { file: File; error: string }[] }> {
    const successful: FileAttachment[] = [];
    const failed: { file: File; error: string }[] = [];
    const totalFiles = files.length;
    let completedFiles = 0;

    // Create chunks for concurrent processing
    const chunks: File[][] = [];
    for (let i = 0; i < files.length; i += maxConcurrent) {
      chunks.push(files.slice(i, i + maxConcurrent));
    }

    for (const chunk of chunks) {
      const chunkPromises = chunk.map(async (file) => {
        try {
          const attachment = await this.uploadFile(file, {
            ...options,
            onProgress: (progress) => {
              // Individual file progress
              options.onProgress?.(progress);
            },
          });

          successful.push(attachment);
          onFileComplete?.(file.name, true);

        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Upload failed';
          failed.push({ file, error: errorMessage });
          onFileComplete?.(file.name, false, errorMessage);
        } finally {
          completedFiles++;
          const overallProgress = (completedFiles / totalFiles) * 100;
          onOverallProgress?.(overallProgress);
        }
      });

      // Wait for current chunk to complete before processing next chunk
      await Promise.allSettled(chunkPromises);
    }

    return { successful, failed };
  }

  /**
   * Delete file from Firebase Storage
   */
  static async deleteFile(attachment: FileAttachment): Promise<void> {
    try {
      // Extract file path from URL or construct it
      const filePath = this.getFilePathFromUrl(attachment.url) || 
                      `exam_hub/${attachment.name}`;
      const storageRef = ref(storage, filePath);
      await deleteObject(storageRef);
    } catch (error) {
      console.error('Error deleting file:', error);
      throw new Error('Failed to delete file from storage');
    }
  }

  /**
   * Delete multiple files
   */
  static async deleteMultipleFiles(attachments: FileAttachment[]): Promise<void> {
    const deletePromises = attachments.map(attachment => this.deleteFile(attachment));
    await Promise.all(deletePromises);
  }

  /**
   * Get file path from download URL
   */
  private static getFilePathFromUrl(url: string): string | null {
    try {
      const urlObj = new URL(url);
      const pathMatch = urlObj.pathname.match(/\/o\/(.+?)\?/);
      return pathMatch ? decodeURIComponent(pathMatch[1]) : null;
    } catch {
      return null;
    }
  }

  /**
   * Get user-friendly error message
   */
  private static getUploadErrorMessage(error: any): string {
    switch (error.code) {
      case 'storage/unauthorized':
        return 'You do not have permission to upload files';
      case 'storage/canceled':
        return 'Upload was canceled';
      case 'storage/quota-exceeded':
        return 'Storage quota exceeded';
      case 'storage/invalid-format':
        return 'Invalid file format';
      case 'storage/invalid-event-name':
        return 'Invalid upload event';
      case 'storage/invalid-url':
        return 'Invalid storage URL';
      case 'storage/invalid-argument':
        return 'Invalid upload argument';
      case 'storage/no-default-bucket':
        return 'No default storage bucket configured';
      case 'storage/cannot-slice-blob':
        return 'Cannot process file';
      case 'storage/server-file-wrong-size':
        return 'File size mismatch on server';
      default:
        return error.message || 'Upload failed due to an unknown error';
    }
  }

  /**
   * Get file size in human readable format
   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * Check if file type is PDF
   */
  static isPDF(file: File): boolean {
    return file.type === 'application/pdf';
  }

  /**
   * Check if file type is image
   */
  static isImage(file: File): boolean {
    return file.type.startsWith('image/');
  }

  /**
   * Check if file type is document
   */
  static isDocument(file: File): boolean {
    return file.type.includes('document') || file.type.includes('msword');
  }
}

export default FileUploadService;
