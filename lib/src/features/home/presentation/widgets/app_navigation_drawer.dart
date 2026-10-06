import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/theme/theme_cubit.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/profile_image_helper.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/personal_info_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/terms_and_conditions_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/widgets/logout_bottom_sheet.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_article.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/create_trip_modal_bottom_sheet.dart';

class AppNavigationDrawer extends StatelessWidget {
  final Function(int tabIndex)? onSelectTab;

  const AppNavigationDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final user = sl.isRegistered<AuthLocalDataSource>()
        ? sl<AuthLocalDataSource>().getUser()
        : null;
    final isLoggedIn = user != null && (user.id?.isNotEmpty ?? false);

    return Drawer(
      backgroundColor: context.surface,
      child: SafeArea(
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: context.primary.withAlpha(12),
                border: Border(
                  bottom: BorderSide(
                    color: context.borderColor.withAlpha(40),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ProfileImageHelper.buildAvatar(
                    context,
                    user: user,
                    radius: 26.r,
                    borderWidth: 2,
                    borderColor: context.primary,
                    onTap: isLoggedIn
                        ? () {
                            Navigator.pop(context);
                            context.push(PersonalInfoScreen.routeName);
                          }
                        : null,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn
                              ? (user.name?.isNotEmpty == true
                                  ? user.name!
                                  : (user.userName ?? "Traveler"))
                              : "Welcome, Traveler 👋",
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        if (isLoggedIn)
                          Text(
                            user.email ?? "",
                            style: context.text.bodySmall?.copyWith(
                              color: context.onSurfaceVariant,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              context.push(LoginScreen.routeName);
                            },
                            child: Text(
                              "Sign In / Create Account ➔",
                              style: context.text.bodySmall?.copyWith(
                                color: context.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: "Home & Explore",
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    title: "AI Trip Planner",
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    title: "Create Trip",
                    iconColor: context.primary,
                    onTap: () {
                      Navigator.pop(context);
                      showCreateTripModal(context, onSelectTab: onSelectTab);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.public_rounded,
                    title: "Public Community Trips",
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.explore_rounded,
                    title: "Popular Destinations",
                    onTap: () {
                      Navigator.pop(context);
                      context.push(ListDestination.routeName);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.article_rounded,
                    title: "Travel Articles & Guides",
                    onTap: () {
                      Navigator.pop(context);
                      context.push(ListArticle.routeName);
                    },
                  ),
                  Divider(
                    height: 24.h,
                    color: context.borderColor.withAlpha(30),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.bookmark_rounded,
                    title: "Saved Places & Articles",
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.map_outlined,
                    title: "My Trips",
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(3);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.description_outlined,
                    title: "Terms & Conditions",
                    onTap: () {
                      Navigator.pop(context);
                      context.push(TermsAndConditionsScreen.routeName);
                    },
                  ),
                ],
              ),
            ),

            // Footer (Theme Switch & Auth Button)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: context.mutedBackground,
                border: Border(
                  top: BorderSide(
                    color: context.borderColor.withAlpha(30),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.dark_mode_outlined,
                            size: 20.sp,
                            color: context.onSurfaceVariant,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            "Dark Mode",
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          final isDark = themeMode == ThemeMode.dark ||
                              (themeMode == ThemeMode.system &&
                                  MediaQuery.of(context).platformBrightness ==
                                      Brightness.dark);
                          return Switch(
                            value: isDark,
                            activeThumbColor: context.primary,
                            onChanged: (val) {
                              context.read<ThemeCubit>().toggleTheme(val);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (isLoggedIn)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showLogoutBottomSheet(context);
                        },
                        icon: Icon(
                          Icons.logout_rounded,
                          color: context.colors.error,
                          size: 18.sp,
                        ),
                        label: Text(
                          "Log Out",
                          style: TextStyle(
                            color: context.colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push(LoginScreen.routeName);
                        },
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text("Sign In"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: (iconColor ?? context.primary).withAlpha(15),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: iconColor ?? context.primary,
        ),
      ),
      title: Text(
        title,
        style: context.text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18.sp,
        color: context.onSurfaceVariant.withAlpha(100),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      dense: true,
    );
  }
}
