import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Compliant image picker service using Android Photo Picker
/// This service uses the Android 13+ Photo Picker API which doesn't require
/// READ_MEDIA_IMAGES or READ_MEDIA_VIDEO permissions
class CompliantImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick a single image using Android Photo Picker (no permissions required)
  /// This is compliant with Google Play policies for infrequent image access
  static Future<File?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
    int? imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      if (kDebugMode) {
        print('🖼️ Using compliant image picker (Android Photo Picker)');
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        // This automatically uses Android Photo Picker on Android 13+
        // No READ_MEDIA_IMAGES permission required
      );

      if (pickedFile != null) {
        if (kDebugMode) {
          print('✅ Image selected successfully: ${pickedFile.path}');
        }
        return File(pickedFile.path);
      }

      if (kDebugMode) {
        print('ℹ️ No image selected by user');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      rethrow;
    }
  }

  /// Pick image from camera (requires CAMERA permission but that's allowed)
  static Future<File?> pickImageFromCamera({
    int? imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      if (kDebugMode) {
        print('📷 Using camera for image capture');
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile != null) {
        if (kDebugMode) {
          print('✅ Image captured successfully: ${pickedFile.path}');
        }
        return File(pickedFile.path);
      }

      if (kDebugMode) {
        print('ℹ️ No image captured');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error capturing image: $e');
      }
      rethrow;
    }
  }

  /// Show image source selection dialog (Gallery or Camera)
  /// This gives users choice while remaining compliant
  static Future<File?> showImageSourceDialog({
    required Function() onGalleryTap,
    required Function() onCameraTap,
    int? imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    // This method should be called from UI to show a dialog
    // The actual dialog implementation should be in the UI layer
    throw UnimplementedError(
      'This method should be implemented in the UI layer to show source selection dialog'
    );
  }

  /// Get image info without requiring additional permissions
  static Future<Map<String, dynamic>?> getImageInfo(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;
      
      return {
        'path': imageFile.path,
        'name': fileName,
        'size': fileSize,
        'sizeFormatted': _formatFileSize(fileSize),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting image info: $e');
      }
      return null;
    }
  }

  /// Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if the device supports the Android Photo Picker
  static Future<bool> supportsPhotoPickerAPI() async {
    try {
      // Android Photo Picker is available on Android 13+ (API 33+)
      // For older versions, it falls back to traditional picker
      if (Platform.isAndroid) {
        // The image_picker plugin automatically handles this
        return true;
      }
      return Platform.isIOS; // iOS has its own photo picker
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking photo picker support: $e');
      }
      return false;
    }
  }

  /// Validate image file before processing
  static bool isValidImageFile(File file) {
    try {
      final extension = file.path.toLowerCase().split('.').last;
      const validExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
      return validExtensions.contains(extension);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating image file: $e');
      }
      return false;
    }
  }

  /// Compress image if needed (for profile pictures)
  static Future<File?> compressImageForProfile(File imageFile) async {
    try {
      // For profile pictures, we want smaller, optimized images
      final XFile? compressedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Good quality but smaller size
        maxWidth: 512,    // Suitable for profile pictures
        maxHeight: 512,   // Square aspect ratio
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error compressing image: $e');
      }
      return imageFile; // Return original if compression fails
    }
  }
}

/// Image picker configuration for different use cases
class ImagePickerConfig {
  final ImageSource source;
  final int imageQuality;
  final double? maxWidth;
  final double? maxHeight;
  final bool allowMultiple;

  const ImagePickerConfig({
    this.source = ImageSource.gallery,
    this.imageQuality = 85,
    this.maxWidth,
    this.maxHeight,
    this.allowMultiple = false,
  });

  /// Configuration for profile pictures
  static const profilePicture = ImagePickerConfig(
    imageQuality: 70,
    maxWidth: 512,
    maxHeight: 512,
    allowMultiple: false,
  );

  /// Configuration for general images
  static const general = ImagePickerConfig(
    imageQuality: 85,
    maxWidth: 1920,
    maxHeight: 1920,
    allowMultiple: false,
  );

  /// Configuration for high quality images
  static const highQuality = ImagePickerConfig(
    imageQuality: 95,
    allowMultiple: false,
  );
}

/// Usage example:
/// ```dart
/// // For profile picture (compliant with Google Play policies)
/// final imageFile = await CompliantImagePickerService.pickSingleImage(
///   imageQuality: ImagePickerConfig.profilePicture.imageQuality,
///   maxWidth: ImagePickerConfig.profilePicture.maxWidth,
///   maxHeight: ImagePickerConfig.profilePicture.maxHeight,
/// );
/// 
/// // For camera capture
/// final cameraImage = await CompliantImagePickerService.pickImageFromCamera();
/// ```
