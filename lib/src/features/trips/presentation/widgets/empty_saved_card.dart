import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/saved_icon.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class EmptySavedCard extends StatelessWidget {
  const EmptySavedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: context.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SavedIcon(),
              24.h.height,
              Text(
                'Empty',
                style: context.titleLarge?.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              8.h.height,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'Start building your dream wishlist by slowly\nmarking destinations and experiences',
                  textAlign: TextAlign.center,
                  style: context.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    height: 1.5,
                    color: context.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
