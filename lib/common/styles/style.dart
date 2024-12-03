import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Text Styles
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.nunito(
      fontSize: 102,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
    ),
    displayMedium: GoogleFonts.nunito(
      fontSize: 64,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.nunito(
      fontSize: 51,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: GoogleFonts.nunito(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.25,
    ),
    headlineSmall: GoogleFonts.nunito(
      fontSize: 25,
      fontWeight: FontWeight.w800,

    ),
    titleLarge: GoogleFonts.nunito(
      fontSize: 21,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    titleMedium: GoogleFonts.nunito(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.nunito(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.nunitoSans(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: GoogleFonts.nunitoSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    labelLarge: GoogleFonts.nunitoSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
    ),
    bodySmall: GoogleFonts.nunitoSans(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelSmall: GoogleFonts.nunitoSans(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
    ),
  );

  // Colors
  static const Color background = Color(0xFFedf0f5);
  static const Color text = Color(0xFF000000);
  static const Color icon = Color(0xFF333333);
  static const Color caption = Color(0xFFadb9d3);
  static const Color button = Color(0xFF3a5795);
  static const Color buttonDisabled = Color(0xFFd3d3d3);
  static const Color buttonHover = Color(0xFF2e4e8c);
  static const Color buttonText = Color(0xFFedf0f5);
  static const Color border = Color(0xFF637bad);

  // Padding and Margin
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(8.0);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(vertical: 8.0);

  // Border Radius
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(10.0));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(5.0));

  // outlineBorder
  static const BorderSide defaultBorder = BorderSide(
    color: border,
    width: 1.0,
  );

  static BoxDecoration outlinedBox({
    Color color = background,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: border, width: 1.0),
      borderRadius: borderRadius ?? cardRadius,
      boxShadow: boxShadow,
    );
  }

  // Theme Data
  ThemeData get light {
    return ThemeData(
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: button,
        onPrimary: buttonText,
        secondary: buttonHover,
        onSecondary: buttonText,
        surface: background,
        onSurface: text,
      ),
      iconTheme: const IconThemeData(color: icon),
      buttonTheme: const ButtonThemeData(
        buttonColor: button,
        disabledColor: buttonDisabled,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
      cardTheme: const CardTheme(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
        ),
        elevation: 4,
      ),
    );
  }

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkIcon = Color(0xFFCCCCCC);
  static const Color darkCaption = Color(0xFF8E8E8E);
  static const Color darkButton = Color(0xFF4267B2);
  static const Color darkButtonDisabled = Color(0xFF4D4D4D);
  static const Color darkButtonHover = Color(0xFF365899);
  static const Color darkButtonText = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFF4D4D4D);

  // Dark theme
  ThemeData get dark {
    return ThemeData(
      textTheme: textTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkButton,
        onPrimary: darkButtonText,
        secondary: darkButtonHover,
        onSecondary: darkButtonText,
        surface: darkBackground,
        onSurface: darkText,
      ),
      iconTheme: const IconThemeData(color: darkIcon),
      buttonTheme: const ButtonThemeData(
        buttonColor: darkButton,
        disabledColor: darkButtonDisabled,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
      cardTheme: const CardTheme(
        color: darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: darkBorder, width: 1.0),
        ),
        elevation: 4,
      ),
      appBarTheme: const AppBarTheme(
        color: darkBackground,
        iconTheme: IconThemeData(color: darkIcon),
        titleTextStyle: TextStyle(color: darkText),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        fillColor: darkBackground,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: darkBorder),
          borderRadius: buttonRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkBorder),
          borderRadius: buttonRadius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkButton),
          borderRadius: buttonRadius,
        ),
        labelStyle: TextStyle(color: darkCaption),
        hintStyle: TextStyle(color: darkCaption),
      ),
    );
  }
}
