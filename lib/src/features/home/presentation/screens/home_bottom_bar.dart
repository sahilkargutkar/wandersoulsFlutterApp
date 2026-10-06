import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/assets/assets.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/app_search_bar.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/profile_image_helper.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/home_screen.dart';
import 'package:wonder_souls/src/features/home/presentation/widgets/app_navigation_drawer.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/settings_screens.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/create_trip_modal_bottom_sheet.dart';

class HomeBottomBar extends StatefulWidget {
  const HomeBottomBar({super.key});

  static const String routeName = "/HomeBottomBar";

  @override
  State<HomeBottomBar> createState() => _HomeBottomBarState();
}

class _HomeBottomBarState extends State<HomeBottomBar>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
      const ListDestination(),
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
    } else {
      setState(() {});
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

  void _openCreateTripModal() {
    showCreateTripModal(
      context,
      onSelectTab: (tabIndex) {
        _tabController.animateTo(tabIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = sl.isRegistered<AuthLocalDataSource>()
        ? sl<AuthLocalDataSource>().getUser()
        : null;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: AppNavigationDrawer(
        onSelectTab: (tabIndex) {
          _tabController.animateTo(tabIndex);
        },
      ),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 56.h,
        titleSpacing: 0,
        backgroundColor: context.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _tabController.index == 0
            ? null
            : (_isSearching
                ? null
                : Padding(
                    padding: EdgeInsets.only(left: 12.w),
                    child: IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: context.onSurface,
                        size: 24.sp,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  )),
        leadingWidth: _tabController.index == 0 ? 0 : null,
        title: _isSearching
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppSearchBar(
                  hintText: "Search destinations & trips...",
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
            : AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Image.asset(
                        Assets.logo,
                        height: 38.h,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (_, __, ___) => Row(
                          children: [
                            Text(
                              "WanderSouls",
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: context.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final titles = ["", "Explore", "My Trips", "Profile"];
                  return Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: Text(
                      titles[_tabController.index],
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  );
                },
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
                    if (_tabController.index == 0) {
                      // On Home Tab: Notification Bell + Avatar
                      return Padding(
                        padding: EdgeInsets.only(right: 16.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Notification bell with red badge dot
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: const Color(0xFF64748B),
                                    size: 26.sp,
                                  ),
                                ),
                                Positioned(
                                  top: 3.h,
                                  right: 5.w,
                                  child: Container(
                                    width: 8.w,
                                    height: 8.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 10.w),

                            // User Profile Avatar
                            ProfileImageHelper.buildAvatar(
                              context,
                              user: user,
                              radius: 18.w,
                              borderWidth: 1.5,
                              borderColor:
                                  context.primary.withValues(alpha: 0.5),
                              onTap: () {
                                _tabController.animateTo(3); // Go to Profile
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    if (_tabController.index == 1 ||
                        _tabController.index == 2) {
                      return Padding(
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
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
      ),

      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),

      // 5-Item Modern Bottom Navigation Bar with Center FAB
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: context.isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              width: 1.h,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home Tab
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_filled,
                  inactiveIcon: Icons.home_outlined,
                  label: "Home",
                ),

                // 2. Explore Tab
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.explore,
                  inactiveIcon: Icons.explore_outlined,
                  label: "Explore",
                ),

                // 3. Center Create Trip Button
                GestureDetector(
                  onTap: _openCreateTripModal,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.primary,
                          boxShadow: [
                            BoxShadow(
                              color: context.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Create Trip",
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. My Trips Tab
                _buildNavItem(
                  context: context,
                  index: 2,
                  icon: Icons.work_rounded,
                  inactiveIcon: Icons.work_outline_rounded,
                  label: "My Trips",
                ),

                // 5. Profile Tab
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline_rounded,
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;
    final activeColor = context.primary;
    const inactiveColor = Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : inactiveIcon,
              size: 23.sp,
              color: isSelected ? activeColor : inactiveColor,
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
