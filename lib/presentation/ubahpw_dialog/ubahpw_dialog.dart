import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/ubahpw_bloc.dart';
import 'models/ubahpw_model.dart'; // ignore_for_file: must_be_immutable

class UbahpwDialog extends StatelessWidget {
  const UbahpwDialog({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<UbahpwBloc>(
      create: (context) => UbahpwBloc(UbahpwState(
        ubahpwModelObj: const UbahpwModel(),
      ))
        ..add(UbahpwInitialEvent()),
      child: const UbahpwDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              _buildColumnView(context),
              SizedBox(height: 6.h),
              Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(
                  horizontal: 22.h,
                  vertical: 26.h,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary,
                  borderRadius: BorderRadiusStyle.customBorderTL30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 2.h),
                    Text(
                      "lbl_ubah_password".tr,
                      style: CustomTextStyles.titleLargePrimary,
                    ),
                    SizedBox(height: 28.h),
                    _buildPasswordFields(context),
                    SizedBox(height: 28.h),
                    _buildSavePasswordButton(context),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  /// Section Widget
  Widget _buildColumnView(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      padding: EdgeInsets.only(left: 142.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4.h,
            width: 32.h,
            decoration: BoxDecoration(
              color: appTheme.gray30001,
              borderRadius: BorderRadius.circular(2.h),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildCurrentPasswordInput(BuildContext context) {
    return BlocSelector<UbahpwBloc, UbahpwState, TextEditingController?>(
      selector: (state) => state.currentPasswordInputController,
      builder: (context, currentPasswordInputController) {
        return CustomTextFormField(
          controller: currentPasswordInputController,
          obscureText: true,
          contentPadding: EdgeInsets.all(12.h),
          borderDecoration: TextFormFieldStyleHelper.outlineGrayTL5,
          filled: false,
        );
      },
    );
  }

  /// Section Widget
  Widget _buildNewPasswordInput(BuildContext context) {
    return BlocSelector<UbahpwBloc, UbahpwState, TextEditingController?>(
      selector: (state) => state.newPasswordInputController,
      builder: (context, newPasswordInputController) {
        return CustomTextFormField(
          controller: newPasswordInputController,
          obscureText: true,
          contentPadding: EdgeInsets.all(12.h),
          borderDecoration: TextFormFieldStyleHelper.outlineGrayTL5,
          filled: false,
        );
      },
    );
  }

  /// Section Widget
  Widget _buildConfirmPasswordInput(BuildContext context) {
    return BlocSelector<UbahpwBloc, UbahpwState, TextEditingController?>(
      selector: (state) => state.confirmPasswordInputController,
      builder: (context, confirmPasswordInputController) {
        return CustomTextFormField(
          controller: confirmPasswordInputController,
          textInputAction: TextInputAction.done,
          obscureText: true,
          contentPadding: EdgeInsets.all(12.h),
          borderDecoration: TextFormFieldStyleHelper.outlineGrayTL5,
          filled: false,
        );
      },
    );
  }

  /// Section Widget
  Widget _buildPasswordFields(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "lbl_password3".tr,
            style: CustomTextStyles.titleSmallGray50003,
          ),
          SizedBox(height: 6.h),
          _buildCurrentPasswordInput(context),
          SizedBox(height: 6.h),
          Text(
            "lbl_password_baru2".tr,
            style: CustomTextStyles.titleSmallGray50003,
          ),
          SizedBox(height: 6.h),
          _buildNewPasswordInput(context),
          SizedBox(height: 6.h),
          Text(
            "msg_konfirmasi_password".tr,
            style: CustomTextStyles.titleSmallGray50003,
          ),
          SizedBox(height: 6.h),
          _buildConfirmPasswordInput(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildSavePasswordButton(BuildContext context) {
    return CustomElevatedButton(
      height: 52.h,
      text: "msg_simpan_password".tr,
      buttonStyle: CustomButtonStyles.fillPrimary,
      buttonTextStyle: CustomTextStyles.titleMediumInterOnPrimary,
      onPressed: () {
        onTapSavePasswordButton(context);
      },
    );
  }

  /// Navigates to the dataProfileScreen when the action is triggered.
  void onTapSavePasswordButton(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.dataProfileScreen,
    );
  }
}
