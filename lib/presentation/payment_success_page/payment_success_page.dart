import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import '../../core/app_export.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String orderId;
  final int? totalPayment;
  final String? paymentMethod;

  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.totalPayment,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray5001,
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 20.h),
          child: Column(
            children: [
              _buildHeader(context),
              SizedBox(height: 18.h),
              _buildProgressSection(context),
              SizedBox(height: 14.h),
              Expanded(
                child: Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 24.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    borderRadius: BorderRadiusStyle.roundedBorder14,
                    boxShadow: [
                      BoxShadow(
                        color: appTheme.black900.withOpacity(0.04),
                        spreadRadius: 2.h,
                        blurRadius: 2.h,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        "Pembayaran Telah\nBerhasil",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: CustomTextStyles.titleLargeBlack900,
                      ),
                      SizedBox(height: 36.h),
                      CustomImageView(
                        imagePath: ImageConstant.imgSuccess1,
                        height: 150.h,
                        width: 150.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 38.h),
                      SizedBox(
                        width: double.maxFinite,
                        child: Text(
                          "Terimakasih, Pembayaran pesanan anda telah kami terima. Silakan cek tiket untuk melihat detail pesanan.",
                          style: CustomTextStyles.titleSmallGray50003,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.maxFinite,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () {
                            final parsedOrderId = int.tryParse(orderId);
                            if (parsedOrderId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order ID tidak valid.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.ticketScreen,
                              (route) => false,
                              arguments: parsedOrderId,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.teal900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.h),
                            ),
                          ),
                          child: Text(
                            'LIHAT TIKET',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.h,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.maxFinite,
                        height: 50.h,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.homeScreen,
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: appTheme.teal900, width: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.h),
                            ),
                          ),
                          child: Text(
                            'KEMBALI KE HOME',
                            style: TextStyle(
                              color: appTheme.teal900,
                              fontSize: 14.h,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: double.maxFinite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.homeScreen,
                  (route) => false,
                );
              },
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Text(
                  'SUKSES',
                  style: CustomTextStyles.titleMediumGray900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 10.h),
      child: AnotherStepper(
        iconHeight: 24,
        iconWidth: 26,
        stepperDirection: Axis.horizontal,
        activeIndex: 2,
        barThickness: 4,
        inverted: true,
        stepperList: [
          StepperData(
            iconWidget: _buildStepperIcon('1', true),
          ),
          StepperData(
            iconWidget: _buildStepperIcon('2', true),
          ),
          StepperData(
            iconWidget: _buildStepperIcon('3', true),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIcon(String label, bool active) {
    return Container(
      height: 24.h,
      width: 26.h,
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primary : appTheme.gray5001,
        borderRadius: BorderRadius.circular(12.h),
        border: active
            ? null
            : Border.all(
                color: appTheme.blueGray100,
                width: 2.h,
              ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : appTheme.blueGray100,
            fontWeight: FontWeight.bold,
            fontSize: 12.h,
          ),
        ),
      ),
    );
  }
}
