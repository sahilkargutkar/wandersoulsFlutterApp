import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import '../widgets/logout_bottom_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const String routeName = "/SettingsScreen";
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          children: [
            // Upgrade Plan Card
            Container(
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [context.primary, context.primary],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.onSurfaceVariant.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 32,
                    ),
                  ),
                  16.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade Plan to Unlock More!',
                          style: context.text.titleMedium,
                        ),
                        4.h.height,
                        Text(
                          'Enjoy all the benefits and explore more possibilities',
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.onSurfaceVariant,
                    size: 28.w,
                  ),
                ],
              ),
            ),
            24.h.height,
            // Settings Menu Items
            SettingsMenuItem(
              icon: Icons.grid_view_rounded,
              title: 'Travel Preferences',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Personal Info',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.shield_outlined,
              title: 'Account & Security',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.star_outline_rounded,
              title: 'Billing & Subscriptions',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.credit_card_outlined,
              title: 'Payment Methods',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.swap_vert_rounded,
              title: 'Linked Accounts',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.remove_red_eye_outlined,
              title: 'App Appearance',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.show_chart_rounded,
              title: 'Data & Analytics',
              onTap: () {},
            ),
            SettingsMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {},
            ),
            SizedBox(height: 8.h),
            // Logout
            SettingsMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              titleColor: context.colors.error,
              iconColor: context.colors.error,
              showArrow: false,
              onTap: () {
                showLogoutBottomSheet(context);
              },
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Color? iconColor;
  final bool showArrow;
  final VoidCallback onTap;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.titleColor,
    this.iconColor,
    this.showArrow = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        color: context.colors.surface,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28.sp,
              color: iconColor ?? context.colors.onSurfaceVariant,
            ),
            16.w.width,
            Expanded(
              child: Text(
                title,
                style: context.text.titleSmall?.copyWith(color: titleColor),
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                size: 24,
                color: iconColor ?? context.colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
