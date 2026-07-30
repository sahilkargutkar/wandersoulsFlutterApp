import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';

import '../../../auth/presentation/cubit/login/auth_cubit.dart';

void showLogoutBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red warning logout icon
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: context.colors.error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: context.colors.error,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                "Logout",
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.onSurface,
                ),
              ),
              SizedBox(height: 10.h),

              Text(
                "Are you sure you want to log out of your account?",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 28.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        side: BorderSide(
                          color: context.borderColor,
                          width: 1.2,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        shadowColor: context.colors.error.withAlpha(40),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthCubit>().logout();
                        context.go(LoginScreen.routeName);
                      },
                      child: Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
