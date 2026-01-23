import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/data_profile_screen/bloc/data_profile_bloc.dart';
import 'package:myhiking/presentation/data_profile_screen/data_profile_screen.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';

// ignore_for_file: must_be

class PopUpLengkapiDataDiriDialog extends StatefulWidget {
  final int userId;

  const PopUpLengkapiDataDiriDialog({super.key, required this.userId});

  @override
  State<PopUpLengkapiDataDiriDialog> createState() =>
      _PopUpLengkapiDataDiriDialogState();
}

class _PopUpLengkapiDataDiriDialogState
    extends State<PopUpLengkapiDataDiriDialog> {
  bool isLoading = true;
  int userId = 0;
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    final token = await ApiService().getToken();

    // Cek apakah token null atau kosong
    if (token == null || token.isEmpty) {
      // Jika token tidak tersedia, tampilkan pesan atau ambil tindakan lain
      // print("Token is null or empty");
      if (mounted) {
        setState(() {
          isLoading =
              false; // Menyelesaikan status loading jika token tidak ada
        });
      }
      return; // Keluar dari fungsi jika token tidak ada
    }

    // print("Token: $token"); // Debugging, pastikan token ada

    try {
      final response = await ApiService().getUser(token);
      if (response['success']) {
        if (mounted) {
          setState(() {
            userId = response['data']['id'];
          });
        }
      } else {
        // Menangani error jika API gagal
        // print("Error: ${response['message']}");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      // Tangani error jaringan atau kesalahan lainnya
      // print("Error fetching user: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.h,
        vertical: 20.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 6.h),
          SizedBox(
            height: 30.h,
            child: VerticalDivider(
              width: 6.h,
              thickness: 6.h,
              color: appTheme.redA700,
            ),
          ),
          SizedBox(height: 8.h),
          CustomImageView(
            imagePath: ImageConstant.imgVector,
            height: 10.h,
            width: 10.h,
          ),
          SizedBox(height: 26.h),
          Text(
            "Harap lengkapi Data diri Profile\nterlebih dahulu",
            textAlign: TextAlign.center,
            style: CustomTextStyles.titleSmallBlack900.copyWith(
              height: 1.40,
            ),
          ),
          SizedBox(height: 32.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomElevatedButton(
                height: 35.h,
                width: 100.h,
                text: "Batal",
                buttonStyle: CustomButtonStyles.fillRed,
                buttonTextStyle: CustomTextStyles.labelMediumOnPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              CustomElevatedButton(
                height: 35.h,
                width: 100.h,
                text: "Lengkapi",
                buttonStyle: CustomButtonStyles.fillPrimaryTL12,
                buttonTextStyle: CustomTextStyles.labelMediumOnPrimary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) =>
                            DataProfileBloc(apiService: ApiService()),
                        child: DataProfileScreen(userId: widget.userId),
                      ),
                    ),
                  );
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
