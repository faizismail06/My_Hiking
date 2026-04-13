import 'package:flutter/material.dart';
import '../core/app_export.dart';

/// A class that offers pre-defined button styles for customizing button appearance.
class CustomButtonStyles {
  // Gradient button styles (Modern)
  static ButtonStyle get gradientGreenPrimary => ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
        shadowColor: appTheme.green600.withOpacity(0.3),
      );

  static ButtonStyle get gradientGreenEmerald => ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.h),
        ),
        elevation: 8,
        padding: EdgeInsets.zero,
        shadowColor: appTheme.green600.withOpacity(0.4),
      );

  // Filled button styles
  static ButtonStyle get fillBlueGray => ElevatedButton.styleFrom(
        backgroundColor: appTheme.green50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.h),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get fillPrimary => ElevatedButton.styleFrom(
        backgroundColor: appTheme.green600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26.h),
        ),
        elevation: 6,
        padding: EdgeInsets.zero,
        shadowColor: appTheme.green600.withOpacity(0.3),
      );

  static ButtonStyle get fillPrimaryTL12 => ElevatedButton.styleFrom(
        backgroundColor: appTheme.green600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        elevation: 4,
        padding: EdgeInsets.zero,
        shadowColor: appTheme.green600.withOpacity(0.2),
      );

  static ButtonStyle get fillPrimaryTL8 => ElevatedButton.styleFrom(
        backgroundColor: appTheme.green600.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.h),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get fillRed => ElevatedButton.styleFrom(
        backgroundColor: appTheme.red700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get fillRed2 => ElevatedButton.styleFrom(
        backgroundColor: appTheme.red700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26.h),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );
  // New gray button style for disabled state
  static ButtonStyle get fillGray => ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // Gray background for disabled button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26.h),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

  // Outline button styles
  static ButtonStyle get outlineBlack => ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.h),
        ),
        shadowColor: appTheme.black900.withOpacity(0.1),
        elevation: 2,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineBlackTL14 => ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.h),
        ),
        shadowColor: appTheme.black900.withOpacity(0.08),
        elevation: 2,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineBlueGray => OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: appTheme.blueGray5001,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.h),
        ),
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineBlueGrayC => ElevatedButton.styleFrom(
        backgroundColor: appTheme.black900.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.h),
        ),
        shadowColor: appTheme.blueGray3000c,
        elevation: 26,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineGray => OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.onPrimary,
        side: BorderSide(
          color: appTheme.green600,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.h),
        ),
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineTeal => ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        shadowColor: appTheme.teal40051,
        elevation: 16,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineTeal1 => ElevatedButton.styleFrom(
        backgroundColor: appTheme.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        shadowColor: appTheme.teal40051,
        elevation: 16,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineTeal2 => ElevatedButton.styleFrom(
        backgroundColor: appTheme.gray100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        shadowColor: appTheme.teal40051,
        elevation: 16,
        padding: EdgeInsets.zero,
      );

  static ButtonStyle get outlineTealTL12 => ElevatedButton.styleFrom(
        backgroundColor: appTheme.gray50003,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        shadowColor: appTheme.teal40051,
        elevation: 16,
        padding: EdgeInsets.zero,
      );

  // Text button style
  static ButtonStyle get none => ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
        elevation: MaterialStateProperty.all<double>(0),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero),
        side: MaterialStateProperty.all<BorderSide>(
          const BorderSide(color: Colors.transparent),
        ),
      );
}
