import 'package:flutter/material.dart';

/// Colours mirror the web app (frontend/src/styles/_theme.scss) and the
/// JavaFX desktop app so the three clients feel like one product.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF43A047);
  static const primaryLight = Color(0xFF66BB6A);
  static const primaryDark = Color(0xFF2E7D32);
  static const primaryDarker = Color(0xFF1B5E20);
  static const bgStart = Color(0xFFF8FDF8);
  static const bgEnd = Color(0xFFE8F5E9);
  static const danger = Color(0xFFE53935);
  static const secondary = Color(0xFF2196F3);
  static const textMuted = Color(0xFF616161);
  static const border = Color(0xFFE0E0E0);
  static const surface = Color(0xFFF1F8E9);
}

class AppTheme {
  AppTheme._();

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgStart, AppColors.bgEnd],
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgStart,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: AppColors.primaryLight.withOpacity(0.1)),
        ),
      ),
    );
  }
}
