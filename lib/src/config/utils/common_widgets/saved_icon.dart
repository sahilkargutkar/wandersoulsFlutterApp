import 'package:flutter/material.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

class SavedIcon extends StatelessWidget {
  const SavedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: context.colors.surface, // small theme-aware card for icon
      elevation: 2,
      shadowColor: context.colors.onSurface.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.bookmark_border,
          size: 20,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}
