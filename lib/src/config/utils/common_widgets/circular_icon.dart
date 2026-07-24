import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

class CircularIcon extends StatelessWidget {
  const CircularIcon({super.key, required this.icon, required this.onTap});
  final Widget icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Card(
        color: context.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
