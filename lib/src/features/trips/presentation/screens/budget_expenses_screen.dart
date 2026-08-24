import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';

class BudgetExpensesScreen extends StatefulWidget {
  final TripData trip;

  const BudgetExpensesScreen({super.key, required this.trip});

  static const String routeName = "/BudgetExpensesScreen";

  @override
  State<BudgetExpensesScreen> createState() => _BudgetExpensesScreenState();
}

class _BudgetExpensesScreenState extends State<BudgetExpensesScreen> {
  final ApiService _apiService = sl<ApiService>();
  List<TripActivityModel> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _loading = true);
    try {
      final res = await _apiService.get<dynamic>(
        "/TripActivity/by-trip/${widget.trip.id}",
        fromJson: (d) => d,
      );
      if (res is Success && res.data != null) {
        final rawData = res.data;
        final List<dynamic> dataList;
        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map<String, dynamic> && rawData["data"] is List) {
          dataList = rawData["data"];
        } else {
          dataList = [];
        }

        setState(() {
          _activities = dataList.map((e) => TripActivityModel.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        AppToast.error("Failed to load activities");
      }
    } catch (e) {
      setState(() => _loading = false);
      AppToast.error("Error loading activities: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate actual spent values
    double totalSpent = 0.0;
    double transportSpent = 0.0;
    double accommodationSpent = 0.0;
    double foodSpent = 0.0;
    double activitiesSpent = 0.0;
    double otherSpent = 0.0;

    final costActivities = _activities.where((act) => act.cost > 0).toList();

    for (final act in costActivities) {
      totalSpent += act.cost;
      switch (act.category) {
        case 1: // Food
          foodSpent += act.cost;
          break;
        case 2: // Transport
          transportSpent += act.cost;
          break;
        case 3: // Accommodation
          accommodationSpent += act.cost;
          break;
        case 0: // Landmark
        case 4: // Relaxation
        case 5: // Shopping
          activitiesSpent += act.cost;
          break;
        default:
          otherSpent += act.cost;
          break;
      }
    }

    final currencySymbol = widget.trip.currency == "EUR"
        ? "€"
        : widget.trip.currency == "INR"
            ? "₹"
            : widget.trip.currency == "GBP"
                ? "£"
                : "\$";

    final totalBudget = widget.trip.totalBudget > 0 ? widget.trip.totalBudget : 1.0;
    final totalProgress = (totalSpent / totalBudget).clamp(0.0, 1.0);
    final totalPercentage = (totalSpent / totalBudget * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          "Trip Budget & Expenses",
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchActivities,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchActivities,
              color: context.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20.w),
                children: [
                  // Total Budget Utilization Card
                  _buildTotalBudgetCard(
                    context,
                    currencySymbol,
                    totalSpent,
                    totalBudget,
                    totalProgress,
                    totalPercentage,
                  ),
                  24.h.verticalSpace,

                  // Category breakdown section
                  Text(
                    "Expenses by Category",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Transportation ✈️",
                    spent: transportSpent,
                    budget: widget.trip.transportBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.blueAccent,
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Accommodation 🏨",
                    spent: accommodationSpent,
                    budget: widget.trip.accommodationBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.indigo,
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Food & Dining 🍽️",
                    spent: foodSpent,
                    budget: widget.trip.foodBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.orangeAccent,
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Activities & Sights 🎡",
                    spent: activitiesSpent,
                    budget: widget.trip.activitiesBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.teal,
                  ),
                  if (otherSpent > 0) ...[
                    12.h.verticalSpace,
                    _buildCategoryProgressRow(
                      context,
                      category: "Others 📦",
                      spent: otherSpent,
                      budget: 0.0,
                      currencySymbol: currencySymbol,
                      color: Colors.grey,
                    ),
                  ],

                  28.h.verticalSpace,

                  // List of expense items
                  Text(
                    "Expense Log (${costActivities.length} items)",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  12.h.verticalSpace,

                  if (costActivities.isEmpty)
                    Container(
                      padding: EdgeInsets.all(32.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        "No expenses recorded yet. Activity costs are added dynamically based on your day events.",
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...costActivities.map((act) {
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.only(bottom: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(color: context.borderColor.withAlpha(20)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                          leading: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: context.primary.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCategoryIcon(act.category),
                              color: context.primary,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(
                            act.name,
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _getCategoryName(act.category),
                            style: context.text.bodySmall?.copyWith(
                              color: context.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            "$currencySymbol${act.cost.toStringAsFixed(2)}",
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      );
                    }),
                  40.h.verticalSpace,
                ],
              ),
            ),
    );
  }

  Widget _buildTotalBudgetCard(
    BuildContext context,
    String currencySymbol,
    double spent,
    double budget,
    double progress,
    String percentage,
  ) {
    final isOverBudget = spent > budget;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.mutedBackground,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.borderColor.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Spent",
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isOverBudget ? Colors.redAccent : context.primary).withAlpha(15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  isOverBudget ? "Over Budget" : "$percentage% used",
                  style: TextStyle(
                    color: isOverBudget ? Colors.redAccent : context.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          8.h.verticalSpace,
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                "$currencySymbol${spent.toStringAsFixed(2)}",
                style: context.text.titleLarge?.copyWith(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: isOverBudget ? Colors.redAccent : context.primary,
                ),
              ),
              8.w.horizontalSpace,
              Text(
                "/ $currencySymbol${budget.toStringAsFixed(0)}",
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          16.h.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10.h,
              backgroundColor: context.borderColor.withAlpha(30),
              color: isOverBudget ? Colors.redAccent : context.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressRow(
    BuildContext context, {
    required String category,
    required double spent,
    required double budget,
    required String currencySymbol,
    required Color color,
  }) {
    final finalBudget = budget > 0 ? budget : 1.0;
    final progress = (spent / finalBudget).clamp(0.0, 1.0);
    final percent = budget > 0 ? "${(spent / budget * 100).toStringAsFixed(0)}%" : "No limit";

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "$currencySymbol${spent.toStringAsFixed(0)} / ${budget > 0 ? "$currencySymbol${budget.toStringAsFixed(0)}" : "∞"}",
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: spent > budget && budget > 0 ? Colors.red : context.onSurface,
                ),
              ),
            ],
          ),
          10.h.verticalSpace,
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.h,
                    backgroundColor: context.borderColor.withAlpha(20),
                    color: color,
                  ),
                ),
              ),
              12.w.horizontalSpace,
              Text(
                percent,
                style: context.text.labelSmall?.copyWith(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int category) {
    switch (category) {
      case 0:
        return Icons.location_on_outlined;
      case 1:
        return Icons.restaurant;
      case 2:
        return Icons.flight_takeoff_rounded;
      case 3:
        return Icons.hotel;
      case 4:
        return Icons.spa;
      case 5:
        return Icons.shopping_bag;
      default:
        return Icons.attach_money;
    }
  }

  String _getCategoryName(int category) {
    switch (category) {
      case 1:
        return "Food & Dining";
      case 2:
        return "Transport";
      case 3:
        return "Accommodation";
      case 4:
        return "Relaxation";
      case 5:
        return "Shopping";
      case 0:
        return "Tourist Attraction";
      default:
        return "Others";
    }
  }
}
