import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

class SocialLoginButtonIcon extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;

  const SocialLoginButtonIcon({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40.w, // double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        height: 30.h,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.onSurface.withAlpha(100),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}
