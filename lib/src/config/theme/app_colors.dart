import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Light Theme ───────────────────────────────────────────
  static const lightPrimary = Color(0xFF0D9F6E);
  static const lightPrimaryLight = Color(0xFF34D399);
  static const lightPrimaryDark = Color(0xFF047857);
  static const lightBackground = Color(0xFFFAFBFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFF3F4F6);
  static const lightText = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightCardShadow = Color(0x0A000000);

  // ─── Dark Theme ────────────────────────────────────────────
  static const darkPrimary = Color(0xFF10B981);
  static const darkPrimaryLight = Color(0xFF6EE7B7);
  static const darkPrimaryDark = Color(0xFF059669);
  static const darkBackground = Color(0xFF0F1117);
  static const darkSurface = Color(0xFF1A1D27);
  static const darkSurfaceContainer = Color(0xFF242733);
  static const darkText = Color(0xFFF3F4F6);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF374151);
  static const darkCardShadow = Color(0x1A000000);

  // ─── Accent / Semantic ─────────────────────────────────────
  static const accent = Color(0xFFF59E0B); // Warm amber
  static const accentSoft = Color(0xFFFEF3C7);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ─── Gradients ─────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9F6E), Color(0xFF059669)],
  );

  static const primaryGradientVibrant = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F1117), Color(0xFF1A1D27)],
  );

  static const shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    stops: [0.0, 0.5, 1.0],
  );
}
