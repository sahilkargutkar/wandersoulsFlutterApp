import 'package:flutter/material.dart';

extension ContextText on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  TextStyle? get titleLarge => text.titleLarge;
  TextStyle? get labelLarge => text.labelLarge;
  TextStyle? get labelMedium => text.labelMedium;
  TextStyle? get bodyMedium => text.bodyMedium;

  /// Muted body text (search hints, placeholders)
  TextStyle? get bodyMuted => bodyMedium?.copyWith(
    color: Theme.of(this).colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w400,
  );

  /// Primary colored label
  TextStyle? get primaryLabel => labelMedium?.copyWith(
    color: Theme.of(this).colorScheme.primary,
    fontWeight: FontWeight.w500,
  );
}
