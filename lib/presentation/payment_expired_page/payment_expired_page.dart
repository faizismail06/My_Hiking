import 'package:flutter/material.dart';

import '../../core/app_export.dart';

class PaymentExpiredPage extends StatelessWidget {
  final String orderId;
  final String message;

  const PaymentExpiredPage({
    super.key,
    required this.orderId,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray5001,
        body: Center(
          child: Container(
            margin: EdgeInsets.all(20.h),
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 24.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              borderRadius: BorderRadiusStyle.roundedBorder14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_off,
                  color: Colors.red.shade600,
                  size: 72,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Payment Expired',
                  style: CustomTextStyles.titleLargeBlack900,
                ),
                SizedBox(height: 8.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.labelMediumGray50002,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Order ID: $orderId',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.homeScreen,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
