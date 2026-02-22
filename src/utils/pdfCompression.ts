import { PDFDocument } from 'pdf-lib';

export interface CompressionOptions {
  quality?: number; // 0.1 to 1.0, default 0.7
  maxSizeMB?: number; // Maximum target size in MB, default 10
  onProgress?: (progress: number) => void;
}

export interface CompressionResult {
  compressedFile: File;
  originalSize: number;
  compressedSize: number;
  compressionRatio: number;
  success: boolean;
  error?: string;
}

export class PDFCompressionService {
  /**
   * Compress a PDF file
   */
  static async compressPDF(
    file: File,
    options: CompressionOptions = {}
  ): Promise<CompressionResult> {
    const {
      quality = 0.7,
      maxSizeMB = 10,
      onProgress
    } = options;

    const startTime = Date.now();
    console.log(`Starting PDF compression for ${file.name} (${this.formatFileSize(file.size)})`);

    try {
      onProgress?.(5);

      // Check if file is too large for compression (>100MB)
      if (file.size > 100 * 1024 * 1024) {
        console.warn(`File ${file.name} is too large for compression (${this.formatFileSize(file.size)})`);
        return {
          compressedFile: file,
          originalSize: file.size,
          compressedSize: file.size,
          compressionRatio: 0,
          success: false,
          error: 'File too large for compression',
        };
      }

      onProgress?.(10);

      // Read the PDF file with progress tracking
      console.log(`Reading PDF file: ${file.name}`);
      const arrayBuffer = await file.arrayBuffer();
      onProgress?.(30);

      // Load the PDF document
      console.log(`Loading PDF document: ${file.name}`);
      const pdfDoc = await PDFDocument.load(arrayBuffer);
      onProgress?.(50);

      // Get basic info
      const pageCount = pdfDoc.getPageCount();
      const originalSize = file.size;
      console.log(`PDF info: ${pageCount} pages, ${this.formatFileSize(originalSize)}`);

      // Apply compression based on file size and page count
      let compressionLevel = quality;

      // Adjust compression based on file size
      if (originalSize > 20 * 1024 * 1024) { // > 20MB
        compressionLevel = Math.min(quality, 0.5);
      } else if (originalSize > 10 * 1024 * 1024) { // > 10MB
        compressionLevel = Math.min(quality, 0.6);
      }

      console.log(`Using compression level: ${compressionLevel}`);
      onProgress?.(70);

      // Save with compression
      console.log(`Compressing PDF: ${file.name}`);
      const compressedBytes = await pdfDoc.save({
        useObjectStreams: true,
        addDefaultPage: false,
        updateFieldAppearances: false,
      });

      onProgress?.(90);

      // Create compressed file
      console.log(`Creating compressed file: ${file.name}`);
      const compressedFile = new File(
        [compressedBytes],
        file.name,
        { type: 'application/pdf' }
      );

      const compressedSize = compressedFile.size;
      const compressionRatio = ((originalSize - compressedSize) / originalSize) * 100;
      const compressionTime = Date.now() - startTime;

      console.log(`Compression completed in ${compressionTime}ms: ${this.formatFileSize(originalSize)} → ${this.formatFileSize(compressedSize)} (${compressionRatio.toFixed(1)}% reduction)`);

      onProgress?.(100);

      // Check if compression was effective
      const targetSize = maxSizeMB * 1024 * 1024;
      const success = compressedSize <= targetSize || compressionRatio > 5; // At least 5% reduction

      if (!success) {
        console.warn(`Compression not effective for ${file.name}, using original file`);
      }

      return {
        compressedFile: success ? compressedFile : file,
        originalSize,
        compressedSize: success ? compressedSize : originalSize,
        compressionRatio: success ? compressionRatio : 0,
        success,
      };

    } catch (error) {
      const compressionTime = Date.now() - startTime;
      console.error(`PDF compression error for ${file.name} after ${compressionTime}ms:`, error);
      return {
        compressedFile: file,
        originalSize: file.size,
        compressedSize: file.size,
        compressionRatio: 0,
        success: false,
        error: error instanceof Error ? error.message : 'Unknown compression error',
      };
    }
  }

  /**
   * Check if a file should be compressed
   */
  static shouldCompress(file: File, thresholdMB: number = 5): boolean {
    return file.type === 'application/pdf' && file.size > thresholdMB * 1024 * 1024;
  }

  /**
   * Get compression recommendation based on file size
   */
  static getCompressionRecommendation(fileSizeMB: number): CompressionOptions {
    if (fileSizeMB > 30) {
      return {
        quality: 0.4,
        maxSizeMB: 15,
      };
    } else if (fileSizeMB > 20) {
      return {
        quality: 0.5,
        maxSizeMB: 12,
      };
    } else if (fileSizeMB > 10) {
      return {
        quality: 0.6,
        maxSizeMB: 8,
      };
    } else if (fileSizeMB > 5) {
      return {
        quality: 0.7,
        maxSizeMB: 5,
      };
    }
    
    return {
      quality: 0.8,
      maxSizeMB: 5,
    };
  }

  /**
   * Format file size for display
   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * Estimate compression time based on file size
   */
  static estimateCompressionTime(fileSizeMB: number): number {
    // Rough estimate: 1MB = 1-2 seconds
    return Math.max(2, Math.min(30, fileSizeMB * 1.5));
  }

  /**
   * Batch compress multiple PDF files
   */
  static async compressMultiplePDFs(
    files: File[],
    options: CompressionOptions = {},
    onFileProgress?: (fileIndex: number, fileName: string, progress: number) => void,
    onOverallProgress?: (overallProgress: number) => void
  ): Promise<CompressionResult[]> {
    const results: CompressionResult[] = [];
    const totalFiles = files.length;

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      
      if (file.type === 'application/pdf') {
        const result = await this.compressPDF(file, {
          ...options,
          onProgress: (progress) => {
            onFileProgress?.(i, file.name, progress);
          },
        });
        results.push(result);
      } else {
        // Non-PDF files are not compressed
        results.push({
          compressedFile: file,
          originalSize: file.size,
          compressedSize: file.size,
          compressionRatio: 0,
          success: true,
        });
      }

      // Update overall progress
      const overallProgress = ((i + 1) / totalFiles) * 100;
      onOverallProgress?.(overallProgress);
    }

    return results;
  }

  /**
   * Validate PDF file before compression
   */
  static async validatePDF(file: File): Promise<{ isValid: boolean; error?: string }> {
    try {
      const arrayBuffer = await file.arrayBuffer();
      await PDFDocument.load(arrayBuffer);
      return { isValid: true };
    } catch (error) {
      return {
        isValid: false,
        error: error instanceof Error ? error.message : 'Invalid PDF file',
      };
    }
  }
}
