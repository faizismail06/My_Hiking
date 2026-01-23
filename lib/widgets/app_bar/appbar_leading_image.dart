import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class AppbarLeadingImage extends StatelessWidget {
  final String? imagePath;
  final Function? onTap;
  final EdgeInsetsGeometry? margin;

  const AppbarLeadingImage({super.key, this.imagePath, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: () => onTap?.call(),
        child: CustomImageView(
          imagePath: imagePath!,
          height: 18.h,
          width: 18.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
