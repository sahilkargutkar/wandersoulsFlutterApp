import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class ItineraryResultStep extends StatefulWidget {
  const ItineraryResultStep({super.key});

  @override
  State<ItineraryResultStep> createState() => _ItineraryResultStepState();
}

class _ItineraryResultStepState extends State<ItineraryResultStep>
    with TickerProviderStateMixin {
  int _selectedDay = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController(int length) {
    if (_tabController.length != length) {
      _tabController.dispose();
      _tabController = TabController(length: length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _selectedDay = _tabController.index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripWizardCubit, TripWizardState>(
      builder: (context, state) {
        final itinerary = state.generatedItinerary;
        if (itinerary == null) {
          return const Center(child: Text("No itinerary data available"));
        }

        final tripName = itinerary["tripName"] ?? "Your Trip";
        final destination = itinerary["destination"] ?? "";
        final totalDays = itinerary["totalDays"] ?? 0;
        final days = (itinerary["itinerary"] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final estimatedCost = (itinerary["estimatedTotalCost"] ?? 0).toDouble();
        final tips = (itinerary["travelTips"] as List?)?.cast<String>() ?? [];

        if (days.isNotEmpty) {
          _updateTabController(days.length);
        }

        return Column(
          children: [
            // Header
            _buildHeader(context, tripName, destination, totalDays, estimatedCost),

            // Day Tabs
            if (days.isNotEmpty)
              _buildDayTabs(context, days),

            // Activities List
            Expanded(
              child: days.isNotEmpty
                  ? _buildActivitiesList(context, days)
                  : const Center(child: Text("No activities planned")),
            ),

            // Travel Tips Toggle + Save Button
            _buildBottomSection(context, tips, state),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String tripName,
    String destination,
    int totalDays,
    double estimatedCost,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: context.colors.primary, size: 24.sp),
              8.w.horizontalSpace,
              Expanded(
                child: Text(
                  "AI-Generated Itinerary",
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          8.h.verticalSpace,
          Text(
            tripName,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          4.h.verticalSpace,
          Row(
            children: [
              Icon(Icons.location_on, size: 14.sp, color: context.colors.onSurfaceVariant),
              4.w.horizontalSpace,
              Text(
                destination,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              16.w.horizontalSpace,
              Icon(Icons.calendar_today, size: 14.sp, color: context.colors.onSurfaceVariant),
              4.w.horizontalSpace,
              Text(
                "$totalDays days",
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              16.w.horizontalSpace,
              Icon(Icons.account_balance_wallet, size: 14.sp, color: context.colors.onSurfaceVariant),
              4.w.horizontalSpace,
              Text(
                "\$${estimatedCost.toStringAsFixed(0)}",
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(BuildContext context, List<Map<String, dynamic>> days) {
    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: days.length > 4,
        onTap: (index) => setState(() => _selectedDay = index),
        labelColor: Colors.white,
        unselectedLabelColor: context.colors.onSurfaceVariant,
        labelStyle: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: context.text.labelMedium,
        indicator: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.all(2.w),
        tabs: List.generate(days.length, (i) {
          return Tab(text: "Day ${i + 1}");
        }),
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context, List<Map<String, dynamic>> days) {
    if (_selectedDay >= days.length) return const SizedBox.shrink();

    final day = days[_selectedDay];
    final title = day["title"] ?? "Day ${_selectedDay + 1}";
    final date = day["date"] ?? "";
    final activities = (day["activities"] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      children: [
        // Day Title
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    4.h.verticalSpace,
                    Text(
                      date,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "${activities.length} activities",
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        16.h.verticalSpace,

        // Timeline Activities
        ...List.generate(activities.length, (index) {
          final activity = activities[index];
          final isLast = index == activities.length - 1;
          return _buildActivityCard(context, activity, isLast);
        }),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity, bool isLast) {
    final time = activity["time"] ?? "";
    final name = activity["name"] ?? "";
    final description = activity["description"] ?? "";
    final category = activity["category"] ?? "";
    final cost = (activity["estimatedCost"] ?? 0).toDouble();
    final duration = activity["duration"] ?? "";
    final tips = activity["tips"] ?? "";

    final categoryIcon = _getCategoryIcon(category);
    final categoryColor = _getCategoryColor(context, category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 60.w,
            child: Column(
              children: [
                Text(
                  time,
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
                8.h.verticalSpace,
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: context.colors.onSurface.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: context.colors.onSurface.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.softShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Cost Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon, size: 12.sp, color: categoryColor),
                            4.w.horizontalSpace,
                            Text(
                              category,
                              style: context.text.labelSmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (cost > 0)
                        Text(
                          "\$${cost.toStringAsFixed(0)}",
                          style: context.text.labelMedium?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  8.h.verticalSpace,

                  // Activity Name
                  Text(
                    name,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  6.h.verticalSpace,

                  // Description
                  Text(
                    description,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  // Duration
                  if (duration.isNotEmpty) ...[
                    10.h.verticalSpace,
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14.sp, color: context.colors.onSurfaceVariant),
                        4.w.horizontalSpace,
                        Text(
                          duration,
                          style: context.text.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Tips
                  if (tips.isNotEmpty) ...[
                    10.h.verticalSpace,
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 14.sp, color: Colors.amber[700]),
                          6.w.horizontalSpace,
                          Expanded(
                            child: Text(
                              tips,
                              style: context.text.labelSmall?.copyWith(
                                color: Colors.amber[800],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    List<String> tips,
    TripWizardState state,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.softShadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Travel Tips expandable
          if (tips.isNotEmpty)
            ExpansionTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tips_and_updates, size: 18.sp, color: context.colors.primary),
                  8.w.horizontalSpace,
                  Text(
                    "Travel Tips",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ],
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.only(bottom: 12.h),
              children: tips.map((tip) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("•  ", style: TextStyle(color: context.colors.primary)),
                      Expanded(
                        child: Text(
                          tip,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          12.h.verticalSpace,

          // Save Trip Button
          CommonButton(
            title: "Save Trip",
            isLoading: state.status == TripWizardStatus.loading,
            icon: Icons.check_circle_outline,
            onPressed: () {
              context.read<TripWizardCubit>().saveTrip();
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "landmark":
        return Icons.location_city;
      case "food":
        return Icons.restaurant;
      case "adventure":
        return Icons.terrain;
      case "culture":
        return Icons.museum;
      case "shopping":
        return Icons.shopping_bag;
      case "nature":
        return Icons.park;
      case "entertainment":
        return Icons.movie;
      case "transport":
        return Icons.directions_car;
      case "accommodation":
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category.toLowerCase()) {
      case "landmark":
        return const Color(0xFF6366F1);
      case "food":
        return const Color(0xFFF97316);
      case "adventure":
        return const Color(0xFF10B981);
      case "culture":
        return const Color(0xFF8B5CF6);
      case "shopping":
        return const Color(0xFFEC4899);
      case "nature":
        return const Color(0xFF22C55E);
      case "entertainment":
        return const Color(0xFFEF4444);
      case "transport":
        return const Color(0xFF3B82F6);
      case "accommodation":
        return const Color(0xFF14B8A6);
      default:
        return context.colors.primary;
    }
  }
}
