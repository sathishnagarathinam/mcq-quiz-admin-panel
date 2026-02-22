import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/mobile_user_auth_provider.dart';
import '../../../core/services/device_auth_service.dart';

/// Widget to display device registration status and information
class DeviceStatusWidget extends ConsumerStatefulWidget {
  const DeviceStatusWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceStatusWidget> createState() => _DeviceStatusWidgetState();
}

class _DeviceStatusWidgetState extends ConsumerState<DeviceStatusWidget> {
  String? _deviceId;
  Map<String, dynamic>? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceId = await DeviceAuthService.getDeviceId();
      final deviceInfo = await DeviceAuthService.getDeviceInfo();
      
      setState(() {
        _deviceId = deviceId;
        _deviceInfo = deviceInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentMobileUserProvider);
    
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading device information...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  user?.isDeviceBound == true 
                      ? Icons.security 
                      : Icons.security_outlined,
                  color: user?.isDeviceBound == true 
                      ? Colors.green 
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Security Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Device binding status
            _buildStatusRow(
              'Device Binding',
              user?.isDeviceBound == true ? 'Enabled' : 'Not Configured',
              user?.isDeviceBound == true ? Colors.green : Colors.orange,
            ),
            
            // Device ID (masked for security)
            if (_deviceId != null)
              _buildStatusRow(
                'Device ID',
                _maskDeviceId(_deviceId!),
                Colors.blue,
              ),
            
            // Device registration date
            if (user?.deviceRegisteredAt != null)
              _buildStatusRow(
                'Registered',
                _formatDate(user!.deviceRegisteredAt!),
                Colors.blue,
              ),
            
            // Device platform
            if (_deviceInfo != null)
              _buildStatusRow(
                'Platform',
                _deviceInfo!['platform']?.toString().toUpperCase() ?? 'Unknown',
                Colors.blue,
              ),
            
            const SizedBox(height: 12),
            
            // Security message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: user?.isDeviceBound == true 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: user?.isDeviceBound == true 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user?.isDeviceBound == true 
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 20,
                    color: user?.isDeviceBound == true 
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user?.isDeviceBound == true
                          ? 'Your account is securely bound to this device. You can only access your account from this device.'
                          : 'Device binding will be configured on your first login for enhanced security.',
                      style: TextStyle(
                        fontSize: 12,
                        color: user?.isDeviceBound == true 
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _maskDeviceId(String deviceId) {
    if (deviceId.length <= 8) return deviceId;
    return '${deviceId.substring(0, 4)}...${deviceId.substring(deviceId.length - 4)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Dialog to show when device validation fails
class DeviceValidationErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onSignOut;

  const DeviceValidationErrorDialog({
    Key? key,
    required this.message,
    this.onRetry,
    this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.red),
          SizedBox(width: 8),
          Text('Device Security Alert'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For security reasons, each account can only be accessed from one registered device.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: onSignOut ?? () => Navigator.of(context).pop(),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onSignOut,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceValidationErrorDialog(
        message: message,
        onRetry: onRetry,
        onSignOut: onSignOut,
      ),
    );
  }
}

/// Widget to show device binding success
class DeviceBindingSuccessWidget extends StatelessWidget {
  final VoidCallback? onContinue;

  const DeviceBindingSuccessWidget({
    Key? key,
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.security,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Device Successfully Registered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account is now securely bound to this device. You can only access your account from this device for enhanced security.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (onContinue != null)
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }
}
