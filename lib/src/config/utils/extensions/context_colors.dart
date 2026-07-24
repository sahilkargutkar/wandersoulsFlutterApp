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
  Color get mutedBackground => onSurface.withAlpha(20);

  /// Soft shadow
  Color get softShadow => onSurface.withAlpha(25);
}
