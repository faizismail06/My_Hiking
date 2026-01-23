import 'package:flutter/material.dart';
import '../core/app_export.dart';

extension on TextStyle {
  TextStyle get manrope {
    return copyWith(
      fontFamily: 'Manrope',
    );
  }

  TextStyle get inter {
    return copyWith(
      fontFamily: 'Inter',
    );
  }

  TextStyle get poppins {
    return copyWith(
      fontFamily: 'Poppins',
    );
  }
}

/// A collection of pre-defined text styles for customizing text appearance,
/// categorized by different font families and weights.
/// Additionally, this class includes extensions on [TextStyle] to easily apply specific font families to text.
class CustomTextStyles {
  static var bodyMediumBlack900Light;

  // Body text style
  static TextStyle get bodyMediumBluegray900 =>
      theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.blueGray900,
      );
  static TextStyle get bodyMediumGray500 =>
      theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray500,
        fontSize: 13.fSize,
      );
  static TextStyle get bodyMediumGray50003 =>
      theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray50003,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w300,
      );
  static TextStyle get bodyMediumGray50004 =>
      theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray50004,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w300,
      );
  static TextStyle get bodyMediumGray600 =>
      theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray600,
        fontSize: 13.fSize,
      );
  static TextStyle get bodyMediumInterPrimary =>
      theme.textTheme.bodyMedium!.inter.copyWith(
        color: theme.colorScheme.primary,
      );
  static TextStyle get bodySmallBlack900 => theme.textTheme.bodySmall!.copyWith(
        color: appTheme.black900,
      );
  static TextStyle get bodySmallBlack90011 =>
      theme.textTheme.bodySmall!.copyWith(
        color: appTheme.black900,
        fontSize: 11.fSize,
      );
  static TextStyle get bodySmallBlack900Light =>
      theme.textTheme.bodySmall!.copyWith(
        color: appTheme.black900,
        fontSize: 11.fSize,
        fontWeight: FontWeight.w300,
      );
  static TextStyle get bodySmallBluegray900 =>
      theme.textTheme.bodySmall!.copyWith(
        color: appTheme.blueGray900,
        fontSize: 11.fSize,
        fontWeight: FontWeight.w300,
      );
  static TextStyle get bodySmallGray50003 =>
      theme.textTheme.bodySmall!.copyWith(
        color: appTheme.gray50003,
        fontSize: 10.fSize,
      );
  static TextStyle get bodySmallGray50003Light =>
      theme.textTheme.bodySmall!.copyWith(
        color: appTheme.gray50003,
        fontSize: 11.fSize,
        fontWeight: FontWeight.w300,
      );
  static TextStyle get bodySmallGray50004 =>
      theme.textTheme.bodySmall!.copyWith(
        color: appTheme.gray50004,
      );
  static TextStyle get bodySmallGray800 => theme.textTheme.bodySmall!.copyWith(
        color: appTheme.gray800,
        fontSize: 11.fSize,
      );
  static TextStyle get bodySmallInterGray40002 =>
      theme.textTheme.bodySmall!.inter.copyWith(
        color: appTheme.gray40002,
      );
// Headline text style
  static TextStyle get headlineLargeRed700 =>
      theme.textTheme.headlineLarge!.copyWith(
        color: appTheme.red700,
        fontWeight: FontWeight.w900,
      );
  static get headlineSmall_1 => theme.textTheme.headlineSmall!;
// Label text style
  static TextStyle get labelLarge13 => theme.textTheme.labelLarge!.copyWith(
        fontSize: 13.fSize,
      );
  static TextStyle get labelLargeBluegray40002 =>
      theme.textTheme.labelLarge!.copyWith(
        color: appTheme.blueGray40002,
        fontSize: 13.fSize,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargeGray30001 =>
      theme.textTheme.labelLarge!.copyWith(
        color: appTheme.gray30001,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargeGray500 =>
      theme.textTheme.labelLarge!.copyWith(
        color: appTheme.gray500,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargeGray50004 =>
      theme.textTheme.labelLarge!.copyWith(
        color: appTheme.gray50004,
        fontSize: 13.fSize,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelLargeInterGray30001 =>
      theme.textTheme.labelLarge!.inter.copyWith(
        color: appTheme.gray30001,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargeInterGray500 =>
      theme.textTheme.labelLarge!.inter.copyWith(
        color: appTheme.gray500,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargeInterGray50001 =>
      theme.textTheme.labelLarge!.inter.copyWith(
        color: appTheme.gray50001,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargePrimary =>
      theme.textTheme.labelLarge!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelLargePrimarySemiBold =>
      theme.textTheme.labelLarge!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 13.fSize,
        fontWeight: FontWeight.w600,
      );
      static TextStyle get labelLargePrimarySemiBoldw =>
      theme.textTheme.labelLarge!.copyWith(
        color: Colors.white,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelLargePrimary_1 =>
      theme.textTheme.labelLarge!.copyWith(
        color: theme.colorScheme.primary,
      );
  static TextStyle get labelMedium10 => theme.textTheme.labelMedium!.copyWith(
        fontSize: 10.fSize,
      );
  static TextStyle get labelMedium10_1 => theme.textTheme.labelMedium!.copyWith(
        fontSize: 10.fSize,
      );
  static TextStyle get labelMediumGray50002 =>
      theme.textTheme.labelMedium!.copyWith(
        color: appTheme.gray50002,
        fontSize: 10.fSize,
      );
  static TextStyle get labelMediumGray50003 =>
      theme.textTheme.labelMedium!.copyWith(
        color: appTheme.gray50003,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelMediumGray50004 =>
      theme.textTheme.labelMedium!.copyWith(
        color: appTheme.gray50004,
        fontSize: 10.fSize,
        fontWeight: FontWeight.w900,
      );
  static TextStyle get labelMediumGray60001 =>
      theme.textTheme.labelMedium!.copyWith(
        color: appTheme.gray60001,
        fontSize: 10.fSize,
      );
  static TextStyle get labelMediumGray6000110 =>
      theme.textTheme.labelMedium!.copyWith(
        color: appTheme.gray60001,
        fontSize: 10.fSize,
      );
  static TextStyle get labelMediumInterOnPrimary =>
      theme.textTheme.labelMedium!.inter.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelMediumOnPrimary =>
      theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get labelMediumOnPrimarySemiBold =>
      theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelMediumPrimary =>
      theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 10.fSize,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get labelMediumPrimary10 =>
      theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 10.fSize,
      );
// Title text style
  static TextStyle get titleLargeBlack900 =>
      theme.textTheme.titleLarge!.copyWith(
        color: appTheme.black900,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleLargeBlack900_1 =>
      theme.textTheme.titleLarge!.copyWith(
        color: appTheme.black900.withOpacity(0.68),
      );
  static TextStyle get titleLargeBluegray800 =>
      theme.textTheme.titleLarge!.copyWith(
        color: appTheme.blueGray800,
        fontWeight: FontWeight.w700,
      );
  static get titleLargeInter => theme.textTheme.titleLarge!.inter;
  static TextStyle get titleLargePrimary =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
      );
  static TextStyle get titleLargePrimaryBlack =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w900,
      );
  static get titleLarge_1 => theme.textTheme.titleLarge!;
  static TextStyle get titleMediumBlack900 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.black900,
      );
  static TextStyle get titleMediumGray50003 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray50003,
      );
  static TextStyle get titleMediumGray50004 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray50004,
      );
  static TextStyle get titleMediumGray80001 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray80001,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumGray900 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray900,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumGray900_1 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray900,
      );
  static TextStyle get titleMediumInterGray80001 =>
      theme.textTheme.titleMedium!.inter.copyWith(
        color: appTheme.gray80001,
      );
  static TextStyle get titleMediumInterOnPrimary =>
      theme.textTheme.titleMedium!.inter.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumManrope =>
      theme.textTheme.titleMedium!.manrope.copyWith(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w800,
      );
  static TextStyle get titleMediumManropeOnPrimary =>
      theme.textTheme.titleMedium!.manrope.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumOnPrimary =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumOnPrimary_1 =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get titleMediumOnPrimary_2 =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get titleMediumSemiBold =>
      theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleSmallBlack900 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.black900,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallBlack90015 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.black900,
        fontSize: 15.fSize,
      );
  static TextStyle get titleSmallBlack900Medium =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.black900,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallBlack900_1 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.black900.withOpacity(0.68),
      );
  static TextStyle get titleSmallBluegray400 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.blueGray400,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallGray50003 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.gray50003,
        fontSize: 15.fSize,
      );
  static TextStyle get titleSmallGray50003Medium =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.gray50003,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallGray900 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.gray900,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallInterOnPrimary =>
      theme.textTheme.titleSmall!.inter.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get titleSmallLightblue900 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.lightBlue900,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleSmallOnPrimary =>
      theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get titleSmallOnPrimaryMedium =>
      theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallPrimary =>
      theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleSmallPrimaryMedium =>
      theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 15.fSize,
        fontWeight: FontWeight.w500,
      );
}
