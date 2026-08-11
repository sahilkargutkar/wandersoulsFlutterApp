import 'package:flutter/material.dart';
import 'package:wonder_souls/src/config/theme/app_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

import 'package:wonder_souls/src/config/utils/common_widgets/animated_press.dart';

class CommonButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final bool useGradient;
  final IconData? icon;

  const CommonButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.useGradient = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? context.colors.primary;
    final fgColor = textColor ?? Colors.white;
    final bool isEnabled = onPressed != null && !isLoading;

    return AnimatedPress(
      onTap: isEnabled ? onPressed : null,
      scaleFactor: 0.97,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: useGradient ? AppColors.primaryGradient : null,
            color: useGradient
                ? null
                : (isLoading || onPressed == null)
                ? bgColor.withAlpha(140)
                : bgColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: (isLoading || onPressed == null)
                ? null
                : [
                    BoxShadow(
                      color: bgColor.withAlpha(40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fgColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
