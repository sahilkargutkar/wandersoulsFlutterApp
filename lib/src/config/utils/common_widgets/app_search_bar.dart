import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

/// A unified search bar widget used across the app.
///
/// Two modes:
/// - **tappable**: For home screen — navigates on tap (pass [onTap])
/// - **editable**: For search/filter screens — accepts text input (pass [controller] + [onChanged])
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onClear;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onTap,
    this.controller,
    this.onChanged,
    this.autofocus = false,
    this.trailing,
    this.leading,
    this.onClear,
  });

  bool get _isTappable => onTap != null;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: context.mutedBackground,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: context.borderColor.withAlpha(40), width: 1),
    );

    if (_isTappable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
            decoration: decoration,
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20.sp, color: context.primary),
                10.horizontalSpace,
                Expanded(
                  child: Text(
                    hintText,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.onSurfaceVariant.withAlpha(150),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (trailing != null) ...[8.horizontalSpace, trailing!],
              ],
            ),
          ),
        ),
      );
    }

    // Editable mode
    return Container(
      decoration: decoration,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        style: context.text.bodyMedium?.copyWith(
          color: context.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: hintText,
          hintStyle: context.text.bodyMedium?.copyWith(
            color: context.onSurfaceVariant.withAlpha(140),
          ),
          prefixIcon:
              leading ??
              Icon(Icons.search_rounded, size: 20.sp, color: context.primary),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  onPressed:
                      onClear ??
                      () {
                        controller?.clear();
                        onChanged?.call('');
                      },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20.sp,
                    color: context.onSurfaceVariant,
                  ),
                )
              : trailing,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 13.h,
          ),
        ),
      ),
    );
  }
}
