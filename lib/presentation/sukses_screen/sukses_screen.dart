import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_outlined_button.dart';
import 'bloc/sukses_bloc.dart';
import 'models/sukses_model.dart';

class SuksesScreen extends StatelessWidget {
  const SuksesScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<SuksesBloc>(
      create: (context) => SuksesBloc(SuksesState(
        suksesModelObj: const SuksesModel(),
      ))
        ..add(SuksesInitialEvent()),
      child: const SuksesScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuksesBloc, SuksesState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: appTheme.gray5001,
            appBar: _buildAppBar(context),
            body: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Container(
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
                      Container(
                        width: double.maxFinite,
                        padding: EdgeInsets.only(
                          left: 6.h,
                          top: 18.h,
                          right: 6.h,
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
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 10.h),
                            SizedBox(
                              width: 206.h,
                              child: Text(
                                "msg_pembayaran_telah".tr,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: CustomTextStyles.titleLargeBlack900,
                              ),
                            ),
                            SizedBox(height: 36.h),
                            CustomImageView(
                              imagePath: ImageConstant.imgSuccess1,
                              height: 150.h,
                              width: 150.h,
                            ),
                            SizedBox(height: 38.h),
                            SizedBox(
                              width: double.maxFinite,
                              child: Text(
                                "msg_terimakasih_pembayaran".tr,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style:
                                    CustomTextStyles.titleSmallGray50003Medium,
                              ),
                            ),
                            SizedBox(height: 128.h),
                            CustomElevatedButton(
                              height: 48.h,
                              text: "lbl_lihat_tiket".tr.toUpperCase(),
                              buttonStyle: CustomButtonStyles.fillPrimary,
                              buttonTextStyle: theme.textTheme.labelLarge!,
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.tiketScreen,
                                    arguments: 3, // Ganti 3 dengan ID pesanan yang benar
                                  );
                                },
                            ),
                            SizedBox(height: 16.h),
                            CustomOutlinedButton(
                              text: "lbl_kembali_ke_home".tr.toUpperCase(),
                              onPressed: () {
                                onTapKembalikehome(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Section Widget
PreferredSizeWidget _buildAppBar(BuildContext context) {
  return CustomAppBar(
    leadingWidth: 31.h,
    leading: AppbarLeadingImage(
      imagePath: ImageConstant.imgArrowDown,
      margin: EdgeInsets.only(left: 13.h),
      onTap: () {
        onTapArrowdownone(context);
      },
    ),
    title: Center(
      // Menggunakan Center widget untuk memusatkan judul
      child: AppbarSubtitleOne(
        text: "lbl_sukses".tr,
        margin: EdgeInsets.zero, // Mengatur margin menjadi nol untuk memusatkan
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
            iconHeight: 24,
            iconWidth: 26,
            stepperDirection: Axis.horizontal,
            activeIndex: 0,
            barThickness: 4,
            inverted: true,
            stepperList: [
              StepperData(
                iconWidget: Container(
                  height: 24.h,
                  width: 24.h,
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
                        style: CustomTextStyles.titleSmallOnPrimaryMedium,
                      ),
                    ],
                  ),
                ),
              ),
              StepperData(
                iconWidget: Container(
                  height: 24.h,
                  width: 24.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadiusStyle.roundedBorder14,
                    // border: Border.all(
                    //   color: theme.colorScheme.primary,
                    //   width: 2.h,
                    // ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "lbl_2".tr,
                        style: CustomTextStyles.titleSmallOnPrimaryMedium,
                      ),
                    ],
                  ),
                ),
              ),
              StepperData(
                iconWidget: Container(
                  height: 24.h,
                  width: 24.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadiusStyle.roundedBorder14,
                    // border: Border.all(
                    //   color: theme.colorScheme.primary,
                    //   width: 2.h,
                    // ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "lbl_3".tr,
                        style: CustomTextStyles.titleSmallOnPrimaryMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Navigates to the berandaScreen when the action is triggered.
void onTapArrowdownone(BuildContext context) {
  NavigatorService.pushNamed(
    AppRoutes.berandaScreen,
  );
}

/// Navigates to the tiketScreen when the action is triggered.
void onTapLihattiket(BuildContext context) {
    Navigator.pushNamed(
    context,
    AppRoutes.tiketScreen,
    arguments: 3, // Ganti 3 dengan nilai ID pesanan yang sesuai
  );
}

/// Navigatesa to the berandaScreen when the action is triggered.
void onTapKembalikehome(BuildContext context) {
  NavigatorService.pushNamed(
    AppRoutes.berandaScreen,
  );
}
