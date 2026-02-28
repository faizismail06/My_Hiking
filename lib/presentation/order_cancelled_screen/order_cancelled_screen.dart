import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:myhiking/widgets/app_bar/appbar_subtitle_one.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_outlined_button.dart';
import 'bloc/order_cancelled_bloc.dart';
import 'models/order_cancelled_model.dart';

class OrderCancelledScreen extends StatelessWidget {
  const OrderCancelledScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<OrderCancelledBloc>(
      create: (context) => OrderCancelledBloc(OrderCancelledState(
        orderCancelledModelObj: const OrderCancelledModel(),
      ))
        ..add(OrderCancelledInitialEvent()),
      child: const OrderCancelledScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCancelledBloc, OrderCancelledState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: appTheme.gray5001,
            appBar: _buildAppBar(context),
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 12.h,
                top: 4.h,
                right: 12.h,
              ),
              child: Column(
                children: [
                  _buildProgressSection(context),
                  SizedBox(height: 14.h),
                  Expanded(
                    child: Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.h,
                        vertical: 18.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        borderRadius: BorderRadiusStyle.roundedBorder14,
                        boxShadow: [
                          BoxShadow(
                            color: appTheme.black900.withOpacity(0.04),
                            spreadRadius: 2.h,
                            blurRadius: 2.h,
                            offset: const Offset(
                              0,
                              2,
                            ),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 10.h),
                          SizedBox(
                            width: 160.h,
                            child: Text(
                              "msg_pesanan_telah_dibatalkan".tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: CustomTextStyles.titleLargeBlack900,
                            ),
                          ),
                          SizedBox(height: 36.h),
                          CustomImageView(
                            imagePath: ImageConstant.imgVectorPrimary150x150,
                            height: 150.h,
                            width: 150.h,
                          ),
                          SizedBox(height: 38.h),
                          SizedBox(
                            width: double.maxFinite,
                            child: Text(
                              "msg_pesanan_ini_telah".tr,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: CustomTextStyles.titleSmallGray50003,
                            ),
                          ),
                          const Spacer(),
                          CustomOutlinedButton(
                            text: "lbl_kembali_ke_home".tr.toUpperCase(),
                            onPressed: () {
                              onTapKembalikehome(context);
                            },
                          )
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
      },
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Center(
        child: AppbarSubtitle(
          text: "lbl_dibatalkan".tr, // Tambahkan textAlign sebagai parameter
        ),
      ),
    );
  }


  /// Section Widget
  Widget _buildProgressSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(
        left: 10.h,
        right: 2.h,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.maxFinite,
            child: AnotherStepper(
              iconHeight: 26,
              iconWidth: 26,
              stepperDirection: Axis.horizontal,
              activeIndex: 0,
              inverted: true,
              stepperList: [
                StepperData(
                  iconWidget: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "lbl_1".tr,
                          style: CustomTextStyles.titleSmallInterOnPrimary,
                        )
                      ],
                    ),
                  ),
                ),
                StepperData(
                  iconWidget: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "lbl_2".tr,
                          style: CustomTextStyles.titleSmallInterOnPrimary,
                        )
                      ],
                    ),
                  ),
                ),
                StepperData(
                  iconWidget: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "lbl_3".tr,
                          style: CustomTextStyles.titleSmallInterOnPrimary,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Navigates to the homeScreen when the action is triggered.
  onTapKembalikehome(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.homeScreen,
    );
  }
}
