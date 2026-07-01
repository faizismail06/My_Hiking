import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import '../pop_up_pw_diganti_dialog/pop_up_pw_diganti_dialog.dart';
import 'bloc/reset_page_two_bloc.dart';
import 'models/reset_page_two_model.dart';

class ResetPageTwoScreen extends StatelessWidget {
  const ResetPageTwoScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<ResetPageTwoBloc>(
      create: (context) => ResetPageTwoBloc(ResetPageTwoState(
        resetPageTwoModelObj: const ResetPageTwoModel(),
      ))
        ..add(ResetPageTwoInitialEvent()),
      child: const ResetPageTwoScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 24.h,
                top: 12.h,
                right: 24.h,
              ),
              child: Column(
                children: [
                  Column(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgNn,
                        height: 54.h,
                        width: 68.h,
                      ),
                      Text(
                        "lbl_myhiking".tr,
                        style: theme.textTheme.headlineLarge,
                      ),
                      Text(
                        "msg_your_hiking_assistance".tr,
                        style: CustomTextStyles.bodySmallBluegray900,
                      ),
                    ],
                  ),
                  SizedBox(height: 74.h),
                  CustomImageView(
                    imagePath: ImageConstant.img37081,
                    height: 200.h,
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 4.h,
                      right: 18.h,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _buildResetPasswordSection(context),
                  SizedBox(height: 118.h),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildRegistrationPrompt(context),
      ),
    );
  }

  /// Section Widget
  Widget _buildResetPasswordSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "lbl_reset_password".tr,
            style: CustomTextStyles.titleMediumSemiBold,
          ),
          SizedBox(height: 2.h),
          Text(
            "lbl_password_baru".tr,
            style: theme.textTheme.labelMedium,
          ),
          BlocSelector<ResetPageTwoBloc, ResetPageTwoState,
              TextEditingController?>(
            selector: (state) => state.passwordController,
            builder: (context, passwordController) {
              return CustomTextFormField(
                controller: passwordController,
                obscureText: true,
                contentPadding: EdgeInsets.all(12.h),
              );
            },
          ),
          SizedBox(height: 10.h),
          Text(
            "msg_konfirmasi_password2".tr,
            style: theme.textTheme.labelMedium,
          ),
          BlocSelector<ResetPageTwoBloc, ResetPageTwoState,
              TextEditingController?>(
            selector: (state) => state.passwordoneController,
            builder: (context, passwordoneController) {
              return CustomTextFormField(
                controller: passwordoneController,
                textInputAction: TextInputAction.done,
                obscureText: true,
                contentPadding: EdgeInsets.all(12.h),
              );
            },
          ),
          SizedBox(height: 24.h),
          CustomElevatedButton(
            text: "lbl_ganti".tr,
            margin: EdgeInsets.symmetric(horizontal: 56.h),
            onPressed: () {
              onTapGanti(context);
            },
          )
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildRegistrationPrompt(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              onTapTxtBelumpunyaakun2(context);
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "msg_belum_punya_akun".tr,
                      style: CustomTextStyles.labelMediumGray6000110,
                    ),
                    TextSpan(
                      text: "msg_registrasi_di_sini".tr,
                      style: CustomTextStyles.labelMedium10_1,
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Menampilkan dialog dengan konten [PopUpPwDigantiDialog].
  onTapGanti(BuildContext context) {
    final double dialogWidth =
        MediaQuery.of(context).size.width * 0.8; // 80% dari lebar layar
    final double dialogHeight =
        MediaQuery.of(context).size.height * 0.4; // 40% dari tinggi layar

    showDialog(
      context: NavigatorService.navigatorKey.currentContext!,
      builder: (_) => Dialog(
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: PopUpPwDigantiDialog.builder(
              NavigatorService.navigatorKey.currentContext!),
        ),
      ),
    );
  }

  /// Navigasi ke halaman registrasi.
  onTapTxtBelumpunyaakun2(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.registScreen,
    );
  }
}
