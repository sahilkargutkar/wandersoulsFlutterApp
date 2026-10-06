import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/theme/app_colors.dart';
import 'package:wonder_souls/src/config/theme/theme_cubit.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/profile_image_helper.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';

import '../widgets/logout_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/personal_info_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/travel_preferences_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/billing_subscriptions_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/upgrade_plan_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/payment_methods_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/account_security_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const String routeName = "/SettingsScreen";
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = sl.isRegistered<AuthLocalDataSource>()
        ? sl<AuthLocalDataSource>().getUser()
        : null;
    final isLoggedIn = user != null && (user.id?.isNotEmpty ?? false);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: context.borderColor.withAlpha(40),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.softShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ProfileImageHelper.buildAvatar(
                    context,
                    user: user,
                    radius: 28.r,
                    borderWidth: 2,
                    borderColor: context.primary,
                  ),
                  14.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn
                              ? (user.name?.isNotEmpty == true
                                  ? user.name!
                                  : (user.userName ?? "Traveler"))
                              : "Guest Explorer 👋",
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        4.h.height,
                        Text(
                          isLoggedIn
                              ? (user.email ?? "Member")
                              : "Sign in to sync your trips & saved items",
                          style: context.text.bodySmall?.copyWith(
                            color: context.onSurfaceVariant,
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isLoggedIn)
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: context.primary,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        context.push(PersonalInfoScreen.routeName).then((_) {
                          setState(() {});
                        });
                      },
                    )
                  else
                    ElevatedButton(
                      onPressed: () => context.push(LoginScreen.routeName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: const Text("Sign In"),
                    ),
                ],
              ),
            ),
            16.h.height,

            // Upgrade Plan Card
            InkWell(
              onTap: () => context.push(UpgradePlanScreen.routeName),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradientVibrant,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 30,
                      ),
                    ),
                    16.w.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade Plan to Unlock More!',
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          4.h.height,
                          Text(
                            'Enjoy all the benefits and explore more possibilities',
                            style: context.text.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(210),
                              fontSize: 13.sp,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 26.w,
                    ),
                  ],
                ),
              ),
            ),
            24.h.height,

            _buildSectionHeader("Account & Preferences"),
            8.h.height,
            _buildGroupedCard([
              SettingsMenuItem(
                icon: Icons.grid_view_rounded,
                title: 'Travel Preferences',
                onTap: () {
                  context.push(TravelPreferencesScreen.routeName);
                },
              ),
              SettingsMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Personal Info',
                onTap: () {
                  if (!isLoggedIn) {
                    context.push(LoginScreen.routeName);
                  } else {
                    context.push(PersonalInfoScreen.routeName).then((_) {
                      setState(() {});
                    });
                  }
                },
              ),
              SettingsMenuItem(
                icon: Icons.shield_outlined,
                title: 'Account & Security',
                onTap: () {
                  if (!isLoggedIn) {
                    context.push(LoginScreen.routeName);
                  } else {
                    context.push(AccountSecurityScreen.routeName);
                  }
                },
              ),
            ]),
            20.h.height,

            _buildSectionHeader("Billing"),
            8.h.height,
            _buildGroupedCard([
              SettingsMenuItem(
                icon: Icons.star_outline_rounded,
                title: 'Billing & Subscriptions',
                onTap: () {
                  context.push(BillingSubscriptionsScreen.routeName);
                },
              ),
              SettingsMenuItem(
                icon: Icons.credit_card_outlined,
                title: 'Payment Methods',
                onTap: () {
                  context.push(PaymentMethodsScreen.routeName);
                },
              ),
            ]),
            20.h.height,

            _buildSectionHeader("App Settings"),
            8.h.height,
            _buildGroupedCard([
              SettingsMenuItem(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode Theme',
                showArrow: false,
                trailingWidget: BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    final isDark =
                        themeMode == ThemeMode.dark ||
                        (themeMode == ThemeMode.system &&
                            MediaQuery.of(context).platformBrightness ==
                                Brightness.dark);
                    return Switch(
                      value: isDark,
                      activeThumbColor: context.primary,
                      onChanged: (value) {
                        context.read<ThemeCubit>().toggleTheme(value);
                      },
                    );
                  },
                ),
                onTap: () {},
              ),
              SettingsMenuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () {
                  context.push(TermsAndConditionsScreen.routeName);
                },
              ),
              SettingsMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  launchUrl(
                    Uri.parse("https://www.wandersouls.in/privacy-policy/"),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ]),
            24.h.height,

            // Login / Logout Section
            if (isLoggedIn)
              _buildGroupedCard([
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
              ])
            else
              _buildGroupedCard([
                SettingsMenuItem(
                  icon: Icons.login_rounded,
                  title: 'Sign In / Register',
                  titleColor: context.primary,
                  iconColor: context.primary,
                  showArrow: true,
                  onTap: () {
                    context.push(LoginScreen.routeName);
                  },
                ),
              ]),
            100.h.height,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title.toUpperCase(),
        style: context.text.titleSmall?.copyWith(
          color: context.onSurfaceVariant.withAlpha(180),
          fontWeight: FontWeight.w700,
          fontSize: 13.sp,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: context.softShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: context.borderColor.withAlpha(30), width: 1),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          final isLast = index == children.length - 1;
          return Column(
            children: [
              children[index],
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 56.w,
                  endIndent: 16.w,
                  color: context.borderColor.withAlpha(20),
                ),
            ],
          );
        }),
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
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.titleColor,
    this.iconColor,
    this.showArrow = true,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (iconColor ?? context.colors.onSurfaceVariant)
                      .withAlpha(12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: iconColor ?? context.colors.onSurfaceVariant,
                ),
              ),
              16.w.width,
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    color: titleColor ?? context.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else if (showArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: context.colors.onSurfaceVariant.withAlpha(120),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
