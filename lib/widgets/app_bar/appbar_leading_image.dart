import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class AppbarLeadingImage extends StatelessWidget {
  final String? imagePath;
  final Function? onTap;
  final EdgeInsetsGeometry? margin;

  const AppbarLeadingImage(
      {super.key, this.imagePath, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: () => onTap?.call(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8.h),
            boxShadow: [
              BoxShadow(
                color: appTheme.green600.withOpacity(0.15),
                spreadRadius: 0,
                blurRadius: 6.h,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(3.h),
          child: CustomImageView(
            imagePath: imagePath!,
            height: 20.h,
            width: 20.h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
