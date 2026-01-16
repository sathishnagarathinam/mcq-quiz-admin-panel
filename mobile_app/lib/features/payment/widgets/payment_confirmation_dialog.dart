import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/models/exam_model.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/paid_quiz_access_service.dart';

/// Payment dialog state enum
enum PaymentDialogState {
  confirming,
  processing,
  verifying,
  success,
  failed,
}

class PaymentConfirmationDialog extends StatefulWidget {
  final ExamModel exam;
  final VoidCallback onCancel;
  final String userId;
  final String userEmail;
  final String userPhone;

  const PaymentConfirmationDialog({
    super.key,
    required this.exam,
    required this.onCancel,
    required this.userId,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog> {
  PaymentDialogState _state = PaymentDialogState.confirming;
  String? _error;
  String? _currentMerchantOrderId;

  // Razorpay instance
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    developer.log('✅ Razorpay initialized');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  /// Start the payment flow with Razorpay
  Future<void> _startPayment() async {
    setState(() {
      _state = PaymentDialogState.processing;
      _error = null;
    });

    try {
      developer.log('🚀 Starting Razorpay payment...');

      final paymentProvider = context.read<PaymentProvider>();

      // Create order with backend
      developer.log('⏳ Creating Razorpay order...');
      final orderResponse = await paymentProvider.createRazorpayOrder(
        exam: widget.exam,
        userEmail: widget.userEmail,
        userPhone: widget.userPhone,
        userId: widget.userId,
      );

      if (!mounted) return;

      if (!orderResponse.success || orderResponse.data == null) {
        developer.log('❌ Failed to create order: ${orderResponse.message}');
        setState(() {
          _state = PaymentDialogState.failed;
          _error = orderResponse.message ?? 'Failed to create payment order';
        });
        return;
      }

      final orderData = orderResponse.data!;
      _currentMerchantOrderId = orderData.merchantOrderId;

      developer.log('✅ Order created, opening Razorpay checkout...');
      developer.log('   Order ID: ${orderData.orderId}');
      developer.log('   Amount: ${orderData.amount}');

      // Open Razorpay checkout
      // Amount is already an int in paise from RazorpayOrderData
      final options = {
        'key': orderData.keyId,
        'amount': orderData.amount, // Amount in paise - MUST be int
        'currency': orderData.currency,
        'order_id': orderData.orderId,
        'name': 'MCQ Quiz App',
        'description': 'Payment for ${widget.exam.displayName}',
        'prefill': {
          'email': widget.userEmail,
          'contact': widget.userPhone,
        },
        'external': {
          'wallets': ['paytm'], // Enable external wallets
        },
        'theme': {
          'color': '#1976D2', // Primary blue color
        },
        'notes': {
          'merchantOrderId': orderData.merchantOrderId,
          'examId': widget.exam.id,
          'userId': widget.userId,
        },
      };

      developer.log('📱 Opening Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      developer.log('❌ Payment error: $e');
      if (mounted) {
        setState(() {
          _state = PaymentDialogState.failed;
          _error = 'Payment error: ${e.toString()}';
        });
      }
    }
  }

  /// Handle successful Razorpay payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    developer.log('✅ Razorpay payment success!');
    developer.log('   Payment ID: ${response.paymentId}');
    developer.log('   Order ID: ${response.orderId}');
    developer.log('   Signature: ${response.signature}');

    if (!mounted) return;

    setState(() {
      _state = PaymentDialogState.verifying;
    });

    // Verify payment with backend
    try {
      developer.log('🔐 Calling verifyRazorpayPayment...');
      developer.log('   paymentId: ${response.paymentId}');
      developer.log('   orderId: ${response.orderId}');
      developer.log('   signature: ${response.signature?.substring(0, 20)}...');
      developer.log('   merchantOrderId: $_currentMerchantOrderId');

      final paymentProvider = context.read<PaymentProvider>();
      final verified = await paymentProvider.verifyRazorpayPayment(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
        merchantOrderId: _currentMerchantOrderId ?? '',
      );

      developer.log('🔐 Verification result: $verified');

      if (!mounted) return;

      if (verified) {
        developer.log('✅ Payment verified successfully!');
        setState(() {
          _state = PaymentDialogState.success;
        });

        // Create access record on client side as fallback
        // This ensures access is available even if backend creation is delayed
        try {
          developer.log('📝 Creating access record on client side...');
          await PaidQuizAccessService.createAccessRecord(
            examId: widget.exam.id,
            examName: widget.exam.displayName,
            paymentId: response.paymentId ?? '',
          );
          developer.log('✅ Client-side access record created successfully');
        } catch (e) {
          developer.log('⚠️ Error creating client-side access record: $e');
          // Don't fail the payment if client-side creation fails
          // Backend should have already created it
        }

        // Wait for Firestore to sync (2 seconds), then close dialog
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            developer
                .log('🔄 Closing payment dialog and refreshing parent screen');
            Navigator.of(context).pop(true); // Return success
            widget.onCancel(); // Refresh parent screen
          }
        });
      } else {
        developer.log('❌ Payment verification returned false');
        setState(() {
          _state = PaymentDialogState.failed;
          _error = 'Payment verification failed. Please contact support.';
        });
      }
    } catch (e) {
      developer.log('❌ Verification error: $e');
      if (mounted) {
        setState(() {
          _state = PaymentDialogState.failed;
          _error = 'Payment verification error: ${e.toString()}';
        });
      }
    }
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    developer.log('❌ Razorpay payment failed');
    developer.log('   Code: ${response.code}');
    developer.log('   Message: ${response.message}');

    if (!mounted) return;

    String errorMessage = 'Payment failed';

    // Parse error message
    switch (response.code) {
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      case Razorpay.INVALID_OPTIONS:
        errorMessage = 'Invalid payment configuration.';
        break;
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled.';
        break;
      default:
        errorMessage = response.message ?? 'Payment failed. Please try again.';
    }

    setState(() {
      _state = PaymentDialogState.failed;
      _error = errorMessage;
    });
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log('📱 External wallet selected: ${response.walletName}');
    // External wallet flow will be handled by Razorpay
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case PaymentDialogState.confirming:
        return _buildConfirmationContent();
      case PaymentDialogState.processing:
        return _buildProcessingContent();
      case PaymentDialogState.verifying:
        return _buildVerifyingContent();
      case PaymentDialogState.success:
        return _buildSuccessContent();
      case PaymentDialogState.failed:
        return _buildFailedContent();
    }
  }

  Widget _buildConfirmationContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.payment,
          size: 64,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Confirm Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.exam.displayName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Show original price with strikethrough if discount exists
              if (widget.exam.hasDiscount) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹${widget.exam.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.exam.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Show discounted price or regular price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.currency_rupee, color: AppTheme.primaryColor),
                  Text(
                    widget.exam.hasDiscount
                        ? widget.exam.discountedPrice.toStringAsFixed(2)
                        : widget.exam.price.toStringAsFixed(2),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '30 days unlimited access',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Return false for cancelled
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          'Processing Payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Opening payment options...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // Return false for cancelled
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          'Verifying Payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we confirm your payment...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Successful!',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You now have access to this quiz for 30 days.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true); // Return true for success
            widget.onCancel(); // Refresh the parent screen
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Continue to Quiz',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Failed',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? 'An error occurred during payment.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Return false for failed
                },
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _state = PaymentDialogState.confirming;
                    _error = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
