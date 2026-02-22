import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/compliant_image_picker_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_snackbar.dart';

/// Profile picture picker widget using compliant Android Photo Picker
/// This widget doesn't require READ_MEDIA_IMAGES permission
class ProfilePicturePicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(File imageFile) onImageSelected;
  final double size;

  const ProfilePicturePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.size = 100,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  File? _selectedImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryColor.withOpacity(0.1),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_selectedImage != null) {
      // Show selected image
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      // Show current profile image
      return ClipOval(
        child: Image.network(
          widget.currentImageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      // Show placeholder
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Stack(
      children: [
        Center(
          child: Icon(
            Icons.person,
            size: widget.size * 0.5,
            color: AppTheme.primaryColor,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Profile Picture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Gallery option (uses Android Photo Picker)
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.blue,
                          ),
                        ),
                        title: const Text('Choose from Gallery'),
                        subtitle: const Text('Select from your photos'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromGallery();
                        },
                      ),
                      
                      // Camera option
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.green,
                          ),
                        ),
                        title: const Text('Take Photo'),
                        subtitle: const Text('Capture with camera'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromCamera();
                        },
                      ),
                      
                      // Remove option (if image exists)
                      if (_selectedImage != null || 
                          (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty))
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                          title: const Text('Remove Photo'),
                          subtitle: const Text('Use default avatar'),
                          onTap: () {
                            Navigator.pop(context);
                            _removeImage();
                          },
                        ),
                      
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use compliant image picker (Android Photo Picker)
      final imageFile = await CompliantImagePickerService.pickSingleImage(
        source: ImageSource.gallery,
        imageQuality: ImagePickerConfig.profilePicture.imageQuality,
        maxWidth: ImagePickerConfig.profilePicture.maxWidth,
        maxHeight: ImagePickerConfig.profilePicture.maxHeight,
      );

      if (imageFile != null) {
        // Validate the image file
        if (CompliantImagePickerService.isValidImageFile(imageFile)) {
          setState(() {
            _selectedImage = imageFile;
          });
          
          // Notify parent widget
          widget.onImageSelected(imageFile);
          
          if (mounted) {
            CustomSnackbar.showSuccess(context, 'Profile picture selected!');
          }
        } else {
          if (mounted) {
            CustomSnackbar.showError(context, 'Please select a valid image file');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to select image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use camera (CAMERA permission is allowed for user-initiated actions)
      final imageFile = await CompliantImagePickerService.pickImageFromCamera(
        imageQuality: ImagePickerConfig.profilePicture.imageQuality,
        maxWidth: ImagePickerConfig.profilePicture.maxWidth,
        maxHeight: ImagePickerConfig.profilePicture.maxHeight,
      );

      if (imageFile != null) {
        // Validate the image file
        if (CompliantImagePickerService.isValidImageFile(imageFile)) {
          setState(() {
            _selectedImage = imageFile;
          });
          
          // Notify parent widget
          widget.onImageSelected(imageFile);
          
          if (mounted) {
            CustomSnackbar.showSuccess(context, 'Photo captured successfully!');
          }
        } else {
          if (mounted) {
            CustomSnackbar.showError(context, 'Failed to capture valid image');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to capture photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    
    if (mounted) {
      CustomSnackbar.showInfo(context, 'Profile picture removed');
    }
  }
}

/// Usage example:
/// ```dart
/// ProfilePicturePicker(
///   currentImageUrl: user.profileImageUrl,
///   onImageSelected: (File imageFile) async {
///     // Upload image to Firebase Storage
///     // Update user profile with new image URL
///   },
/// )
/// ```
