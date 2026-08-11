import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Screens
import 'package:wonder_souls/src/features/home/presentation/screens/home_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/settings_screens.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/saved_trips_screen.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

import '../../../../config/core/assets/assets.dart';

class HomeBottomBar extends StatefulWidget {
  const HomeBottomBar({super.key});

  static const String routeName = "/HomeBottomBar";
  @override
  State<HomeBottomBar> createState() => _HomeBottomBarState();
}

class _HomeBottomBarState extends State<HomeBottomBar>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SavedTripsScreen(),
    const MyTripsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 46.h,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Image.asset(
            Assets.logo,
            height: 36.h,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return (_tabController.index == 1 || _tabController.index == 2)
                  ? Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: context.mutedBackground,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: context.onSurfaceVariant,
                          size: 20.sp,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),

      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark
                  ? context.surface.withAlpha(230)
                  : context.surface.withAlpha(240),
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(context.isDark ? 30 : 12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: context.borderColor.withAlpha(context.isDark ? 20 : 30),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  controller: _tabController,
                  labelColor: context.primary,
                  unselectedLabelColor: context.onSurfaceVariant.withAlpha(140),
                  indicatorColor: context.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorPadding: EdgeInsets.only(bottom: 6.h),
                  splashBorderRadius: BorderRadius.circular(28.r),
                  tabs: const [
                    Tab(icon: Icon(Icons.home_rounded, size: 24), text: 'Home'),
                    Tab(
                      icon: Icon(Icons.bookmark_border_rounded, size: 24),
                      text: 'Saved',
                    ),
                    Tab(
                      icon: Icon(Icons.location_on_outlined, size: 24),
                      text: 'My Trips',
                    ),
                    Tab(
                      icon: Icon(Icons.settings_outlined, size: 24),
                      text: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
