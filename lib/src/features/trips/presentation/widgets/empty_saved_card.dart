import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class EmptySavedCard extends StatelessWidget {
  const EmptySavedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.primary.withAlpha(20),
                    context.primary.withAlpha(8),
                  ],
                ),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 40.sp,
                color: context.primary.withAlpha(150),
              ),
            ),
            24.h.height,
            Text(
              'No Saved Places',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            12.h.height,
            Text(
              'Start building your dream wishlist by saving destinations and experiences you love',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                height: 1.5,
                color: context.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
