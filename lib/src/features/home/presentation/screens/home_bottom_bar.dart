import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Screens
import 'package:wonder_souls/src/features/home/presentation/screens/home_screen.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/settings_screens.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/saved_trips_screen.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

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

  final List<String> _titles = [
    "Wander Souls",
    'Saved',
    'My Trips',
    'Settings',
  ];
  final List<Widget> _pages = [
    const HomeScreen(),
    const SavedTripsScreen(),
    const MyTripsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _titles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Fixed AppBar, title changes with tab
      appBar: AppBar(
        leadingWidth: 60,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),

            child: Image.asset(
              // placeholder icon for your logo
              Assets.logo,
              width: 50.w,
            ),
          ),
        ),

        title: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Text(
              _titles[_tabController.index],
              style: context.text.titleLarge,
            );
          },
        ),

        actions: [
          // balances leading so title is truly centered
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return (_tabController.index == 1 || _tabController.index == 2)
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 16.w,
                      ),
                      child: Icon(
                        Icons.search,
                        color: context.onSurfaceVariant,
                      ),
                    )
                  : 48.w.width;
            },
          ),
        ],
      ),

      // ✅ Body: TabBarView takes full height
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),

      // ✅ Bottom TabBar
      bottomNavigationBar: Material(
        color: context.surface,
        child: SafeArea(
          child: TabBar(
            dividerColor: Colors.transparent,
            controller: _tabController,
            labelColor: context.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: context.primary,
            tabs: const [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.bookmark_border), text: 'Saved'),
              Tab(icon: Icon(Icons.location_on_outlined), text: 'My Trips'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
