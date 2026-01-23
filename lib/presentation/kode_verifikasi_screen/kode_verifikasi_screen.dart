import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/kode_verifikasi_bloc.dart';
import 'models/kode_verifikasi_model.dart';

class KodeVerifikasiScreen extends StatelessWidget {
  const KodeVerifikasiScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<KodeVerifikasiBloc>(
      create: (context) => KodeVerifikasiBloc(KodeVerifikasiState(
        TextEditingController(), // Inisialisasi passwordController
        const KodeVerifikasiModel(), // Inisialisasi kodeVerifikasiModelobj
      ))
        ..add(KodeVerifikasiInitialEvent()),
      child: const KodeVerifikasiScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          // Ditambahkan SingleChildScrollView di sini
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.only(
              left: 24.h,
              top: 12.h,
              right: 24.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
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
                  imagePath: ImageConstant.imgGroup297,
                  height: 192.h,
                  width: double.maxFinite,
                  margin: EdgeInsets.only(
                    left: 4.h,
                    right: 18.h,
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 10.h),
                    child: Text(
                      "lbl_reset_password".tr,
                      style: CustomTextStyles.titleMediumSemiBold,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                _buildOtpInputSection(context),
                SizedBox(height: 24.h),
                CustomElevatedButton(
                  text: "lbl_kirim".tr,
                  margin: EdgeInsets.only(
                    left: 62.h,
                    right: 68.h,
                  ),
                  onPressed: () {
                    onTapKirim(context);
                  },
                ),
                SizedBox(
                    height: 102
                        .h), // Menambahkan jarak 24.h antara tombol "Kirim" dan teks
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildRegistrationPrompt(context),
      ),
    );
  }

  /// Section Widget
  Widget _buildOtpInputSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        children: [
          SizedBox(
            height: 18.h,
            width: double.maxFinite,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Text(
                  "msg_masukkan_kode_otp".tr,
                  style: theme.textTheme.labelMedium,
                ),
                Text(
                  "msg_masukkan_kode_otp".tr,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          BlocSelector<KodeVerifikasiBloc, KodeVerifikasiState,
              TextEditingController?>(
            selector: (state) => state.passwordController,
            builder: (context, passwordController) {
              return CustomTextFormField(
                controller: passwordController,
                textInputAction: TextInputAction.done,
                contentPadding: EdgeInsets.all(12.h),
              );
            },
          ),
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
          ),
        ],
      ),
    );
  }

  /// Navigates to the resetPageTwoScreen when the action is triggered.
  void onTapKirim(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.resetPageTwoScreen,
    );
  }

  /// Navigates to the registScreen when the action is triggered.
  void onTapTxtBelumpunyaakun2(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.registScreen,
    );
  }
}
