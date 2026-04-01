import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'dart:io';
import 'dart:convert'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/regist_bloc.dart';
import 'models/regist_model.dart';
import 'package:http/http.dart' as http;


class RegistScreen extends StatelessWidget {
  RegistScreen({super.key});

  final ApiService _apiService = ApiService();

  static Widget builder(BuildContext context) {
    return BlocProvider<RegistBloc>(
      create: (context) => RegistBloc(
        RegistState(
          registModelObj: const RegistModel(),
        ),
      )..add(RegistInitialEvent()),
      child: RegistScreen(),
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
                        SizedBox(height: 12.h),
                        _buildGoogleRegisterButton(context),
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

  Widget _buildGoogleRegisterButton(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 66.h),
        child: OutlinedButton(
          onPressed: () => onTapGoogleRegister(context),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            minimumSize: Size(double.maxFinite, 44.h),
            side: const BorderSide(color: Color(0xFF747775), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999.h),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'G',
                style: TextStyle(
                  color: const Color(0xFF4285F4),
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                'Sign up with Google',
                style: TextStyle(
                  color: const Color(0xFF1F1F1F),
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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

  Future<void> onTapGoogleRegister(BuildContext context) async {
    if (!_isGoogleSignInSupportedPlatform()) {
      _showErrorDialog(
        context,
        'Google Sign-In belum didukung di platform ini. Jalankan di Android, iOS, macOS, atau Web.',
      );
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        _showErrorDialog(context, 'Gagal mendapatkan token Google.');
        return;
      }

      final responseData = await _apiService.loginWithGoogle(idToken);
      final token = responseData['token']?.toString();

      if (token == null || token.isEmpty) {
        _showErrorDialog(context, 'Token login tidak ditemukan.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      NavigatorService.pushNamed(AppRoutes.homeScreen);
    } on SocketException {
      _showErrorDialog(context, 'Tidak ada koneksi internet.');
    } on MissingPluginException {
      _showErrorDialog(
        context,
        'Plugin Google Sign-In belum aktif. Lakukan full restart aplikasi dan jalankan di platform yang didukung.',
      );
    } catch (e) {
      _showErrorDialog(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  bool _isGoogleSignInSupportedPlatform() {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Google Register Gagal'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
