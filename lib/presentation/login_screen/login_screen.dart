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
                top: 6.h,
                right: 24.h,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 176.h,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48.h,
                          width: 62.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomImageView(
                                imagePath: ImageConstant.imgNn,
                                height: 46.h,
                                width: double.maxFinite,
                              ),
                              CustomImageView(
                                imagePath: ImageConstant.imgNn,
                                height: 48.h,
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
                  SizedBox(height: 34.h),
                  CustomImageView(
                    imagePath: ImageConstant.img37081,
                    height: 172.h,
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 4.h,
                      right: 18.h,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(height: 7.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "LOGIN".tr,
                      style: CustomTextStyles.titleMediumSemiBold,
                      textAlign: TextAlign.center,
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
                    child: Padding(
                      padding: EdgeInsets.only(right: 6.h),
                      child: _buildInlineActionButton(
                        context,
                        label: "lbl_lupa_password".tr,
                        onPressed: () => onTapTxtLupapassword(context),
                        compact: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  CustomElevatedButton(
                    text: "lbl_masuk".tr,
                    margin: EdgeInsets.symmetric(horizontal: 66.h),
                    onPressed: () {
                      onTapMasuk(context);
                    },
                  ),
                  SizedBox(height: 8.h),
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
      height: 44.h,
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "msg_belum_punya_akun".tr,
            style: CustomTextStyles.labelMediumGray60001,
          ),
          SizedBox(width: 2.h),
          _buildInlineActionButton(
            context,
            label: "msg_registrasi_di_sini".tr,
            onPressed: () => onTapTxtRegistrasidi(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    bool compact = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: compact ? 10.h : 12.h,
            vertical: compact ? 4.h : 6.h,
          ),
        ),
        minimumSize: WidgetStateProperty.all(Size.zero),
        visualDensity: VisualDensity.compact,
        animationDuration: const Duration(milliseconds: 180),
        splashFactory: InkRipple.splashFactory,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return appTheme.teal900;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return theme.colorScheme.primary;
          }
          return compact ? appTheme.gray60001 : theme.colorScheme.primary;
        }),
        textStyle: WidgetStateProperty.resolveWith((states) {
          final isActive = states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed);
          final baseStyle = compact
              ? CustomTextStyles.labelMediumGray60001
              : CustomTextStyles.labelMedium10;
          return baseStyle.copyWith(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            decoration:
                isActive ? TextDecoration.underline : TextDecoration.none,
            decorationColor: theme.colorScheme.primary,
          );
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return appTheme.blueGray50;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return appTheme.blueGray50.withValues(alpha: 0.9);
          }
          return compact
              ? Colors.transparent
              : theme.colorScheme.primary.withValues(alpha: 0.08);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return theme.colorScheme.primary.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return theme.colorScheme.primary.withValues(alpha: 0.06);
          }
          return null;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final isActive = states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed);
          return BorderSide(
            color: compact
                ? (isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.22)
                    : Colors.transparent)
                : theme.colorScheme.primary.withValues(
                    alpha: isActive ? 0.38 : 0.2,
                  ),
          );
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999.h),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (!compact) ...[
            SizedBox(width: 4.h),
            Icon(
              Icons.arrow_outward_rounded,
              size: 12.h,
            ),
          ],
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
                        'Mohon tunggu...',
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
