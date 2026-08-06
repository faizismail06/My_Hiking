import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
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
        TextEditingController(),
        const KodeVerifikasiModel(),
      ))
        ..add(KodeVerifikasiInitialEvent()),
      child: const KodeVerifikasiScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil argumen email dari navigasi registrasi
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String email = args?['email']?.toString() ?? '';

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
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
                SizedBox(height: 40.h),
                CustomImageView(
                  imagePath: ImageConstant.imgGroup297,
                  height: 160.h,
                  width: double.maxFinite,
                  margin: EdgeInsets.only(
                    left: 4.h,
                    right: 18.h,
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 10.h),
                    child: Text(
                      "Verifikasi Kode OTP Email",
                      style: CustomTextStyles.titleMediumSemiBold,
                    ),
                  ),
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: 10.h, top: 4.h, bottom: 8.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Kode OTP 6-Digit telah dikirimkan ke:\n$email",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12.fSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                _buildOtpInputSection(context),
                SizedBox(height: 24.h),
                CustomElevatedButton(
                  text: "Verifikasi OTP",
                  margin: EdgeInsets.only(
                    left: 32.h,
                    right: 32.h,
                  ),
                  onPressed: () {
                    onTapKirim(context, email);
                  },
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () => onTapResendOtp(context, email),
                  child: const Text(
                    "Belum menerima email? Kirim Ulang OTP",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildRegistrationPrompt(context),
      ),
    );
  }

  /// Section Widget OTP Input Field
  Widget _buildOtpInputSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Masukkan Kode OTP 6-Digit:",
            style: theme.textTheme.labelMedium,
          ),
          SizedBox(height: 6.h),
          BlocSelector<KodeVerifikasiBloc, KodeVerifikasiState, TextEditingController?>(
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

  /// Mengirimkan Kode OTP untuk Verifikasi Email
  void onTapKirim(BuildContext context, String email) async {
    final otpCode = context.read<KodeVerifikasiBloc>().state.passwordController?.text?.trim();

    if (otpCode == null || otpCode.length != 6) {
      _showDialog(context, 'Perhatian', 'Harap masukkan 6-digit kode OTP.');
      return;
    }

    try {
      final response = await ApiService().verifyOtp(email: email, otpCode: otpCode);

      if (context.mounted) {
        if (response['success'] == true) {
          final token = response['token']?.toString();
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi Email Berhasil! Selamat Datang di MyHiking.'),
              backgroundColor: Colors.green,
            ),
          );

          NavigatorService.pushNamedAndRemoveUntil(AppRoutes.homeScreen);
        } else {
          _showDialog(context, 'Verifikasi Gagal', response['message'] ?? 'Kode OTP tidak valid.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showDialog(context, 'Kesalahan Jaringan', 'Gagal memproses verifikasi: $e');
      }
    }
  }

  void onTapResendOtp(BuildContext context, String email) async {
    if (email.isEmpty) {
      _showDialog(context, 'Perhatian', 'Email tidak ditemukan.');
      return;
    }

    try {
      final response = await ApiService().resendOtp(email: email);
      if (context.mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Kode OTP baru telah dikirimkan ke email Anda.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showDialog(context, 'Gagal Kirim Ulang', response['message'] ?? 'Gagal mengirimkan ulang OTP.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showDialog(context, 'Kesalahan', 'Gagal terhubung ke server: $e');
      }
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void onTapTxtBelumpunyaakun2(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.registScreen);
  }
}
