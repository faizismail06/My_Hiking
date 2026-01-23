import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';

class PopUpPwDigantiDialog extends StatelessWidget {
  const PopUpPwDigantiDialog({super.key});

  static Widget builder(BuildContext context) {
    return const PopUpPwDigantiDialog();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          14, // Rounded corners
        ),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(20.0), // Internal padding
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green Check Icon
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 70.0,
            ),
            const SizedBox(height: 20.0),
            // Success Message
            Text(
              "Selamat Password Anda Berhasil Diganti",
              textAlign: TextAlign.center,
              style: CustomTextStyles.titleSmallBlack900.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 30.0),
            // "Lanjut" Button
            CustomElevatedButton(
              height: 40.0,
              width: 120.0,
              text: "Lanjut",
              buttonStyle: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  Colors.green, // Green background color
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Rounded button
                  ),
                ),
              ),
              buttonTextStyle: CustomTextStyles.labelMediumOnPrimarySemiBold,
              onPressed: () {
                Navigator.pushNamed(
                    context, AppRoutes.loginScreen); // Close the dialog
              },
            ),
          ],
        ),
      ),
    );
  }
}
