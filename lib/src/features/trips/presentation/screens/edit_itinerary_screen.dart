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

class EditItineraryScreen extends StatefulWidget {
  final TripData trip;
  final List<TripActivityModel> initialActivities;

  const EditItineraryScreen({
    super.key,
    required this.trip,
    required this.initialActivities,
  });

  @override
  State<EditItineraryScreen> createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen> {
  // Map of day index (0-based) to list of activities
  late Map<int, List<TripActivityModel>> _dayActivities;
  final List<String> _deletedActivityIds = [];
  final List<TripActivityModel> _addedActivities = [];
  bool _isSaving = false;

  int get _totalDays {
    if (widget.trip.startDate == null || widget.trip.endDate == null) return 3;
    final diff = widget.trip.endDate!.difference(widget.trip.startDate!).inDays;
    return diff >= 0 ? diff + 1 : 3;
  }

  @override
  void initState() {
    super.initState();
    _initializeDayActivities();
  }

  void _initializeDayActivities() {
    _dayActivities = {};
    for (int i = 0; i < _totalDays; i++) {
      _dayActivities[i] = [];
    }

    for (var act in widget.initialActivities) {
      final dayNum = int.tryParse(act.dayId) ?? 1;
      final dayIndex = (dayNum - 1).clamp(0, _totalDays - 1);
      _dayActivities[dayIndex]?.add(act);
    }
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
        builder: (context) => AddEventScreen(dayTitle: dayTitle),
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
          final res = await apiService.delete<dynamic>(
            "/TripActivity/$id",
            fromJson: (data) => data,
          );
          if (res is Failure) {
            throw Exception(res.message);
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
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              itemCount: _totalDays,
              itemBuilder: (context, dayIndex) {
                final dayTitle = _formatDayTitle(dayIndex);
                final activities = _dayActivities[dayIndex] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Text(
                        dayTitle,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.sp,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    // Reorderable Activity List for Day
                    if (activities.isNotEmpty)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activities.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = activities.removeAt(oldIndex);
                            activities.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, activityIndex) {
                          final act = activities[activityIndex];
                          return Container(
                            key: ValueKey(
                              "${act.name}_${activityIndex}_$dayIndex",
                            ),
                            margin: EdgeInsets.only(bottom: 6.h),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.drag_indicator_rounded,
                                  color: context.onSurfaceVariant,
                                  size: 20.sp,
                                ),
                                4.w.horizontalSpace,
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: context.surface,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: context.borderColor.withAlpha(20),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                act.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context.text.bodyMedium
                                                    ?.copyWith(
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
                                2.w.horizontalSpace,
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
                          );
                        },
                      ),

                    // Add More Events Button
                    12.h.verticalSpace,
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: context.primary.withAlpha(15),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        onPressed: () => _addEventForDay(dayIndex),
                        icon: Icon(
                          Icons.add_rounded,
                          color: context.primary,
                          size: 18.sp,
                        ),
                        label: Text(
                          "Add More Events",
                          style: TextStyle(
                            color: context.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                    24.h.verticalSpace,
                  ],
                );
              },
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
}
