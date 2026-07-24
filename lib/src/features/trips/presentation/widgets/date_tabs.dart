import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

class DateTabs extends StatelessWidget {
  final bool isSelected;
  final String label;
  const DateTabs({super.key, required this.isSelected, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected
              ? context.colors.primary
              : context.colors.onSurfaceVariant.withAlpha(150),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.colors.onSurfaceVariant,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
