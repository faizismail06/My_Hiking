import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../custom_icon_button.dart';

class AppbarLeadingIconbutton extends StatelessWidget {
  final String? imagePath;
  final Function? onTap;
  final EdgeInsetsGeometry? margin;

  const AppbarLeadingIconbutton({super.key, this.imagePath, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: () {
          onTap?.call();
        },
        child: CustomIconButton(
          height: 40.h,
          width: 40.h,
          padding: EdgeInsets.all(8.h),
          child: CustomImageView(
            imagePath: imagePath ?? ImageConstant.imgIconArrow,
          ),
        ),
      ),
    );
  }
}
