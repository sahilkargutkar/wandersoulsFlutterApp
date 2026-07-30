import 'package:flutter/material.dart';

extension ContextColors on BuildContext {
  /// Shortcuts
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Commonly used colors
  Color get primary => colors.primary;
  Color get onPrimary => colors.onPrimary;

  Color get surface => colors.surface;
  Color get onSurface => colors.onSurface;
  Color get onSurfaceVariant => colors.onSurfaceVariant;

  Color get outline => colors.outline;

  /// Muted / subtle background (perfect for search bars, cards)
  Color get mutedBackground => onSurface.withAlpha(12);

  /// Soft shadow
  Color get softShadow => onSurface.withAlpha(20);

  /// Card background with slight elevation feel
  Color get cardBackground => colors.surface;

  /// Subtle primary tint for backgrounds
  Color get primaryTint => primary.withAlpha(15);

  /// Shimmer base color for loading
  Color get shimmerBase => onSurface.withAlpha(18);
  Color get shimmerHighlight => onSurface.withAlpha(8);

  /// Border color
  Color get borderColor => colors.outline.withAlpha(100);

  /// Check if dark mode
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
