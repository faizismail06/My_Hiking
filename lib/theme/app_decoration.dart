import 'package:flutter/material.dart';
import '../core/app_export.dart';

class AppDecoration {
  // Fill decorations
  static BoxDecoration get fillBlueGray => BoxDecoration(
        color: appTheme.blueGray50,
      );

  static BoxDecoration get fillGray => BoxDecoration(
        color: appTheme.gray5001,
      );

  static BoxDecoration get fillGray300 => BoxDecoration(
        color: appTheme.gray300,
      );

  static BoxDecoration get fillGray30002 => BoxDecoration(
        color: appTheme.gray30002,
      );

  static BoxDecoration get fillGray50 => BoxDecoration(
        color: appTheme.gray50,
      );

  static BoxDecoration get fillOnPrimary => BoxDecoration(
        color: theme.colorScheme.onPrimary,
      );

  static BoxDecoration get fillPrimary => BoxDecoration(
        color: theme.colorScheme.primary,
      );

  static BoxDecoration get fillPrimary1 => BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.7),
      );

  // Gradient decorations
  static BoxDecoration get gradientPrimaryGreen => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, 0),
          end: const Alignment(1, 0),
          colors: [
            appTheme.green600,
            appTheme.emerald400,
          ],
        ),
      );

  static BoxDecoration get gradientGreenToEmerald => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0, -1),
          end: const Alignment(0, 1),
          colors: [
            const Color(0XFF1DB854),
            const Color(0XFF0D7E4A),
          ],
        ),
      );

  static BoxDecoration get gradientVibrantGreen => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1),
          end: const Alignment(1, 1),
          colors: [
            const Color(0XFF4ECB71),
            const Color(0XFF1DB854),
            const Color(0XFF0D7E4A),
          ],
        ),
      );

  static BoxDecoration get gradientGrayToGray => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.43, 0.79),
          end: const Alignment(0.43, 0.05),
          colors: [appTheme.gray50, appTheme.gray50.withOpacity(0)],
        ),
      );

  static BoxDecoration get modernShadowCard => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.green600.withOpacity(0.12),
            spreadRadius: 0,
            blurRadius: 8.h,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: appTheme.black900.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 2.h,
            offset: const Offset(0, 1),
          ),
        ],
      );

  // Modern Dark Theme Decorations
  static BoxDecoration get darkGradientGreen => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, 0),
          end: const Alignment(1, 0),
          colors: [
            const Color(0XFF4ECB71),
            const Color(0XFF2ECC71),
          ],
        ),
      );

  static BoxDecoration get darkModernCard => BoxDecoration(
        color: const Color(0XFF1A2D24),
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF4ECB71).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8.h,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Outline decorations
  static BoxDecoration get outlineBlack => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.04),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get outlineBlack900 => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.08),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get outlineBlueGray => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        boxShadow: [
          BoxShadow(
            color: appTheme.blueGray40019,
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 13),
          ),
        ],
      );

  static BoxDecoration get outlineGray => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        border: Border.all(
          color: appTheme.gray50004,
          width: 1.h,
        ),
      );

  static BoxDecoration get outlineGray400 => BoxDecoration(
        border: Border.all(
          color: appTheme.gray400,
          width: 1.h,
        ),
      );

  static BoxDecoration get outlineGray40019 => BoxDecoration(
        color: theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: appTheme.gray40019,
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get outlineGray4001 => BoxDecoration(
        color: appTheme.blueGray10001,
        border: Border.all(
          color: appTheme.gray400,
          width: 1.h,
        ),
      );

  static BoxDecoration get outlineOnPrimary => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        border: Border.all(
          color: theme.colorScheme.onPrimary,
          width: 1.h,
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.blueGray40019.withOpacity(0.08),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get outlinePrimary => BoxDecoration(
        color: appTheme.gray30002.withOpacity(0.25),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2.h,
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.25),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get outlinePrimary1 => BoxDecoration(
        color: theme.colorScheme.primary,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2.h,
        ),
      );

  static BoxDecoration get outlinePrimary2 => BoxDecoration(
        color: theme.colorScheme.onPrimary,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.h,
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.blueGray40019,
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 13),
          ),
        ],
      );
}

class BorderRadiusStyle {
  // Circle borders
  static BorderRadius get circleBorder24 => BorderRadius.circular(24.h);

  static BorderRadius get circleBorder60 => BorderRadius.circular(60.h);

  // Custom borders
  static BorderRadius get customBorderTL30 => BorderRadius.vertical(
        top: Radius.circular(30.h),
      );

  // Rounded borders
  static BorderRadius get roundedBorder10 => BorderRadius.circular(10.h);

  static BorderRadius get roundedBorder14 => BorderRadius.circular(14.h);

  static BorderRadius get roundedBorder20 => BorderRadius.circular(20.h);

  static BorderRadius get roundedBorder30 => BorderRadius.circular(30.h);

  static BorderRadius get roundedBorder6 => BorderRadius.circular(6.h);
}
