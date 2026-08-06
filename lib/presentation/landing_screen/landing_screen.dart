import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/landing_bloc.dart';
import 'models/landing_model.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<LandingBloc>(
      create: (context) => LandingBloc(const LandingState(
        landingModelObj: LandingModel(),
      ))
        ..add(LandingInitialEvent()),
      child: const LandingScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandingBloc, LandingState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.only(top: 24.h),
                  child: Column(
                    children: [
                      _buildWelcomeTextSection(context),
                      SizedBox(height: 60.h),
                      CustomImageView(
                        imagePath: ImageConstant.img37082,
                        height: 400.h,
                        width: double.maxFinite,
                      ),
                      SizedBox(height: 60.h),
                      _buildStartButtonSection(context),
                      SizedBox(height: 30.h),
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

  Widget _buildWelcomeTextSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      padding: EdgeInsets.only(left: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "lbl_halo".tr,
            style: theme.textTheme.displayMedium,
          ),
          Padding(
            padding: EdgeInsets.only(left: 2.h),
            child: Text(
              "msg_selamat_datang_di".tr,
              style: CustomTextStyles.bodyMediumBluegray900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButtonSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          CustomElevatedButton(
            height: 52.h,
            text: "lbl_mulai".tr,
            buttonStyle: CustomButtonStyles.fillPrimary,
            buttonTextStyle: CustomTextStyles.titleLargeInter,
            onPressed: () {
              onTapMulai(context);
            },
          ),
        ],
      ),
    );
  }

  onTapMulai(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.loginScreen,
    );
  }
}
