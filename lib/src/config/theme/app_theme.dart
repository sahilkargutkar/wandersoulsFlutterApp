import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light = _theme(Brightness.light);
  static ThemeData dark = _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onPrimary: Colors.white,
      secondary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onSecondary: Colors.white,
      surface: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      onSurface: isDark ? AppColors.darkText : AppColors.lightText,
      error: Colors.red,
      onSurfaceVariant: isDark ? AppColors.darkText : AppColors.lightText,

      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        shadowColor: scheme.onSurface.withAlpha(250),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.onSurface.withAlpha(80),
            width: 1.2,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary, // 👈 Highlight color
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: _textTheme(scheme),
    );
  }

  static TextTheme _textTheme(ColorScheme colors) {
    return TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.onSurfaceVariant,
      ),
      labelMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.onPrimary,
      ),
    );
  }
}
