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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58.w,
          height: 58.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.mutedBackground,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.borderColor.withAlpha(40),
              width: 1,
            ),
          ),
          child: icon,
        ),
      ),
    );
  }
}
