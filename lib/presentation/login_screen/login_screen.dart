import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhiking/api/api_service.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/login_bloc.dart';
import 'models/login_model.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final ApiService _apiService = ApiService();

  static Widget builder(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (context) => LoginBloc(LoginState(
        loginModelObj: const LoginModel(),
      ))
        ..add(LoginInitialEvent()),
      child: LoginScreen(),
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
                  SizedBox(height: 10.h),
                  _buildGoogleButton(context),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.h),
                        child: Text("OR"),
                      ),
                      Expanded(child: Divider()),
                    ],
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
                  SizedBox(height: 20.h),
                  CustomElevatedButton(
                    text: "lbl_masuk".tr,
                    margin: EdgeInsets.symmetric(horizontal: 66.h),
                    onPressed: () {
                      onTapMasuk(context);
                    },
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildRegistrationPrompt(context),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 66.h),
        child: OutlinedButton(
          onPressed: () => onTapGoogleSignIn(context),
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
                'Sign in with Google',
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

  /// Section Widget
  Widget _buildEmailInputSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5.h),
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

  /// Navigates to the homeScreen when the action is triggered.
  void onTapMasuk(BuildContext context) async {
    final emailController = context.read<LoginBloc>().state.lockoneController;
    final passwordController =
        context.read<LoginBloc>().state.locationoneController;

    if (emailController != null && passwordController != null) {
      final email = emailController.text;
      final password = passwordController.text;

      // Endpoint URL
      final url = Uri.parse('$baseUrl/login');

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

          await _navigateToHomeWithDssWarmup(context);
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
        _showErrorDialog(
          context,
          "Tidak bisa terhubung ke server. Pastikan backend aktif dan URL API benar.",
        );
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

  Future<void> onTapGoogleSignIn(BuildContext context) async {
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

      await _navigateToHomeWithDssWarmup(context);
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

  Future<void> _navigateToHomeWithDssWarmup(BuildContext context) async {
    bool dialogShown = false;

    try {
      final hasCache = await _apiService.hasHomeFeedCache();
      if (!hasCache && context.mounted) {
        dialogShown = true;
        _showDssWarmupDialog(context);
      }

      await _apiService.warmHomeFeedCache();
    } catch (e) {
      debugPrint('DSS warmup error: $e');
    } finally {
      if (dialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (context.mounted) {
      NavigatorService.pushNamed(AppRoutes.homeScreen);
    }
  }

  void _showDssWarmupDialog(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'DSS Warmup',
      barrierColor: Colors.white,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return PopScope(
          canPop: false,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgNn,
                      height: 56.h,
                      width: 70.h,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'MyHiking',
                      style: theme.textTheme.headlineLarge,
                    ),
                    SizedBox(height: 26.h),
                    SizedBox(
                      height: 180.h,
                      width: 180.h,
                      child: Lottie.asset(
                        'assets/lottie/sandy_loading.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 34.h),
                      child: Text(
                        'Menyiapkan rekomendasi jalur DSS, mohon tunggu...',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
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
