import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'base_button.dart';

class CustomElevatedButton extends BaseButton {
  final BoxDecoration? decoration;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool useGradient;

  const CustomElevatedButton({
    super.key,
    this.decoration,
    this.leftIcon,
    this.rightIcon,
    this.useGradient = true,
    super.margin,
    super.onPressed,
    super.buttonStyle,
    super.alignment,
    super.buttonTextStyle,
    super.isDisabled,
    super.height,
    super.width,
    required super.text,
  });

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: buildElevatedButtonWidget,
          )
        : buildElevatedButtonWidget;
  }

  Widget get buildElevatedButtonWidget => Container(
        height: height ?? 48.h,
        width: width ?? double.maxFinite,
        margin: margin,
        decoration: decoration ?? (useGradient ? _gradientDecoration : null),
        child: ElevatedButton(
          style: buttonStyle ?? _defaultButtonStyle,
          onPressed: isDisabled ?? false ? null : onPressed ?? () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leftIcon ?? const SizedBox.shrink(),
              Text(
                text,
                style: buttonTextStyle ??
                    CustomTextStyles.titleSmallInterOnPrimary,
              ),
              rightIcon ?? const SizedBox.shrink(),
            ],
          ),
        ),
      );

  BoxDecoration get _gradientDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, 0),
          end: const Alignment(1, 0),
          colors: [
            appTheme.green600,
            appTheme.emerald400,
          ],
        ),
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.green600.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12.h,
            offset: const Offset(0, 6),
          ),
        ],
      );

  ButtonStyle get _defaultButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
      );
}
