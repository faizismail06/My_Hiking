import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/pop_up_checkout_bloc.dart';
import 'models/pop_up_checkout_model.dart'; // ignore_for_file: must_be_immutable

class PopUpCheckoutDialog extends StatelessWidget {
  final int pesananId;

  const PopUpCheckoutDialog({super.key, required this.pesananId});

  static Widget builder(BuildContext context, int pesananId) {
    return BlocProvider<PopUpCheckoutBloc>(
      create: (context) => PopUpCheckoutBloc(
        PopUpCheckoutState(
          popUpCheckoutModelobj: const PopUpCheckoutModel(),
        ),
      )..add(PopUpCheckoutInitialEvent()),
      child: PopUpCheckoutDialog(pesananId: pesananId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), // Rounded corners for dialog
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0, // Atur padding horizontal sesuai kebutuhan Anda
          vertical: 32.0, // Atur padding vertikal sesuai kebutuhan Anda
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(
                horizontal: 20.h,
                vertical: 30.h,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 72.h,
                    width: double.maxFinite,
                    margin: EdgeInsets.symmetric(horizontal: 16.h),
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Text(
                          "msg_konfirmasi_pendakian".tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: CustomTextStyles.titleSmallBlack900Medium
                              .copyWith(
                            fontSize: 15.0,
                            height: 1.40,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            "lbl_checkout".tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style:
                                CustomTextStyles.headlineLargeRed700.copyWith(
                              fontSize: 28.0,
                              height: 1.40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  buildBarcodeButtonsRow(context, pesananId),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBarcodeButtonsRow(BuildContext context, int pesananId) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 4.h),
      child: Row(
        children: [
          Expanded(
            child: CustomElevatedButton(
              height: 36.h,
              text: "lbl_barcode".tr,
              buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
              onPressed: () {
                onTapBarcode(context, pesananId);
              },
            ),
          ),
          SizedBox(width: 18.h),
          Expanded(
            child: CustomElevatedButton(
              height: 36.h,
              text: "lbl_gform".tr,
              buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
              onPressed: () {
                onTapGform(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  onTapBarcode(BuildContext context, int pesananId) {
    Navigator.pushNamed(
      context,
      AppRoutes.ticketScreen,
      arguments: pesananId,
    );
  }

  void onTapGform(BuildContext context) async {
    print('Attempting to launch URL:');
    const url = 'https://forms.gle/24H6HALhYRYEXVLS8';
    print('URL: $url');

    try {
      final Uri parsedUrl = Uri.parse(url);
      print('Parsed URL: $parsedUrl');

      if (!await launchUrl(
        parsedUrl,
        mode: LaunchMode.platformDefault,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat meluncurkan Google Form'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal meluncurkan Google Form: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
