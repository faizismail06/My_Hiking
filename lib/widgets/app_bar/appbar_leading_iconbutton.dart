import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../custom_icon_button.dart';

class AppbarLeadingIconbutton extends StatelessWidget {
  final String? imagePath;
  final Function? onTap;
  final EdgeInsetsGeometry? margin;

  const AppbarLeadingIconbutton(
      {super.key, this.imagePath, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: () {
          onTap?.call();
        },
        child: CustomIconButton(
          height: 48.h,
          width: 48.h,
          padding: EdgeInsets.all(8.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14.h),
            boxShadow: [
              BoxShadow(
                color: appTheme.black900.withOpacity(0.12),
                spreadRadius: 0,
                blurRadius: 8.h,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CustomImageView(
            imagePath: imagePath ?? ImageConstant.imgIconArrow,
          ),
        ),
      ),
    );
  }
}
