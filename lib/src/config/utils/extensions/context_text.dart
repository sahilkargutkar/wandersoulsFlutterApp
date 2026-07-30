import 'package:flutter/material.dart';

extension ContextText on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  TextStyle? get headlineLarge => text.headlineLarge;
  TextStyle? get headlineMedium => text.headlineMedium;
  TextStyle? get headlineSmall => text.headlineSmall;
  TextStyle? get titleLarge => text.titleLarge;
  TextStyle? get titleMedium => text.titleMedium;
  TextStyle? get titleSmall => text.titleSmall;
  TextStyle? get bodyLarge => text.bodyLarge;
  TextStyle? get bodyMedium => text.bodyMedium;
  TextStyle? get bodySmall => text.bodySmall;
  TextStyle? get labelLarge => text.labelLarge;
  TextStyle? get labelMedium => text.labelMedium;
  TextStyle? get labelSmall => text.labelSmall;

  /// Muted body text (search hints, placeholders)
  TextStyle? get bodyMuted => bodyMedium?.copyWith(
    color: Theme.of(this).colorScheme.onSurfaceVariant.withAlpha(150),
    fontWeight: FontWeight.w400,
  );

  /// Primary colored label
  TextStyle? get primaryLabel => labelMedium?.copyWith(
    color: Theme.of(this).colorScheme.primary,
    fontWeight: FontWeight.w600,
  );

  /// Caption text
  TextStyle? get caption => bodySmall?.copyWith(
    color: Theme.of(this).colorScheme.onSurfaceVariant.withAlpha(160),
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}
