import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

import 'package:wonder_souls/src/config/utils/common_widgets/animated_press.dart';

class CircularIcon extends StatelessWidget {
  const CircularIcon({super.key, required this.icon, required this.onTap});
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      scaleFactor: 0.90, // bounce factor for small icons
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: context.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.softShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}
