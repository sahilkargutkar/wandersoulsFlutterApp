import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/api_result.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/accommodation_model.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';
import 'package:wonder_souls/src/features/trips/model/trip_expense_model.dart';
import 'package:wonder_souls/src/features/trips/model/trip_transport_model.dart';

class BudgetExpensesScreen extends StatefulWidget {
  final TripData trip;

  const BudgetExpensesScreen({super.key, required this.trip});

  static const String routeName = "/BudgetExpensesScreen";

  @override
  State<BudgetExpensesScreen> createState() => _BudgetExpensesScreenState();
}

class _ExpenseItem {
  final String id;
  final String title;
  final String subtitle;
  final double cost;
  final int category; // 0: Activities, 1: Food, 2: Transport, 3: Accommodation, 6: Others
  final IconData icon;
  final DateTime? date;
  final bool isCustomExpense;
  final TripExpenseModel? rawExpense;

  _ExpenseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.category,
    required this.icon,
    this.date,
    this.isCustomExpense = false,
    this.rawExpense,
  });
}

class _BudgetExpensesScreenState extends State<BudgetExpensesScreen> {
  final ApiService _apiService = sl<ApiService>();
  late TripData _currentTrip;
  List<TripExpenseModel> _tripExpenses = [];
  List<TripActivityModel> _activities = [];
  List<AccommodationModel> _accommodations = [];
  List<TripTransportModel> _transports = [];
  bool _loading = true;
  int _selectedFilter = -1; // -1: All, 2: Transport, 3: Accommodation, 1: Food, 0: Activities, 6: Others

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchTripDetails(),
      _fetchTripBudgetExpenses(),
      _fetchActivities(),
      _fetchAccommodations(),
      _fetchTransports(),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _extractList(dynamic rawData, List<String> possibleKeys) {
    if (rawData == null) return [];
    if (rawData is List) return rawData;
    if (rawData is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        if (rawData.containsKey(key) && rawData[key] is List) {
          return rawData[key] as List;
        }
      }
      if (rawData["data"] is Map<String, dynamic>) {
        final innerMap = rawData["data"] as Map<String, dynamic>;
        for (final key in possibleKeys) {
          if (innerMap.containsKey(key) && innerMap[key] is List) {
            return innerMap[key] as List;
          }
        }
      }
      if (rawData["expenses"] is List) return rawData["expenses"] as List;
      if (rawData["data"] is List) return rawData["data"] as List;
    }
    return [];
  }

  Future<void> _fetchTripDetails() async {
    try {
      final res = await _apiService.get<dynamic>(
        "/Trips/${widget.trip.id}",
        fromJson: (d) => d,
      );
      if (res is Success && res.data != null) {
        final raw = res.data;
        final map = raw is Map<String, dynamic>
            ? (raw["data"] is Map<String, dynamic>
                ? raw["data"] as Map<String, dynamic>
                : raw)
            : null;
        if (map != null) {
          _currentTrip = TripData.fromJson(map);
        }
      }
    } catch (e) {
      debugPrint("Error fetching trip details: $e");
    }
  }

  Future<void> _fetchTripBudgetExpenses() async {
    try {
      ApiResult<dynamic> res = await _apiService.get<dynamic>(
        "${ApiConstants.tripBudgetGetAllExpenses}?tripId=${widget.trip.id}",
        fromJson: (d) => d,
      );
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "${ApiConstants.tripBudgetGetAllExpenses}?TripId=${widget.trip.id}",
          fromJson: (d) => d,
        );
      }
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          ApiConstants.tripBudgetGetAllExpenses,
          fromJson: (d) => d,
        );
      }

      if (res is Success && res.data != null) {
        final list = _extractList(
          res.data,
          ["data", "items", "expenses", "Expenses", "value", "results"],
        );
        final targetTripId = widget.trip.id.trim().toLowerCase();
        final List<TripExpenseModel> items = [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              final model = TripExpenseModel.fromJson(item);
              final actTripId = model.tripId.trim().toLowerCase();
              if (actTripId.isEmpty || actTripId == targetTripId) {
                items.add(model);
              }
            } catch (e) {
              debugPrint("Error parsing trip budget expense: $e");
            }
          }
        }
        _tripExpenses = items;
      }
    } catch (e) {
      debugPrint("Error fetching trip budget expenses: $e");
    }
  }

  Future<void> _fetchActivities() async {
    try {
      ApiResult<dynamic> res = await _apiService.get<dynamic>(
        "/TripActivity?TripId=${widget.trip.id}&tripId=${widget.trip.id}",
        fromJson: (d) => d,
      );
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/TripActivity?TripId=${widget.trip.id}",
          fromJson: (d) => d,
        );
      }
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/TripActivity?tripId=${widget.trip.id}",
          fromJson: (d) => d,
        );
      }
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/TripActivity",
          fromJson: (d) => d,
        );
      }

      if (res is Success && res.data != null) {
        final list = _extractList(
          res.data,
          ["data", "items", "activities", "value", "results"],
        );
        final targetTripId = widget.trip.id.trim().toLowerCase();
        final List<TripActivityModel> items = [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              final model = TripActivityModel.fromJson(item);
              final actTripId = model.tripId.trim().toLowerCase();
              if (actTripId.isEmpty || actTripId == targetTripId) {
                items.add(model);
              }
            } catch (e) {
              debugPrint("Error parsing activity: $e");
            }
          }
        }
        _activities = items;
      }
    } catch (e) {
      debugPrint("Error fetching activities: $e");
    }
  }

  Future<void> _fetchAccommodations() async {
    try {
      ApiResult<dynamic> res = await _apiService.get<dynamic>(
        "/Accomodation?TripId=${widget.trip.id}&tripId=${widget.trip.id}",
        fromJson: (d) => d,
      );
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/Accomodation?tripId=${widget.trip.id}",
          fromJson: (d) => d,
        );
      }
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/Accomodation",
          fromJson: (d) => d,
        );
      }

      if (res is Success && res.data != null) {
        final list = _extractList(
          res.data,
          ["data", "items", "accommodations", "Accommodations", "value", "results"],
        );
        final targetTripId = widget.trip.id.trim().toLowerCase();
        final List<AccommodationModel> items = [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              final acc = AccommodationModel.fromJson(item);
              final accTripId = (acc.tripId ?? "").trim().toLowerCase();
              if (accTripId.isEmpty || accTripId == targetTripId) {
                items.add(acc);
              }
            } catch (e) {
              debugPrint("Error parsing accommodation: $e");
            }
          }
        }
        _accommodations = items;
      }
    } catch (e) {
      debugPrint("Error fetching accommodations: $e");
    }
  }

  Future<void> _fetchTransports() async {
    try {
      ApiResult<dynamic> res = await _apiService.get<dynamic>(
        "/TripTransports?TripId=${widget.trip.id}&tripId=${widget.trip.id}",
        fromJson: (d) => d,
      );
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/TripTransports?tripId=${widget.trip.id}",
          fromJson: (d) => d,
        );
      }
      if (res is Failure) {
        res = await _apiService.get<dynamic>(
          "/TripTransports",
          fromJson: (d) => d,
        );
      }

      if (res is Success && res.data != null) {
        final list = _extractList(
          res.data,
          ["data", "items", "transports", "Transports", "tripTransports", "value", "results"],
        );
        final targetTripId = widget.trip.id.trim().toLowerCase();
        final List<TripTransportModel> items = [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              final trans = TripTransportModel.fromJson(item);
              final transTripId = (trans.tripId ?? "").trim().toLowerCase();
              if (transTripId.isEmpty || transTripId == targetTripId) {
                items.add(trans);
              }
            } catch (e) {
              debugPrint("Error parsing transport: $e");
            }
          }
        }
        _transports = items;
      }
    } catch (e) {
      debugPrint("Error fetching transports: $e");
    }
  }

  int _mapCategoryStringToEnum(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains("transport") || lower.contains("flight") || lower.contains("train")) return 2;
    if (lower.contains("accommodat") || lower.contains("hotel") || lower.contains("stay")) return 3;
    if (lower.contains("food") || lower.contains("dining") || lower.contains("restaurant") || lower.contains("meal")) return 1;
    if (lower.contains("activit") || lower.contains("sight") || lower.contains("tour") || lower.contains("landmark")) return 0;
    return 6;
  }

  String _mapEnumToCategoryString(int cat) {
    switch (cat) {
      case 1:
        return "Food";
      case 2:
        return "Transportation";
      case 3:
        return "Accommodation";
      case 0:
        return "Activities";
      default:
        return "Others";
    }
  }

  Future<void> _showAddOrEditExpenseDialog([TripExpenseModel? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? "");
    final amountController = TextEditingController(
      text: existing != null && existing.amount > 0 ? existing.amount.toStringAsFixed(2) : "",
    );
    final notesController = TextEditingController(text: existing?.notes ?? "");
    int selectedCatEnum = existing != null
        ? _mapCategoryStringToEnum(existing.category)
        : 1; // Default food

    final isEdit = existing != null && existing.id.isNotEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.h,
                20.w,
                MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? "Edit Expense" : "Add New Expense",
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    16.h.verticalSpace,
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Expense Title / Description",
                        hintText: "e.g. Lunch at Cafe, Train Ticket",
                        filled: true,
                        fillColor: context.mutedBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    12.h.verticalSpace,
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Amount (${_currentTrip.currency})",
                        hintText: "0.00",
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        filled: true,
                        fillColor: context.mutedBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    16.h.verticalSpace,
                    Text(
                      "Category",
                      style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    8.h.verticalSpace,
                    Wrap(
                      spacing: 8.w,
                      children: [
                        _buildCategoryChoiceChip("🍽️ Food", 1, selectedCatEnum, (c) => setSheetState(() => selectedCatEnum = c)),
                        _buildCategoryChoiceChip("✈️ Transport", 2, selectedCatEnum, (c) => setSheetState(() => selectedCatEnum = c)),
                        _buildCategoryChoiceChip("🏨 Stay", 3, selectedCatEnum, (c) => setSheetState(() => selectedCatEnum = c)),
                        _buildCategoryChoiceChip("🎡 Activities", 0, selectedCatEnum, (c) => setSheetState(() => selectedCatEnum = c)),
                        _buildCategoryChoiceChip("📦 Others", 6, selectedCatEnum, (c) => setSheetState(() => selectedCatEnum = c)),
                      ],
                    ),
                    12.h.verticalSpace,
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Notes (Optional)",
                        hintText: "Additional notes...",
                        filled: true,
                        fillColor: context.mutedBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    20.h.verticalSpace,
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (title.isEmpty) {
                            AppToast.error("Please enter a title");
                            return;
                          }
                          if (amount <= 0) {
                            AppToast.error("Please enter a valid positive amount");
                            return;
                          }

                          Navigator.pop(ctx);
                          final categoryStr = _mapEnumToCategoryString(selectedCatEnum);

                          final payload = {
                            if (isEdit) "id": existing.id,
                            if (isEdit) "expenseId": existing.id,
                            "tripId": widget.trip.id,
                            "TripId": widget.trip.id,
                            "title": title,
                            "name": title,
                            "amount": amount,
                            "cost": amount,
                            "category": categoryStr,
                            "currency": _currentTrip.currency,
                            "notes": notesController.text.trim(),
                            "date": DateTime.now().toUtc().toIso8601String(),
                          };

                          AppToast.success(isEdit ? "Updating expense..." : "Adding expense...");

                          try {
                            final res = isEdit
                                ? await _apiService.put<dynamic>(
                                    ApiConstants.tripBudgetExpenseById(existing.id),
                                    data: payload,
                                    fromJson: (d) => d,
                                  )
                                : await _apiService.post<dynamic>(
                                    ApiConstants.tripBudgetExpenses,
                                    data: payload,
                                    fromJson: (d) => d,
                                  );

                            if (res is Success) {
                              AppToast.success(isEdit ? "Expense updated!" : "Expense added successfully!");
                              _fetchData();
                            } else if (res is Failure) {
                              AppToast.error(res.message);
                            }
                          } catch (e) {
                            AppToast.error("Error saving expense: $e");
                          }
                        },
                        child: Text(
                          isEdit ? "Update Expense" : "Save Expense",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChoiceChip(
    String label,
    int value,
    int selectedValue,
    ValueChanged<int> onSelected,
  ) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: context.primary,
      backgroundColor: context.mutedBackground,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.onSurface,
        fontSize: 12.sp,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      showCheckmark: false,
    );
  }

  Future<void> _deleteCustomExpense(String expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to remove this expense?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    AppToast.success("Deleting expense...");
    try {
      final res = await _apiService.delete<dynamic>(
        ApiConstants.tripBudgetExpenseById(expenseId),
        fromJson: (d) => d,
      );
      if (res is Success) {
        AppToast.success("Expense deleted successfully!");
        _fetchData();
      } else if (res is Failure) {
        AppToast.error(res.message);
      }
    } catch (e) {
      AppToast.error("Error deleting expense: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate spent numbers from all sources
    double totalSpent = 0.0;
    double transportSpent = 0.0;
    double accommodationSpent = 0.0;
    double foodSpent = 0.0;
    double activitiesSpent = 0.0;
    double otherSpent = 0.0;

    final List<_ExpenseItem> allExpenses = [];

    // Custom TripBudget Expenses
    for (final exp in _tripExpenses) {
      if (exp.amount > 0) {
        totalSpent += exp.amount;
        final catEnum = _mapCategoryStringToEnum(exp.category);
        switch (catEnum) {
          case 1:
            foodSpent += exp.amount;
            break;
          case 2:
            transportSpent += exp.amount;
            break;
          case 3:
            accommodationSpent += exp.amount;
            break;
          case 0:
            activitiesSpent += exp.amount;
            break;
          default:
            otherSpent += exp.amount;
            break;
        }

        allExpenses.add(
          _ExpenseItem(
            id: exp.id,
            title: exp.title,
            subtitle: exp.notes != null && exp.notes!.isNotEmpty
                ? "${exp.category} · ${exp.notes}"
                : exp.category,
            cost: exp.amount,
            category: catEnum,
            icon: _getCategoryIcon(catEnum),
            date: exp.date,
            isCustomExpense: true,
            rawExpense: exp,
          ),
        );
      }
    }

    // Accommodations
    for (final acc in _accommodations) {
      if (acc.cost > 0) {
        accommodationSpent += acc.cost;
        totalSpent += acc.cost;
        allExpenses.add(
          _ExpenseItem(
            id: acc.id ?? acc.name,
            title: acc.name,
            subtitle: acc.address ?? (acc.type ?? "Accommodation Stay"),
            cost: acc.cost,
            category: 3,
            icon: Icons.hotel,
            date: acc.checkInDate,
          ),
        );
      }
    }

    // Transports
    for (final trans in _transports) {
      if (trans.cost > 0) {
        transportSpent += trans.cost;
        totalSpent += trans.cost;
        final route = [
          trans.departureLocation,
          trans.arrivalLocation,
        ].where((e) => e != null && e.isNotEmpty).join(" ➔ ");
        allExpenses.add(
          _ExpenseItem(
            id: trans.id ?? trans.type,
            title: "${trans.type}${trans.provider != null ? ' (${trans.provider})' : ''}",
            subtitle: route.isNotEmpty ? route : "Transportation",
            cost: trans.cost,
            category: 2,
            icon: _getTransportIcon(trans.type),
            date: trans.departureDatetime,
          ),
        );
      }
    }

    // Activities
    for (final act in _activities) {
      if (act.cost > 0) {
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
          case 6: // Activity
            activitiesSpent += act.cost;
            break;
          default:
            otherSpent += act.cost;
            break;
        }

        allExpenses.add(
          _ExpenseItem(
            id: act.id,
            title: act.name,
            subtitle: _getCategoryName(act.category),
            cost: act.cost,
            category: act.category,
            icon: _getCategoryIcon(act.category),
            date: act.startDatetime,
          ),
        );
      }
    }

    // Sort expenses by date descending
    allExpenses.sort((a, b) {
      if (a.date != null && b.date != null) {
        return b.date!.compareTo(a.date!);
      }
      return 0;
    });

    final filteredExpenses = _selectedFilter == -1
        ? allExpenses
        : allExpenses.where((e) {
            if (_selectedFilter == 0) {
              return e.category == 0 || e.category == 4 || e.category == 5 || e.category == 6;
            }
            return e.category == _selectedFilter;
          }).toList();

    final currencySymbol = _currentTrip.currency == "EUR"
        ? "€"
        : _currentTrip.currency == "INR"
            ? "₹"
            : _currentTrip.currency == "GBP"
                ? "£"
                : "\$";

    final totalBudget = _currentTrip.totalBudget > 0 ? _currentTrip.totalBudget : 1.0;
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
            icon: const Icon(Icons.add_rounded),
            tooltip: "Add Expense",
            onPressed: () => _showAddOrEditExpenseDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
            onPressed: () {
              AppToast.success("Refreshing budget data...");
              _fetchData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Expense", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddOrEditExpenseDialog(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: context.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 96.h),
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
                    budget: _currentTrip.transportBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.blueAccent,
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Accommodation 🏨",
                    spent: accommodationSpent,
                    budget: _currentTrip.accommodationBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.indigo,
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Food & Dining 🍽️",
                    spent: foodSpent,
                    budget: _currentTrip.foodBudget,
                    currencySymbol: currencySymbol,
                    color: Colors.orangeAccent,
                  ),
                  12.h.verticalSpace,

                  _buildCategoryProgressRow(
                    context,
                    category: "Activities & Sights 🎡",
                    spent: activitiesSpent,
                    budget: _currentTrip.activitiesBudget,
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

                  // Expense Log Header with count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Expense Log (${allExpenses.length})",
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total: $currencySymbol${totalSpent.toStringAsFixed(2)}",
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.primary,
                        ),
                      ),
                    ],
                  ),
                  12.h.verticalSpace,

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", -1),
                        8.w.horizontalSpace,
                        _buildFilterChip("Transports", 2),
                        8.w.horizontalSpace,
                        _buildFilterChip("Stays", 3),
                        8.w.horizontalSpace,
                        _buildFilterChip("Food", 1),
                        8.w.horizontalSpace,
                        _buildFilterChip("Activities", 0),
                        8.w.horizontalSpace,
                        _buildFilterChip("Others", 6),
                      ],
                    ),
                  ),
                  16.h.verticalSpace,

                  if (filteredExpenses.isEmpty)
                    Container(
                      padding: EdgeInsets.all(32.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40.sp,
                            color: context.onSurfaceVariant.withAlpha(120),
                          ),
                          12.h.verticalSpace,
                          Text(
                            "No expenses recorded for this category yet.",
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium?.copyWith(
                              color: context.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredExpenses.map((item) {
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.only(bottom: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: context.borderColor.withAlpha(20),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item.category).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: _getCategoryColor(item.category),
                              size: 20.sp,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: context.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$currencySymbol${item.cost.toStringAsFixed(2)}",
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              if (item.isCustomExpense && item.rawExpense != null) ...[
                                4.w.horizontalSpace,
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    size: 18.sp,
                                    color: context.onSurfaceVariant,
                                  ),
                                  onSelected: (val) {
                                    if (val == "edit") {
                                      _showAddOrEditExpenseDialog(item.rawExpense);
                                    } else if (val == "delete") {
                                      _deleteCustomExpense(item.rawExpense!.id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: "edit",
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text("Edit"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: "delete",
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                          SizedBox(width: 8),
                                          Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = filterValue);
      },
      selectedColor: context.primary,
      backgroundColor: context.mutedBackground,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.sp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      showCheckmark: false,
    );
  }

  Color _getCategoryColor(int category) {
    switch (category) {
      case 1:
        return Colors.orangeAccent;
      case 2:
        return Colors.blueAccent;
      case 3:
        return Colors.indigo;
      case 4:
        return Colors.teal;
      case 5:
        return Colors.purpleAccent;
      case 0:
      default:
        return context.primary;
    }
  }

  IconData _getTransportIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains("flight") || lower.contains("plane")) {
      return Icons.flight_takeoff_rounded;
    }
    if (lower.contains("train") || lower.contains("rail")) {
      return Icons.train_outlined;
    }
    if (lower.contains("bus")) {
      return Icons.directions_bus_outlined;
    }
    if (lower.contains("ferry") || lower.contains("boat") || lower.contains("ship")) {
      return Icons.directions_boat_outlined;
    }
    return Icons.directions_car_outlined;
  }

  Widget _buildTotalBudgetCard(
    BuildContext context,
    String currencySymbol,
    double spent,
    double budget,
    double progress,
    String percentage,
  ) {
    final isOverBudget = spent > budget && budget > 1.0;
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
    final percent = budget > 0
        ? "${(spent / budget * 100).toStringAsFixed(0)}%"
        : "No limit";

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
        return "General Activity";
    }
  }
}
