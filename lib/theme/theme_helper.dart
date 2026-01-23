import 'package:flutter/material.dart';
import '../core/app_export.dart';

LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.
class ThemeHelper {
  // The current app theme
  final _appTheme = PrefUtils().getThemeData();

  // A map of custom color themes supported by the app
  final Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors(),
  };

  // A map of color schemes supported by the app
  final Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme,
  };

  /// Returns the lightCode colors for the current theme.
  LightCodeColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      textTheme: TextThemes.textTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.onPrimary,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
          padding: EdgeInsets.zero,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.onPrimary,
          side: BorderSide(color: colorScheme.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
          padding: EdgeInsets.zero,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: appTheme.blueGray5002,
      ),
    );
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

/// Class containing the supported text theme styles.
class TextThemes {
  static TextTheme textTheme(ColorScheme colorScheme) => TextTheme(
        bodyLarge: TextStyle(
          color: colorScheme.primary,
          fontSize: 16.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: appTheme.blueGray40002,
          fontSize: 14.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: appTheme.blueGray40001,
          fontSize: 12.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: appTheme.blueGray900,
          fontSize: 48.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: colorScheme.primary,
          fontSize: 32.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          color: colorScheme.primary,
          fontSize: 24.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: appTheme.blueGray900,
          fontSize: 11.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: colorScheme.primary,
          fontSize: 8.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 20.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: colorScheme.primary,
          fontSize: 16.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: appTheme.blueGray700,
          fontSize: 14.fSize,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      );
}

/// Class containing the supported color schemes.
class ColorSchemes {
  static const lightCodeColorScheme = ColorScheme.light(
    primary: Color(0XFF127857),
    secondaryContainer: Color(0X14314F7C),
    onPrimary: Color(0XFFFFFFFF),
    onPrimaryContainer: Color(0XFF292B3A),
  );
}

/// Class containing custom colors for a lightCode theme.
class LightCodeColors {
  // Black
  Color get black900 => const Color(0XFF000000);

  // BlueGray
  Color get blueGray100 => const Color(0XFFD7D7D7);
  Color get blueGray10001 => const Color(0XFFD9D9D9);
  Color get blueGray10002 => const Color(0XFFCAD8EA);
  Color get blueGray400 => const Color(0XFF8D8D8D);
  Color get blueGray40001 => const Color(0XFF838FA0);
  Color get blueGray40002 => const Color(0XFF7F88A6);
  Color get blueGray40019 => const Color(0X19887AA5);
  Color get blueGray50 => const Color(0XFFE9F0EE);
  Color get blueGray5001 => const Color(0XFFEFF0F2);
  Color get blueGray5002 => const Color(0XFFEAECF0);
  Color get blueGray700 => const Color(0XFF3F4764);
  Color get blueGray800 => const Color(0XFF323F4B);
  Color get blueGray900 => const Color(0XFF373737);

  // BlueGrayc
  Color get blueGray3000c => const Color(0X0C8D9BAA);

  // Gray
  Color get gray200 => const Color(0XFFF0F0F0);
  Color get gray300 => const Color(0XFFE3E5EB);
  Color get gray30001 => const Color(0XFFDAE2DF);
  Color get gray30002 => const Color(0XFFD9E9E4);
  Color get gray400 => const Color(0XFFB5B5B5);
  Color get gray40001 => const Color(0XFFB8B8B8);
  Color get gray40002 => const Color(0XFFABB0AF);
  Color get gray40003 => const Color(0XFFC1C1C1);
  Color get gray40019 => const Color(0X19C5C5C5);
  Color get gray50 => const Color(0XFFFAFCFF);
  Color get gray500 => const Color(0XFFA2AAA8);
  Color get gray50001 => const Color(0XFFA3ABA8);
  Color get gray50002 => const Color(0XFF939393);
  Color get gray50003 => const Color(0XFF979797);
  Color get gray50004 => const Color(0XFF959595);
  Color get gray5001 => const Color(0XFFFAFAFA);
  Color get gray600 => const Color(0XFF746A6A);
  Color get gray60001 => const Color(0XFF6B6B6B);
  Color get gray800 => const Color(0XFF373C3A);
  Color get gray80001 => const Color(0XFF363B3A);
  Color get gray900 => const Color(0XFF25272A);
  Color get gray100 => const Color(0xFF979797);

  // Green
  Color get greenA700 => const Color(0XFF0FA958);

  // LightBlue
  Color get lightBlue200 => const Color(0XFF85D3FF);
  Color get lightBlue900 => const Color(0XFF034A8B);

  // LightGreen
  Color get lightGreenA700 => const Color(0XFF3FC700);

  // Red
  Color get red600 => const Color(0xFFD32F2F);
  Color get red700 => const Color(0XFFD62F2F);
  Color get redA700 => const Color(0XFFFF0000);

  // Teal
  Color get teal40051 => const Color(0X5128A176);
  Color get teal800 => const Color(0XFF127958);
  Color get teal900 => const Color(0XFF064E3A);

  // Orange
  Color get orange => const Color(0xffffa8949);
}
