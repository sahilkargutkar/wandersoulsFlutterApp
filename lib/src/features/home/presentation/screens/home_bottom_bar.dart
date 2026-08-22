import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Screens
import 'package:wonder_souls/src/features/home/presentation/screens/home_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/settings_screens.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/saved_trips_screen.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/app_search_bar.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>("");
  bool _isSearching = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _pages = [
      const HomeScreen(),
      SavedTripsScreen(searchNotifier: _searchNotifier),
      MyTripsScreen(searchNotifier: _searchNotifier),
      const SettingsScreen(),
    ];
  }

  void _handleTabChange() {
    if (_isSearching) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
        _searchNotifier.value = "";
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchNotifier.dispose();
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
        title: _isSearching
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppSearchBar(
                  hintText: _tabController.index == 1
                      ? "Search saved..."
                      : "Search your trips...",
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) {
                    _searchNotifier.value = value;
                  },
                  onClear: () {
                    _searchController.clear();
                    _searchNotifier.value = "";
                  },
                ),
              )
            : Padding(
                padding: EdgeInsets.only(left: 16.w),
                child: Image.asset(
                  Assets.logo,
                  height: 36.h,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
        actions: _isSearching
            ? [
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.onSurface),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchNotifier.value = "";
                    });
                  },
                ),
                SizedBox(width: 8.w),
              ]
            : [
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return (_tabController.index == 1 ||
                            _tabController.index == 2)
                        ? Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
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

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(
            top: BorderSide(
              color: context.borderColor.withAlpha(context.isDark ? 30 : 60),
              width: 1.h,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64.h,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return TabBar(
                  dividerColor: Colors.transparent,
                  controller: _tabController,
                  labelColor: context.primary,
                  unselectedLabelColor: const Color(0xFF9CA3AF),
                  indicator: const BoxDecoration(), // Remove indicator bar completely
                  labelStyle: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  indicatorPadding: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                      icon: Icon(
                        _tabController.index == 0
                            ? Icons.home_filled
                            : Icons.home_outlined,
                        size: 24.sp,
                      ),
                      text: 'Home',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                      icon: Icon(
                        _tabController.index == 1
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 24.sp,
                      ),
                      text: 'Saved',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                      icon: Icon(
                        _tabController.index == 2
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        size: 24.sp,
                      ),
                      text: 'My Trips',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                      icon: Icon(
                        _tabController.index == 3
                            ? Icons.settings
                            : Icons.settings_outlined,
                        size: 24.sp,
                      ),
                      text: 'Settings',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
