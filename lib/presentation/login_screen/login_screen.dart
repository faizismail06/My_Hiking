import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/login_bloc.dart';
import 'models/login_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (context) => LoginBloc(LoginState(
        loginModelObj: const LoginModel(),
      ))
        ..add(LoginInitialEvent()),
      child: const LoginScreen(),
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
                  SizedBox(
                    width: 184.h,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 54.h,
                          width: 68.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomImageView(
                                imagePath: ImageConstant.imgNn,
                                height: 52.h,
                                width: double.maxFinite,
                              ),
                              CustomImageView(
                                imagePath: ImageConstant.imgNn,
                                height: 54.h,
                                width: double.maxFinite,
                              )
                            ],
                          ),
                        ),
                        Text(
                          "lbl_myhiking".tr,
                          style: theme.textTheme.headlineLarge,
                        ),
                        Text(
                          "msg_your_hiking_assistance".tr,
                          style: CustomTextStyles.bodySmallBluegray900,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 74.h),
                  CustomImageView(
                    imagePath: ImageConstant.img37081,
                    height: 192.h,
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 4.h,
                      right: 18.h,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.h),
                      child: Text(
                        "LOGIN".tr,
                        style: CustomTextStyles.titleMediumSemiBold,
                      ),
                    ),
                  ),
                  _buildEmailInputSection(context),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        onTapTxtLupapassword(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: 6.h),
                        child: Text(
                          "lbl_lupa_password".tr,
                          style: CustomTextStyles.labelMediumGray60001,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  CustomElevatedButton(
                    text: "lbl_masuk".tr,
                    margin: EdgeInsets.symmetric(horizontal: 66.h),
                    onPressed: () {
                      onTapMasuk(context);
                    },
                  ),
                  SizedBox(height: 102.h),
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
  Widget _buildEmailInputSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            "Email".tr,
            style: theme.textTheme.labelMedium,
          ),
          BlocSelector<LoginBloc, LoginState, TextEditingController?>(
            selector: (state) => state.lockoneController,
            builder: (context, lockoneController) {
              return CustomTextFormField(
                controller: lockoneController,
                prefix: Container(
                  margin: EdgeInsets.fromLTRB(14.h, 8.h, 16.h, 8.h),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgLock,
                    height: 16.h,
                    width: 12.h,
                    fit: BoxFit.contain,
                  ),
                ),
                prefixConstraints: BoxConstraints(
                  maxHeight: 34.h,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.h,
                  vertical: 8.h,
                ),
              );
            },
          ),
          SizedBox(height: 10.h),
          Text(
            "Password".tr,
            style: theme.textTheme.labelMedium,
          ),
          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              return CustomTextFormField(
                controller: state.locationoneController,
                textInputAction: TextInputAction.done,
                prefix: Container(
                  margin: EdgeInsets.fromLTRB(14.h, 8.h, 16.h, 8.h),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgLocation,
                    height: 16.h,
                    width: 12.h,
                    fit: BoxFit.contain,
                  ),
                ),
                prefixConstraints: BoxConstraints(
                  maxHeight: 34.h,
                ),
                suffix: InkWell(
                  onTap: () {
                    context.read<LoginBloc>().add(ChangePasswordVisibilityEvent(
                          value: !state.isShowPassword,
                        ));
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16.h, 8.h, 14.h, 8.h),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgMdieye,
                      height: 16.h,
                      width: 24.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                suffixConstraints: BoxConstraints(
                  maxHeight: 34.h,
                ),
                obscureText: state.isShowPassword,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.h,
                  vertical: 8.h,
                ),
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
      height: 28.h,
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              "msg_belum_punya_akun".tr,
              style: CustomTextStyles.labelMediumGray60001,
            ),
          ),
          SizedBox(width: 2.h),
          GestureDetector(
            onTap: () {
              onTapTxtRegistrasidi(context);
            },
            child: Text(
              "msg_registrasi_di_sini".tr,
              style: CustomTextStyles.labelMedium10,
            ),
          )
        ],
      ),
    );
  }

  /// Navigates to the resetKirimEmailScreen when the action is triggered.
  void onTapTxtLupapassword(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.resetKirimEmailScreen,
    );
  }

  /// Navigates to the berandaScreen when the action is triggered.
  void onTapMasuk(BuildContext context) async {
    final emailController = context.read<LoginBloc>().state.lockoneController;
    final passwordController =
        context.read<LoginBloc>().state.locationoneController;

    if (emailController != null && passwordController != null) {
      final email = emailController.text;
      final password = passwordController.text;

      // Endpoint URL
      final url = Uri.parse("http://myhiking.my.id/api/login");

      try {
        // Mengirim request ke server
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "email": email,
            "password": password,
          }),
        );

        // Mengecek response dari server
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);

          // Navigate to berandaScreen after successful login
          NavigatorService.pushNamed(AppRoutes.berandaScreen);
        } else {
          // Jika login gagal, tampilkan pop-up error
          final errorData = jsonDecode(response.body);
          _showErrorDialog(
            context,
            errorData['data'] ??
                "Login gagal. Silakan cek kembali email dan password Anda.",
          );
        }
      } on SocketException {
        _showErrorDialog(context, "Tidak ada koneksi internet.");
      } on FormatException catch (e) {
        debugPrint('FORMAT ERROR: $e');
        _showErrorDialog(context, "Response server tidak valid.");
      } catch (e, s) {
        debugPrint('UNKNOWN ERROR: $e');
        debugPrintStack(stackTrace: s);
        _showErrorDialog(context, "Terjadi kesalahan tidak terduga.");
      }
    } else {
      // Jika input kosong
      _showErrorDialog(context, "Email dan password tidak boleh kosong.");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login Gagal"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Navigates to the registScreen when the action is triggered.
  void onTapTxtRegistrasidi(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.registScreen,
    );
  }
}
