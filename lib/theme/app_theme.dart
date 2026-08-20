import 'package:flutter/material.dart';

/// Central place for colors, gradients, and the ThemeData used across the
/// app — keeps the "attractive" styling consistent instead of scattered
/// magic numbers in every screen.
class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF4834D4);
  static const accent = Color(0xFFFF6B9D);
  static const background = Color(0xFFF7F6FB);
  static const surface = Colors.white;
  static const textDark = Color(0xFF2D2D3A);
  static const textMuted = Color(0xFF8A8A9E);
  static const danger = Color(0xFFE74C3C);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFFFF6B9D)],
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1.5,
        shadowColor: AppColors.primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// For destructive/high-stakes confirmations (delete, log out) — visually
  /// distinct (red) from the default purple FilledButton so a confirm
  /// dialog doesn't look identical to a routine "Save"/"Continue" button.
  static ButtonStyle get dangerButtonStyle => FilledButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  /// A short, rotating set of soft accent colors used to give repeated
  /// small elements (like note-list leading icons) some visual variety
  /// instead of every single one using the identical accent gradient.
  static const List<List<Color>> tileAccents = [
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    [Color(0xFFFF6B9D), Color(0xFFFFA6C9)],
    [Color(0xFF00B894), Color(0xFF55EFC4)],
    [Color(0xFFFD9644), Color(0xFFFFC069)],
    [Color(0xFF0984E3), Color(0xFF74B9FF)],
  ];

  static LinearGradient tileAccentGradient(int index) {
    final colors = tileAccents[index % tileAccents.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
