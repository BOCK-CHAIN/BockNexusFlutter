import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return base.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(textStyle: base.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
      displayMedium: GoogleFonts.playfairDisplay(textStyle: base.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
      displaySmall: GoogleFonts.playfairDisplay(textStyle: base.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
      headlineLarge: GoogleFonts.playfairDisplay(textStyle: base.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      headlineMedium: GoogleFonts.playfairDisplay(textStyle: base.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      headlineSmall: GoogleFonts.playfairDisplay(textStyle: base.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      titleLarge: GoogleFonts.playfairDisplay(textStyle: base.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      titleMedium: GoogleFonts.lato(textStyle: base.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      titleSmall: GoogleFonts.lato(textStyle: base.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      bodyLarge: GoogleFonts.lato(textStyle: base.bodyLarge?.copyWith(color: textColor)),
      bodyMedium: GoogleFonts.lato(textStyle: base.bodyMedium?.copyWith(color: textColor)),
      bodySmall: GoogleFonts.lato(textStyle: base.bodySmall?.copyWith(color: textColor)),
      labelLarge: GoogleFonts.lato(textStyle: base.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
      labelMedium: GoogleFonts.lato(textStyle: base.labelMedium?.copyWith(color: textColor)),
      labelSmall: GoogleFonts.lato(textStyle: base.labelSmall?.copyWith(color: textColor)),
    );
  }

  static ThemeData get lightTheme {
    final ThemeData base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.textPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
        error: AppColors.errorDark,
        onPrimary: AppColors.onPrimaryDark,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.textPrimaryDark),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryDark),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorDark),
        ),
      ),
    );
  }
}
