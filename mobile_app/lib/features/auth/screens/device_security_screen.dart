import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/mobile_user_auth_provider.dart';
import '../../../core/services/device_auth_service.dart';
import '../../../core/widgets/secure_screen_wrapper.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/theme/app_theme.dart';

class DeviceSecurityScreen extends ConsumerStatefulWidget {
  const DeviceSecurityScreen({super.key});

  @override
  ConsumerState<DeviceSecurityScreen> createState() => _DeviceSecurityScreenState();
}

class _DeviceSecurityScreenState extends ConsumerState<DeviceSecurityScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _deviceInfo;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _deviceId = await DeviceAuthService.getDeviceId();
      _deviceInfo = await DeviceAuthService.getDeviceInfo();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load device information');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentMobileUserProvider);

    return SecureScreenWrapper(
      enableScreenshotPrevention: true,
      enableScreenRecordingPrevention: true,
      showWarningOnRecording: true,
      customWarningMessage: 'Screenshots and screen recording are not allowed in security settings.',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Device Security',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Status Card
                    _buildSecurityStatusCard(),
                    const SizedBox(height: 24),

                    // Device Information Card
                    _buildDeviceInfoCard(),
                    const SizedBox(height: 24),

                    // Security Features Card
                    _buildSecurityFeaturesCard(),
                    const SizedBox(height: 24),

                    // Account Security Card
                    _buildAccountSecurityCard(user),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Security Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Your device is secure and protected',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This device is registered and bound to your account. Only this device can access your account for enhanced security.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registered Device Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_deviceInfo != null) ...[
              _buildInfoRow('Device Model', _deviceInfo!['model'] ?? 'Unknown'),
              _buildInfoRow('Device Brand', _deviceInfo!['brand'] ?? 'Unknown'),
              _buildInfoRow('Operating System', _deviceInfo!['systemName'] ?? 'Unknown'),
              _buildInfoRow('OS Version', _deviceInfo!['systemVersion'] ?? 'Unknown'),
              _buildInfoRow('Device ID', _maskDeviceId(_deviceId ?? 'Unknown')),
            ] else
              const Text(
                'Loading device information...',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeaturesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Security Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityFeature(
              Icons.screenshot_monitor,
              'Screenshot Prevention',
              'Screenshots are blocked in sensitive areas',
              true,
            ),
            _buildSecurityFeature(
              Icons.videocam_off,
              'Screen Recording Protection',
              'Screen recording is detected and blocked',
              true,
            ),
            _buildSecurityFeature(
              Icons.phone_android,
              'Device Binding',
              'Account is bound to this specific device',
              true,
            ),
            _buildSecurityFeature(
              Icons.security,
              'Multi-User Prevention',
              'Prevents multiple users on same device',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(IconData icon, String title, String description, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard(MobileUser? user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              _buildInfoRow('Account Email', user.email),
              _buildInfoRow('Device Bound', user.isDeviceBound ? 'Yes' : 'No'),
              _buildInfoRow('Last Login', _formatDate(user.lastLoginAt)),
              _buildInfoRow('Account Status', user.isActive ? 'Active' : 'Inactive'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Important Security Notes:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Your account is bound to this device for security\n'
              '• You cannot login from other devices\n'
              '• Screenshots are prevented in sensitive areas\n'
              '• Screen recording is detected and blocked\n'
              '• Only one user can be logged in per device',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskDeviceId(String deviceId) {
    if (deviceId.length <= 8) return deviceId;
    return '${deviceId.substring(0, 4)}****${deviceId.substring(deviceId.length - 4)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
