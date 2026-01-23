import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class AppbarSubtitle extends StatelessWidget {
  final String text;
  final Function? onTap;
  final EdgeInsetsGeometry? margin;

  const AppbarSubtitle({super.key, required this.text, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => onTap?.call(),
        child: Text(
          text,
          style: CustomTextStyles.titleMediumGray900.copyWith(
            color: appTheme.gray900,
          ),
        ),
      ),
    );
  }
}
