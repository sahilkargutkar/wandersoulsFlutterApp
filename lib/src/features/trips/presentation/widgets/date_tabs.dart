import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

class DateTabs extends StatelessWidget {
  final bool isSelected;
  final String label;
  const DateTabs({super.key, required this.isSelected, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? context.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected
              ? context.primary
              : context.borderColor.withAlpha(60),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: context.primary.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : context.onSurfaceVariant,
          fontSize: 13.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
