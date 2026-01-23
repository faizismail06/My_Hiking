import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/pop_up_data_diri_lengkap_bloc.dart';
import 'models/pop_up_data_diri_lengkap_model.dart';

class PopUpDataDiriLengkapDialog extends StatelessWidget {
  const PopUpDataDiriLengkapDialog({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<PopUpDataDiriLengkapBloc>(
      create: (context) => PopUpDataDiriLengkapBloc(
        PopUpDataDiriLengkapState(
          const PopUpDataDiriLengkapModel(),
        ),
      )..add(PopUpDataDiriLengkapInitialEvent()),
      child: const PopUpDataDiriLengkapDialog(),
    );
  }
  @override
Widget build(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children:[
      Container(
        width: double.maxFinite,
        padding:EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadiusStyle.roundedBorder14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgCheckmark,
              height: 88.h,
              width: 88.h,
            ),
            SizedBox(height: 12.h),
            Text(
                  "msg_data_berhasil_disimpan".tr,
                style: CustomTextStyles.titleSmallBlack900,
            ),
            SizedBox(height: 12.h),
            CustomElevatedButton(
              height: 24.h,
              width: 72.h,
              text: "lbl_lanjut".tr,
              buttonStyle: CustomButtonStyles.fillPrimaryTL12,
              buttonTextStyle: CustomTextStyles.labelMediumOnPrimarySemiBold,
              onPressed: () {
                onTapContinueButton(context);
              },
            ),
            SizedBox(height: 8.h)
          ],
        ),
      )
    ],
  );
}

onTapContinueButton(BuildContext context) {
  NavigatorService.pushNamed(
    AppRoutes.berandaScreen,
  );
}
}