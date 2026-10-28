import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/circular_icon.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/mongo_id_helper.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/add_event_screen.dart';

class _DragPayload {
  final int fromDay;
  final int fromIndex;
  final TripActivityModel activity;

  const _DragPayload({
    required this.fromDay,
    required this.fromIndex,
    required this.activity,
  });
}

class EditItineraryScreen extends StatefulWidget {
  final TripData trip;
  final List<TripActivityModel> initialActivities;
  final int initialDayIndex;

  const EditItineraryScreen({
    super.key,
    required this.trip,
    required this.initialActivities,
    this.initialDayIndex = 0,
  });

  @override
  State<EditItineraryScreen> createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen>
    with SingleTickerProviderStateMixin {
  // Map of day index (0-based) to list of activities
  late Map<int, List<TripActivityModel>> _dayActivities;
  final List<String> _deletedActivityIds = [];
  final List<TripActivityModel> _addedActivities = [];
  late int _selectedDayIndex;
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};
  Timer? _autoScrollTimer;
  double _autoScrollStep = 0.0;
  Timer? _tabHoverTimer;
  int? _hoveredDayTab;
  _DragPayload? _activeDraggingPayload;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  Animation<double> get pulseAnimation {
    if (_pulseAnimation == null) {
      _initPulseAnimation();
    }
    return _pulseAnimation!;
  }

  void _initPulseAnimation() {
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation ??= Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  int get _totalDays {
    if (widget.trip.startDate == null || widget.trip.endDate == null) return 3;
    final diff = widget.trip.endDate!.difference(widget.trip.startDate!).inDays;
    return diff >= 0 ? diff + 1 : 3;
  }

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _selectedDayIndex = widget.initialDayIndex.clamp(0, _totalDays - 1);
    _initializeDayActivities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDayIndex > 0 && widget.initialDayIndex < _totalDays) {
        _scrollToDay(widget.initialDayIndex);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    _initPulseAnimation();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _tabHoverTimer?.cancel();
    _scrollController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  void _initializeDayActivities() {
    _dayActivities = {};
    for (int i = 0; i < _totalDays; i++) {
      _dayActivities[i] = [];
      _dayKeys[i] = GlobalKey();
    }

    for (var act in widget.initialActivities) {
      final dayNum = int.tryParse(act.dayId) ?? 1;
      final dayIndex = (dayNum - 1).clamp(0, _totalDays - 1);
      _dayActivities[dayIndex]?.add(act);
    }

    for (int i = 0; i < _totalDays; i++) {
      _dayActivities[i]?.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
    }
  }

  void _scrollToDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _totalDays) return;
    setState(() => _selectedDayIndex = dayIndex);
    final keyContext = _dayKeys[dayIndex]?.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        alignment: 0.02,
      );
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final dy = details.globalPosition.dy;

    const topThreshold = 240.0;
    final bottomThreshold = screenHeight - 220.0;

    if (dy < topThreshold) {
      final intensity = ((topThreshold - dy) / 120.0).clamp(0.2, 2.5);
      _startAutoScroll(-18.0 * intensity);
    } else if (dy > bottomThreshold) {
      final intensity = ((dy - bottomThreshold) / 120.0).clamp(0.2, 2.5);
      _startAutoScroll(18.0 * intensity);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(double step) {
    _autoScrollStep = step;
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) {
      return;
    }
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final currentOffset = _scrollController.offset;
      final targetOffset = (currentOffset + _autoScrollStep).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (targetOffset != currentOffset) {
        _scrollController.jumpTo(targetOffset);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollStep = 0.0;
  }

  void _onDropActivity({
    required int fromDay,
    required int fromIndex,
    required int toDay,
    required int toIndex,
  }) {
    if (fromDay == toDay && fromIndex == toIndex) return;

    setState(() {
      final fromList = _dayActivities[fromDay];
      final toList = _dayActivities[toDay] ??= [];

      if (fromList == null || fromIndex < 0 || fromIndex >= fromList.length) {
        return;
      }

      final item = fromList.removeAt(fromIndex);

      int insertIndex = toIndex;
      if (fromDay == toDay) {
        if (toIndex > fromIndex) {
          insertIndex = toIndex - 1;
        }
      }

      insertIndex = insertIndex.clamp(0, toList.length);

      if (fromDay != toDay) {
        final updatedItem = item.copyWith(dayId: "${toDay + 1}");
        toList.insert(insertIndex, updatedItem);
        AppToast.success("Moved \"${item.name}\" to Day ${toDay + 1}");
      } else {
        toList.insert(insertIndex, item);
      }
      _activeDraggingPayload = null;
    });
  }

  void _moveActivityToDay(int fromDay, int itemIndex, int toDay) {
    if (fromDay == toDay) return;
    setState(() {
      final item = _dayActivities[fromDay]!.removeAt(itemIndex);
      final updatedItem = item.copyWith(dayId: "${toDay + 1}");
      _dayActivities[toDay] ??= [];
      _dayActivities[toDay]!.add(updatedItem);
    });
    AppToast.success("Moved to Day ${toDay + 1}");
  }

  String _formatDayTitle(int dayIndex) {
    final start = widget.trip.startDate ?? DateTime.now();
    final date = start.add(Duration(days: dayIndex));
    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final daySuffix = _getDaySuffix(date.day);
    return "Day ${dayIndex + 1}: ${monthNames[date.month - 1]} ${date.day}$daySuffix";
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  String _getCategoryName(int categoryCode) {
    switch (categoryCode) {
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
        return "Activity";
    }
  }

  String _getImageUrl(TripActivityModel act) {
    return act.displayImageUrl;
  }

  void _confirmDeleteEvent(
    BuildContext context,
    int dayIndex,
    int activityIndex,
  ) {
    final activity = _dayActivities[dayIndex]![activityIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Delete this Event?",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontSize: 18.sp,
                ),
              ),
              16.h.verticalSpace,
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(activity),
                        width: 50.w,
                        height: 50.h,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 50.w,
                          height: 50.h,
                          color: context.shimmerBase,
                          child: Icon(
                            Icons.image,
                            size: 24.sp,
                            color: context.primary,
                          ),
                        ),
                      ),
                    ),
                    12.w.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          4.h.verticalSpace,
                          Text(
                            _getCategoryName(activity.category),
                            style: context.text.bodySmall?.copyWith(
                              color: context.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              24.h.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: context.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  12.w.horizontalSpace,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          final removed = _dayActivities[dayIndex]!.removeAt(
                            activityIndex,
                          );
                          if (removed.id.isNotEmpty) {
                            _deletedActivityIds.add(removed.id);
                          }
                          _addedActivities.remove(removed);
                        });
                        AppToast.success("Event deleted");
                      },
                      child: const Text(
                        "Yes, Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              12.h.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  Future<void> _addEventForDay(int dayIndex) async {
    final dayTitle = _formatDayTitle(dayIndex);
    final result = await Navigator.push<List<PlaceModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          dayTitle: dayTitle,
          destination: widget.trip.mainDestination,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final dateStr = (widget.trip.startDate ?? DateTime.now())
          .add(Duration(days: dayIndex))
          .toIso8601String()
          .split('T')
          .first;

      final startDatetime = DateTime.parse("${dateStr}T09:00:00Z");
      final endDatetime = DateTime.parse("${dateStr}T10:00:00Z");

      setState(() {
        for (var place in result) {
          final newAct = TripActivityModel(
            id: "", // Will be assigned by API or dynamic ID
            tripId: widget.trip.id,
            placeId: place.placeId.isNotEmpty
                ? place.placeId
                : "place_${DateTime.now().millisecondsSinceEpoch}",
            dayId: "${dayIndex + 1}",
            name: place.name,
            startDatetime: startDatetime,
            endDatetime: endDatetime,
            currency: "USD",
            category: _getCategoryEnum(place.types),
            cost: 0.0,
            tips: place.description,
            imageUrl: place.googleMapsUrl,
          );
          _dayActivities[dayIndex]!.add(newAct);
          _addedActivities.add(newAct);
        }
      });
      AppToast.success("Added ${result.length} event(s)");
    }
  }

  int _getCategoryEnum(List<String> types) {
    if (types.contains("restaurant") ||
        types.contains("food") ||
        types.contains("cafe") ||
        types.contains("bar")) {
      return 1; // Food
    }
    if (types.contains("transit_station") ||
        types.contains("airport") ||
        types.contains("bus_station")) {
      return 2; // Transport
    }
    if (types.contains("lodging") || types.contains("hotel")) {
      return 3; // Accommodation
    }
    if (types.contains("spa") || types.contains("beauty_salon")) {
      return 4; // Relaxation
    }
    if (types.contains("shopping_mall") || types.contains("store")) {
      return 5; // Shopping
    }
    return 0; // Sightseeing
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final apiService = sl<ApiService>();

    try {
      // 1. Delete removed activities from API
      for (var id in _deletedActivityIds) {
        if (id.isNotEmpty) {
          var res = await apiService.delete<dynamic>(
            "/TripActivity/$id",
            fromJson: (data) => data,
          );
          if (res is Failure) {
            res = await apiService.delete<dynamic>(
              "/TripActivity?id=$id",
              fromJson: (data) => data,
            );
          }
          if (res is Failure) {
            res = await apiService.delete<dynamic>(
              "/TripActivity?activityId=$id",
              fromJson: (data) => data,
            );
          }
        }
      }

      // 2. Process all activities in current day lists to check if they need update or insert
      for (int dayIndex = 0; dayIndex < _totalDays; dayIndex++) {
        final activities = _dayActivities[dayIndex] ?? [];
        final start = widget.trip.startDate ?? DateTime.now();
        final date = start.add(Duration(days: dayIndex));
        final dateStr = date.toIso8601String().split('T').first;

        for (int i = 0; i < activities.length; i++) {
          final act = activities[i];
          final startHour = 9 + i;
          final startDatetime = DateTime.parse(
            "${dateStr}T${startHour.toString().padLeft(2, '0')}:00:00Z",
          );
          final endDatetime = startDatetime.add(const Duration(hours: 1));

          final newDayId = "${dayIndex + 1}";

          if (act.id.isEmpty) {
            // New activity, need to POST
            final payload = {
              "tripId": act.tripId,
              "placeId": convertToMongoObjectId(act.placeId),
              "dayId": newDayId,
              "name": act.name,
              "bookingReference": "",
              "startDatetime": startDatetime.toUtc().toIso8601String(),
              "endDatetime": endDatetime.toUtc().toIso8601String(),
              "currency": act.currency ?? "USD",
              "bookingUrl": "",
              "confirmationDocumentUrl": "",
              "activityDetailsDto": {
                "categoryDto": act.category,
                "participants": [],
                "meetingPoint": "",
                "duration": 60,
                "difficulty": "Easy",
                "ageRestriction": "None",
                "cost": act.cost,
                "tips": act.tips ?? "",
                "imageUrl": act.displayImageUrl,
              },
              "notes": act.tips ?? "",
            };

            final res = await apiService.post<dynamic>(
              "/TripActivity",
              data: payload,
              fromJson: (data) => data,
            );
            if (res is Failure) {
              throw Exception(res.message);
            }
          } else {
            // Existing activity, check if it needs update (reordered or day changed)
            final originalDayId = act.dayId;
            final originalStart = act.startDatetime;
            final originalEnd = act.endDatetime;

            if (originalDayId != newDayId ||
                originalStart.toUtc().toIso8601String() !=
                    startDatetime.toUtc().toIso8601String() ||
                originalEnd.toUtc().toIso8601String() !=
                    endDatetime.toUtc().toIso8601String()) {
              final payload = {
                "id": act.id,
                "tripId": act.tripId,
                "placeId": convertToMongoObjectId(act.placeId),
                "dayId": newDayId,
                "name": act.name,
                "bookingReference": act.bookingReference ?? "",
                "startDatetime": startDatetime.toUtc().toIso8601String(),
                "endDatetime": endDatetime.toUtc().toIso8601String(),
                "currency": act.currency ?? "USD",
                "bookingUrl": act.bookingUrl ?? "",
                "confirmationDocumentUrl": act.confirmationDocumentUrl ?? "",
                "activityDetailsDto": {
                  "categoryDto": act.category,
                  "participants": [],
                  "meetingPoint": "",
                  "duration": 60,
                  "difficulty": "Easy",
                  "ageRestriction": "None",
                  "cost": act.cost,
                  "tips": act.tips ?? "",
                  "imageUrl": act.displayImageUrl,
                },
                "notes": act.notes ?? act.tips ?? "",
              };

              final res = await apiService.put<dynamic>(
                "/TripActivity/${act.id}",
                data: payload,
                fromJson: (data) => data,
              );
              if (res is Failure) {
                throw Exception(res.message);
              }
            }
          }
        }
      }

      AppToast.success("Itinerary updated successfully!");
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppToast.error("Error saving itinerary: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: CircularIcon(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: context.onSurface,
            ),
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Edit Itinerary",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Horizontal Day Selector when trip has multiple days
          if (_totalDays > 1)
            Container(
              height: 44.h,
              margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                itemCount: _totalDays,
                separatorBuilder: (context, index) => 8.w.horizontalSpace,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDayIndex;
                  final count = (_dayActivities[index] ?? []).length;
                  final isDragging = _activeDraggingPayload != null;

                  return DragTarget<_DragPayload>(
                    hitTestBehavior: HitTestBehavior.translucent,
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) {
                      _stopAutoScroll();
                      _tabHoverTimer?.cancel();
                      final fromDay = details.data.fromDay;
                      final fromIndex = details.data.fromIndex;
                      final toDay = index;
                      final toIndex = (_dayActivities[toDay] ?? []).length;
                      _onDropActivity(
                        fromDay: fromDay,
                        fromIndex: fromIndex,
                        toDay: toDay,
                        toIndex: toIndex,
                      );
                      _scrollToDay(toDay);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Moved \"${details.data.activity.name}\" to Day ${toDay + 1}",
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onMove: (details) {
                      if (_hoveredDayTab != index) {
                        _hoveredDayTab = index;
                        _tabHoverTimer?.cancel();
                        _tabHoverTimer = Timer(
                          const Duration(milliseconds: 250),
                          () {
                            if (mounted && _hoveredDayTab == index) {
                              _scrollToDay(index);
                            }
                          },
                        );
                      }
                    },
                    onLeave: (_) {
                      if (_hoveredDayTab == index) {
                        _hoveredDayTab = null;
                        _tabHoverTimer?.cancel();
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;

                      return GestureDetector(
                        onTap: () => _scrollToDay(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: isHovered ? 16.w : 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: isHovered
                                ? LinearGradient(
                                    colors: [
                                      context.primary,
                                      context.primary.withAlpha(210),
                                    ],
                                  )
                                : null,
                            color: isHovered
                                ? null
                                : (isSelected
                                    ? context.primary
                                    : context.surface),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isHovered
                                  ? Colors.white
                                  : (isSelected
                                      ? context.primary
                                      : (isDragging
                                          ? context.primary.withAlpha(90)
                                          : context.borderColor.withAlpha(40))),
                              width: isHovered ? 2.0 : 1.2,
                            ),
                            boxShadow: (isSelected || isHovered)
                                ? [
                                    BoxShadow(
                                      color: context.primary.withAlpha(isHovered ? 70 : 40),
                                      blurRadius: isHovered ? 10 : 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isHovered) ...[
                                Icon(
                                  Icons.file_download_outlined,
                                  size: 14.sp,
                                  color: Colors.white,
                                ),
                                4.w.horizontalSpace,
                              ],
                              Text(
                                isHovered
                                    ? "Drop in Day ${index + 1}"
                                    : "Day ${index + 1}",
                                style: TextStyle(
                                  color: (isSelected || isHovered)
                                      ? Colors.white
                                      : context.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                ),
                              ),
                              6.w.horizontalSpace,
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: (isSelected || isHovered)
                                      ? Colors.white.withAlpha(50)
                                      : context.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  "$count",
                                  style: TextStyle(
                                    color: (isSelected || isHovered)
                                        ? Colors.white
                                        : context.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5.sp,
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
              ),
            ),

          // Vertical view of all days with cross-day drag and drop
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Column(
                    children: List.generate(
                      _totalDays,
                      (dayIndex) => _buildDaySection(
                        dayIndex,
                        _dayActivities[dayIndex] ?? [],
                      ),
                    ),
                  ),
                ),

                // Floating auto-scroll helper at the bottom when dragging
                if (_activeDraggingPayload != null)
                  Positioned(
                    left: 20.w,
                    right: 20.w,
                    bottom: 8.h,
                    child: DragTarget<_DragPayload>(
                      hitTestBehavior: HitTestBehavior.translucent,
                      onWillAcceptWithDetails: (_) => true,
                      onMove: (_) {
                        _startAutoScroll(26.0);
                      },
                      onLeave: (_) {
                        _stopAutoScroll();
                      },
                      onAcceptWithDetails: (details) {
                        _stopAutoScroll();
                      },
                      builder: (context, candidateData, _) {
                        final isHovered = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHovered
                                  ? [context.primary, context.primary.withAlpha(220)]
                                  : [
                                      context.surface.withAlpha(245),
                                      context.surface.withAlpha(235),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isHovered
                                  ? context.primary
                                  : context.primary.withAlpha(90),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.primary.withAlpha(isHovered ? 60 : 30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 16.sp,
                                color: isHovered ? Colors.white : context.primary,
                              ),
                              8.w.horizontalSpace,
                              Text(
                                isHovered
                                    ? "Scrolling to later days..."
                                    : "Hold here to scroll down to Day 3 & more",
                                style: TextStyle(
                                  color: isHovered ? Colors.white : context.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Floating auto-scroll helper at the top when dragging
                if (_activeDraggingPayload != null)
                  Positioned(
                    left: 20.w,
                    right: 20.w,
                    top: 6.h,
                    child: DragTarget<_DragPayload>(
                      hitTestBehavior: HitTestBehavior.translucent,
                      onWillAcceptWithDetails: (_) => true,
                      onMove: (_) {
                        _startAutoScroll(-26.0);
                      },
                      onLeave: (_) {
                        _stopAutoScroll();
                      },
                      onAcceptWithDetails: (details) {
                        _stopAutoScroll();
                      },
                      builder: (context, candidateData, _) {
                        final isHovered = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHovered
                                  ? [context.primary, context.primary.withAlpha(220)]
                                  : [
                                      context.surface.withAlpha(245),
                                      context.surface.withAlpha(235),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isHovered
                                  ? context.primary
                                  : context.primary.withAlpha(90),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.primary.withAlpha(isHovered ? 60 : 30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 16.sp,
                                color: isHovered ? Colors.white : context.primary,
                              ),
                              8.w.horizontalSpace,
                              Text(
                                isHovered
                                    ? "Scrolling to earlier days..."
                                    : "Hold here to scroll up to earlier days",
                                style: TextStyle(
                                  color: isHovered ? Colors.white : context.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Save Changes Sticky Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: context.surface,
              boxShadow: [
                BoxShadow(
                  color: context.softShadow,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayDateOnly(int dayIndex) {
    final start = widget.trip.startDate ?? DateTime.now();
    final date = start.add(Duration(days: dayIndex));
    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final daySuffix = _getDaySuffix(date.day);
    return "${monthNames[date.month - 1]} ${date.day}$daySuffix";
  }

  Widget _buildDaySection(int dayIndex, List<TripActivityModel> activities) {
    final isDragging = _activeDraggingPayload != null;

    return Column(
      key: _dayKeys[dayIndex],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header with timeline connector
        Padding(
          padding: EdgeInsets.only(top: dayIndex == 0 ? 8.h : 16.h, bottom: 10.h),
          child: Row(
            children: [
              // Timeline dot + vertical line
              SizedBox(
                width: 28.w,
                child: Column(
                  children: [
                    if (dayIndex > 0)
                      Container(
                        width: 2,
                        height: 12.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              context.primary.withAlpha(30),
                              context.primary.withAlpha(120),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primary,
                            context.primary.withAlpha(180),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.primary.withAlpha(60),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              6.w.horizontalSpace,
              // Day badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primary,
                      context.primary.withAlpha(200),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "Day ${dayIndex + 1}",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              10.w.horizontalSpace,
              Text(
                _formatDayDateOnly(dayIndex),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: activities.isEmpty
                      ? context.onSurfaceVariant.withAlpha(15)
                      : context.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  "${activities.length} ${activities.length == 1 ? 'spot' : 'spots'}",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: activities.isEmpty
                        ? context.onSurfaceVariant
                        : context.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Activities area with subtle left-side timeline
        Padding(
          padding: EdgeInsets.only(left: 13.w),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.primary.withAlpha(isDragging ? 60 : 30),
                  width: 2,
                ),
              ),
            ),
            padding: EdgeInsets.only(left: 20.w),
            child: Column(
              children: [
                if (activities.isEmpty)
                  _buildEmptyDayDropZone(dayIndex)
                else ...[
                  _buildDropSlot(dayIndex: dayIndex, slotIndex: 0),
                  for (int i = 0; i < activities.length; i++) ...[
                    _buildActivityCard(
                      dayIndex: dayIndex,
                      activityIndex: i,
                      act: activities[i],
                    ),
                    _buildDropSlot(dayIndex: dayIndex, slotIndex: i + 1),
                  ],
                ],
                8.h.verticalSpace,
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: context.primary.withAlpha(12),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 9.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide(
                          color: context.primary.withAlpha(30),
                        ),
                      ),
                    ),
                    onPressed: () => _addEventForDay(dayIndex),
                    icon: Icon(
                      Icons.add_rounded,
                      color: context.primary,
                      size: 17.sp,
                    ),
                    label: Text(
                      "Add to Day ${dayIndex + 1}",
                      style: TextStyle(
                        color: context.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ),
                ),
                14.h.verticalSpace,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropSlot({
    required int dayIndex,
    required int slotIndex,
  }) {
    final isDragging = _activeDraggingPayload != null;

    return DragTarget<_DragPayload>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        final payload = details.data;
        if (payload.fromDay == dayIndex &&
            (payload.fromIndex == slotIndex ||
                payload.fromIndex == slotIndex - 1)) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        _stopAutoScroll();
        _onDropActivity(
          fromDay: details.data.fromDay,
          fromIndex: details.data.fromIndex,
          toDay: dayIndex,
          toIndex: slotIndex,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        if (isHovered) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 52.h,
            margin: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primary.withAlpha(18),
                  context.primary.withAlpha(35),
                  context.primary.withAlpha(18),
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: context.primary.withAlpha(120),
                width: 1.8,
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) => Opacity(
                  opacity: pulseAnimation.value,
                  child: child,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22.w,
                      height: 22.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.primary.withAlpha(30),
                        border: Border.all(
                          color: context.primary.withAlpha(100),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 14.sp,
                        color: context.primary,
                      ),
                    ),
                    8.w.horizontalSpace,
                    Text(
                      "Drop here",
                      style: TextStyle(
                        color: context.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // When dragging, show a subtle indicator line
        if (isDragging) {
          return Container(
            height: 18.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.primary.withAlpha(60),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: context.primary.withAlpha(40),
                    ),
                  ),
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.primary.withAlpha(60),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(height: 4.h);
      },
    );
  }

  Widget _buildEmptyDayDropZone(int dayIndex) {
    return DragTarget<_DragPayload>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _stopAutoScroll();
        _onDropActivity(
          fromDay: details.data.fromDay,
          fromIndex: details.data.fromIndex,
          toDay: dayIndex,
          toIndex: 0,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 20.w),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primary.withAlpha(25),
                      context.primary.withAlpha(45),
                    ],
                  )
                : null,
            color: isHovered ? null : context.mutedBackground.withAlpha(80),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isHovered
                  ? context.primary
                  : context.borderColor.withAlpha(40),
              width: isHovered ? 2.2 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: context.primary.withAlpha(30),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isHovered ? (0.9 + 0.15 * pulseAnimation.value) : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHovered
                        ? context.primary.withAlpha(30)
                        : context.mutedBackground,
                    border: Border.all(
                      color: isHovered
                          ? context.primary.withAlpha(100)
                          : context.borderColor.withAlpha(30),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isHovered
                        ? Icons.file_download_rounded
                        : Icons.place_outlined,
                    size: 22.sp,
                    color: isHovered
                        ? context.primary
                        : context.primary.withAlpha(100),
                  ),
                ),
              ),
              10.h.verticalSpace,
              Text(
                isHovered
                    ? "Release to drop here"
                    : "No spots yet — drag here or add new",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: isHovered ? FontWeight.w800 : FontWeight.w500,
                  color: isHovered
                      ? context.primary
                      : context.onSurfaceVariant,
                  fontSize: 13.sp,
                  letterSpacing: isHovered ? 0.2 : 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required int dayIndex,
    required int activityIndex,
    required TripActivityModel act,
  }) {
    final payload = _DragPayload(
      fromDay: dayIndex,
      fromIndex: activityIndex,
      activity: act,
    );

    final isBeingDragged = _activeDraggingPayload?.fromDay == dayIndex &&
        _activeDraggingPayload?.fromIndex == activityIndex;

    return DragTarget<_DragPayload>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        return details.data.fromDay != dayIndex ||
            details.data.fromIndex != activityIndex;
      },
      onAcceptWithDetails: (details) {
        _stopAutoScroll();
        _onDropActivity(
          fromDay: details.data.fromDay,
          fromIndex: details.data.fromIndex,
          toDay: dayIndex,
          toIndex: activityIndex,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHoveredAsDropTarget = candidateData.isNotEmpty;

        return Stack(
          children: [
            if (isBeingDragged) _buildPlaceholderCard(),
            Opacity(
              opacity: isBeingDragged ? 0.0 : 1.0,
              child: Container(
                margin: EdgeInsets.only(bottom: 6.h),
                child: Row(
            children: [
              Draggable<_DragPayload>(
                data: payload,
                feedback: _buildDragFeedback(act),
                childWhenDragging: const SizedBox.shrink(),
                onDragStarted: () {
                  setState(() => _activeDraggingPayload = payload);
                },
                onDragUpdate: _handleDragUpdate,
                onDragEnd: (_) {
                  _stopAutoScroll();
                  if (mounted) setState(() => _activeDraggingPayload = null);
                },
                onDraggableCanceled: (_, __) {
                  _stopAutoScroll();
                  if (mounted) setState(() => _activeDraggingPayload = null);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 12.h,
                    ),
                    color: Colors.transparent,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: context.primary,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
              4.w.horizontalSpace,
              Expanded(
                child: LongPressDraggable<_DragPayload>(
                  data: payload,
                  feedback: _buildDragFeedback(act),
                  childWhenDragging: const SizedBox.shrink(),
                  onDragStarted: () {
                    setState(() => _activeDraggingPayload = payload);
                  },
                  onDragUpdate: _handleDragUpdate,
                  onDragEnd: (_) {
                    _stopAutoScroll();
                    if (mounted) setState(() => _activeDraggingPayload = null);
                  },
                  onDraggableCanceled: (_, __) {
                    _stopAutoScroll();
                    if (mounted) setState(() => _activeDraggingPayload = null);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isHoveredAsDropTarget
                          ? context.primary.withAlpha(20)
                          : context.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isHoveredAsDropTarget
                            ? context.primary
                            : context.borderColor.withAlpha(20),
                        width: isHoveredAsDropTarget ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.softShadow,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: CachedNetworkImage(
                            imageUrl: _getImageUrl(act),
                            width: 48.w,
                            height: 48.h,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 48.w,
                              height: 48.h,
                              color: context.shimmerBase,
                              child: Icon(
                                Icons.place,
                                size: 20.sp,
                                color: context.primary,
                              ),
                            ),
                          ),
                        ),
                        8.w.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              4.h.verticalSpace,
                              Text(
                                _getCategoryName(act.category),
                                style: context.text.bodySmall?.copyWith(
                                  color: context.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_totalDays > 1) ...[
                PopupMenuButton<int>(
                  tooltip: "Move to another day",
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: context.onSurfaceVariant,
                    size: 22.sp,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  onSelected: (targetDayIndex) {
                    _moveActivityToDay(
                      dayIndex,
                      activityIndex,
                      targetDayIndex,
                    );
                  },
                  itemBuilder: (context) {
                    return List.generate(_totalDays, (dIdx) {
                      final isCurrent = dIdx == dayIndex;
                      return PopupMenuItem<int>(
                        value: dIdx,
                        enabled: !isCurrent,
                        child: Text(
                          "Move to Day ${dIdx + 1}",
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: isCurrent
                                ? Colors.grey
                                : context.onSurface,
                          ),
                        ),
                      );
                    });
                  },
                ),
              ],
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22.sp,
                ),
                onPressed: () => _confirmDeleteEvent(
                  context,
                  dayIndex,
                  activityIndex,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
},
);
}

  Widget _buildDragFeedback(TripActivityModel act) {
    return Transform.rotate(
      angle: -0.018,
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48.w,
        child: Material(
          elevation: 20,
          shadowColor: context.primary.withAlpha(60),
          borderRadius: BorderRadius.circular(18.r),
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.surface,
                  context.surface.withAlpha(250),
                ],
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: context.primary.withAlpha(160),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primary.withAlpha(25),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.primary.withAlpha(20),
                  ),
                  child: Icon(
                    Icons.open_with_rounded,
                    color: context.primary,
                    size: 18.sp,
                  ),
                ),
                8.w.horizontalSpace,
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(act),
                    width: 46.w,
                    height: 46.h,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 46.w,
                      height: 46.h,
                      decoration: BoxDecoration(
                        color: context.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.place,
                        size: 22.sp,
                        color: context.primary,
                      ),
                    ),
                  ),
                ),
                10.w.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        act.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                          color: context.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      3.h.verticalSpace,
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(act.category),
                            size: 12.sp,
                            color: context.onSurfaceVariant,
                          ),
                          4.w.horizontalSpace,
                          Text(
                            _getCategoryName(act.category),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primary,
                        context.primary.withAlpha(200),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: context.primary.withAlpha(50),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_with_rounded,
                        size: 11.sp,
                        color: Colors.white,
                      ),
                      4.w.horizontalSpace,
                      Text(
                        "Moving",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5.sp,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(int categoryCode) {
    switch (categoryCode) {
      case 1:
        return Icons.restaurant_rounded;
      case 2:
        return Icons.directions_car_rounded;
      case 3:
        return Icons.hotel_rounded;
      case 4:
        return Icons.spa_rounded;
      case 5:
        return Icons.shopping_bag_rounded;
      case 0:
        return Icons.camera_alt_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Widget _buildPlaceholderCard() {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        return Container(
          height: 62.h,
          margin: EdgeInsets.only(bottom: 6.h),
          decoration: BoxDecoration(
            color: context.primary.withAlpha(
              (8 + 12 * pulseAnimation.value).toInt(),
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.primary.withAlpha(
                (40 + 40 * pulseAnimation.value).toInt(),
              ),
              width: 1.5,
            ),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: context.primary.withAlpha(50),
              borderRadius: 16.r,
              dashWidth: 8,
              dashGap: 5,
              strokeWidth: 1.2,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.open_with_rounded,
                    size: 16.sp,
                    color: context.primary.withAlpha(140),
                  ),
                  8.w.horizontalSpace,
                  Text(
                    "Drop to reposition",
                    style: TextStyle(
                      color: context.primary.withAlpha(160),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints a dashed rounded rect border for the placeholder card.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance = end + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        borderRadius != oldDelegate.borderRadius;
  }
}
