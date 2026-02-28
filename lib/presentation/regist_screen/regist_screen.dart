import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'dart:convert'; // Add this import
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/regist_bloc.dart';
import 'models/regist_model.dart';
import 'package:http/http.dart' as http;


class RegistScreen extends StatelessWidget {
  const RegistScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<RegistBloc>(
      create: (context) => RegistBloc(
        RegistState(
          registModelObj: const RegistModel(),
        ),
      )..add(RegistInitialEvent()),
      child: const RegistScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.only(left: 24.h, top: 56.h, right: 24.h),
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
                        SizedBox(height: 70.h),
                        Text(
                          "lbl_registrasi".tr,
                          style: CustomTextStyles.titleLargeBluegray800,
                        ),
                        SizedBox(height: 54.h),
                        _buildFullNameSection(context),
                        SizedBox(height: 14.h),
                        _buildEmailSection(context),
                        SizedBox(height: 16.h),
                        _buildPasswordSection(context),
                        SizedBox(height: 16.h),
                        _buildConfirmPasswordSection(context),
                        SizedBox(height: 44.h),
                        _buildRegisterButton(context),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ),
              // SizedBox(height: 34.h),
            ],
          ),
        ),
        bottomNavigationBar: _buildFooterSection(context),
      ),
    );
  }

  /// Full name input section
  Widget _buildFullNameSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "lbl_nama_lengkap".tr,
            style: theme.textTheme.labelMedium,
          ),
          _buildEdittextone(context),
        ],
      ),
    );
  }

  /// Email input section
  Widget _buildEmailSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "lbl_email2".tr,
            style: theme.textTheme.labelMedium,
          ),
          _buildEmailtwo(context),
        ],
      ),
    );
  }

  /// Password input section
  Widget _buildPasswordSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "lbl_password2".tr,
            style: theme.textTheme.labelMedium,
          ),
          _buildPasswordtwo(context),
        ],
      ),
    );
  }

  /// Confirm password input section
  Widget _buildConfirmPasswordSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "msg_konfirmasi_password".tr,
            style: theme.textTheme.labelMedium,
          ),
          _buildPasswordthree(context),
        ],
      ),
    );
  }

  /// Register button
  Widget _buildRegisterButton(BuildContext context) {
    return CustomElevatedButton(
      text: "lbl_daftar".tr,
      margin: EdgeInsets.symmetric(horizontal: 66.h),
      onPressed: () {
        onTapRegisterButton(context);
      },
    );
  }

  /// Footer section
  Widget _buildFooterSection(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              "lbl_daftar".tr,
              textAlign: TextAlign.center,
              style: CustomTextStyles.labelMediumInterOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle register button tap
  void onTapRegisterButton(BuildContext context) async {
  final name = context.read<RegistBloc>().state.edittextoneController?.text;
  final email = context.read<RegistBloc>().state.emailtwoController?.text;
  final password = context.read<RegistBloc>().state.passwordtwoController?.text;
  final confirmPassword = context.read<RegistBloc>().state.passwordthreeController?.text;

  if (password == confirmPassword) {
    // Kirim data ke server
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name ?? '',
        'email': email ?? '',
        'password': password ?? '',
        'password_confirmation': confirmPassword ?? '', 
      }),
    );

      if (response.statusCode == 201) {
        // Registrasi berhasil
        NavigatorService.pushNamed(AppRoutes.loginScreen);
      } else {
        // Tampilkan pesan error
        print('Failed to register: ${response.body}');
      }
    } else {
      // Tampilkan pesan password tidak sesuai
      print('Password tidak sesuai');
    }
  }
  


  /// Full name input field
  Widget _buildEdittextone(BuildContext context) {
    return BlocSelector<RegistBloc, RegistState, TextEditingController?>(
      selector: (state) => state.edittextoneController,
      builder: (context, edittextoneController) {
        return CustomTextFormField(
          controller: edittextoneController,
          contentPadding: EdgeInsets.all(12.h),
        );
      },
    );
  }

  /// Email input field
  Widget _buildEmailtwo(BuildContext context) {
    return BlocSelector<RegistBloc, RegistState, TextEditingController?>(
      selector: (state) => state.emailtwoController,
      builder: (context, emailtwoController) {
        return CustomTextFormField(
          controller: emailtwoController,
          contentPadding: EdgeInsets.all(12.h),
        );
      },
    );
  }

/// Password input field
Widget _buildPasswordtwo(BuildContext context) {
  return BlocSelector<RegistBloc, RegistState, bool>(
    selector: (state) => state.isPassword2Visible ?? false,
    builder: (context, isVisible) {
      return BlocSelector<RegistBloc, RegistState, TextEditingController?>(
        selector: (state) => state.passwordtwoController,
        builder: (context, passwordtwoController) {
          return CustomTextFormField(
            controller: passwordtwoController,
            obscureText: !isVisible,
            contentPadding: EdgeInsets.all(12.h),
            suffix: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                context.read<RegistBloc>().add(TogglePassword2Visibility());
              },
            ),
          );
        },
      );
    },
  );
}

/// Confirm password input field
Widget _buildPasswordthree(BuildContext context) {
  return BlocSelector<RegistBloc, RegistState, bool>(
    selector: (state) => state.isPassword3Visible ?? false,
    builder: (context, isVisible) {
      return BlocSelector<RegistBloc, RegistState, TextEditingController?>(
        selector: (state) => state.passwordthreeController,
        builder: (context, passwordthreeController) {
          return CustomTextFormField(
            controller: passwordthreeController,
            textInputAction: TextInputAction.done,
            obscureText: !isVisible,
            contentPadding: EdgeInsets.all(12.h),
            suffix: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                context.read<RegistBloc>().add(TogglePassword3Visibility());
              },
            ),
          );
        },
      );
    },
  );
}

}
