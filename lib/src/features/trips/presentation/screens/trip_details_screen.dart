import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/core/services/google_map_services.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/circular_icon.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/config/utils/mongo_id_helper.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/map_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonder_souls/src/features/trips/model/trip_activity_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/edit_itinerary_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/trip_bookings_sheet.dart';

class TripDetailsScreen extends StatefulWidget {
  final TripData trip;
  static const String routeName = "/TripDetailsScreen";

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late TripData _tripState;
  int _selectedDayIndex = 0;
  List<TripActivityModel> _activities = [];
  bool _loadingActivities = false;
  OverlayEntry? _notificationOverlay;

  // Search & suggestions
  final TextEditingController _searchController = TextEditingController();
  List<PlaceModel> _suggestions = [];
  bool _searchingLocations = false;
  final FocusNode _searchFocusNode = FocusNode();

  // AI Suggestions
  List<dynamic> _aiSuggestions = [];
  bool _loadingAiSuggestions = false;
  String? _aiSuggestionsError;

  List<String> _attachments = [];
  bool _uploadingAttachment = false;

  @override
  void initState() {
    super.initState();
    _tripState = widget.trip;
    _fetchTripDetails();
    _fetchActivities();
    _fetchAiSuggestions();
    _loadAttachments();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadAttachments() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("attachments_${_tripState.id}");
    if (list != null) {
      setState(() {
        _attachments = list;
      });
    }
  }

  Future<void> _saveAttachments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("attachments_${_tripState.id}", _attachments);
  }

  Future<void> _pickAndUploadAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _uploadingAttachment = true);
    AppToast.success("Uploading attachment...");

    final filename = pickedFile.path.split("/").last;
    final extension = filename.split(".").last;
    final blobPath =
        "attachments/${_tripState.id}_${DateTime.now().millisecondsSinceEpoch}.$extension";

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.uploadFile(pickedFile.path, blobPath);

      if (result is Success<String>) {
        setState(() {
          _attachments.add(blobPath);
          _uploadingAttachment = false;
        });
        await _saveAttachments();
        AppToast.success("Attachment uploaded successfully!");
      } else {
        setState(() => _uploadingAttachment = false);
        AppToast.error("Failed to upload attachment");
      }
    } catch (e) {
      setState(() => _uploadingAttachment = false);
      AppToast.error("Error uploading file: $e");
    }
  }

  Future<void> _downloadAndOpenAttachment(String blobPath) async {
    AppToast.success("Opening document...");
    try {
      final apiService = sl<ApiService>();
      final result = await apiService.downloadFile(blobPath);

      if (result is Success<String> && result.data.isNotEmpty) {
        final url = Uri.parse(result.data);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          AppToast.error("Could not launch file reader");
        }
      } else {
        AppToast.error("Failed to download file");
      }
    } catch (e) {
      AppToast.error("Error opening document: $e");
    }
  }

  Future<void> _fetchTripDetails() async {
    if (_tripState.id.isEmpty) return;
    try {
      final apiService = sl<ApiService>();
      final res = await apiService.get<dynamic>(
        "/Trips/${_tripState.id}",
        fromJson: (data) => data,
      );
      if (res is Success && res.data != null && res.data["data"] != null) {
        setState(() {
          _tripState = TripData.fromJson(res.data["data"]);
        });
      }
    } catch (e) {
      debugPrint("Error fetching trip details: $e");
    }
  }

  void _showEditTripDialog() {
    final nameController = TextEditingController(text: _tripState.name);
    final descController = TextEditingController(text: _tripState.description);
    DateTime start = _tripState.startDate ?? DateTime.now();
    DateTime end =
        _tripState.endDate ?? DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Trip Details"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Trip Name"),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                    16.h.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: start,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setStateDialog(() => start = picked);
                              }
                            },
                            child: Text("Start: ${start.day}/${start.month}"),
                          ),
                        ),
                        8.w.horizontalSpace,
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: end,
                                firstDate: start,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setStateDialog(() => end = picked);
                              }
                            },
                            child: Text("End: ${end.day}/${end.month}"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context);

                    AppToast.success("Updating trip...");
                    try {
                      final apiService = sl<ApiService>();
                      final payload = {
                        "name": name,
                        "description": descController.text.trim(),
                        "startDate": start.toUtc().toIso8601String(),
                        "endDate": end.toUtc().toIso8601String(),
                        "mainDestination": _tripState.mainDestination,
                        "whoIsGoing": _tripState.tripType,
                        "isPublic": false,
                        "travelTastes": _tripState.travelTastes,
                        "budget": {
                          "budgetType": _tripState.category,
                          "totalEstimated": 2000,
                          "currency": "USD",
                        },
                      };

                      final res = await apiService.put<dynamic>(
                        "/Trips/${_tripState.id}",
                        data: payload,
                        fromJson: (d) => d,
                      );

                      if (res is Success) {
                        AppToast.success("Trip updated successfully!");
                        _fetchTripDetails();
                      } else {
                        AppToast.error("Failed to update trip details");
                      }
                    } catch (e) {
                      AppToast.error("Error updating trip: $e");
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _dismissNotification();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Calculate total days from trip dates
  int get _totalDays {
    if (_tripState.startDate == null || _tripState.endDate == null) return 3;
    final diff = _tripState.endDate!.difference(_tripState.startDate!).inDays;
    return diff >= 0 ? diff + 1 : 3;
  }

  // Get current date of the selected day index
  DateTime get _currentDayDate {
    final start = _tripState.startDate ?? DateTime.now();
    return start.add(Duration(days: _selectedDayIndex));
  }

  Future<void> _fetchAiSuggestions() async {
    setState(() {
      _loadingAiSuggestions = true;
      _aiSuggestionsError = null;
    });

    final start = _tripState.startDate ?? DateTime.now();
    final end =
        _tripState.endDate ?? DateTime.now().add(const Duration(days: 3));

    final payload = {
      "destination": _tripState.mainDestination,
      "startDate": start.toUtc().toIso8601String(),
      "endDate": end.toUtc().toIso8601String(),
      "whoIsGoing": _tripState.tripType.toLowerCase(),
      "travelTastes": _tripState.travelTastes,
      "budget": {
        "budgetType": _tripState.category.toLowerCase(),
        "totalEstimated": 2000,
        "currency": "USD",
        "byCategory": {
          "transportation": 0,
          "accommodation": 0,
          "food": 0,
          "activities": 0,
        },
      },
      "tripName": _tripState.name,
      "description": "",
    };

    try {
      final apiService = sl<ApiService>();
      final aiResult = await apiService.aiPost(
        ApiConstants.generateItinerary,
        data: payload,
      );

      if (aiResult is Success<Map<String, dynamic>>) {
        final data = aiResult.data;
        final List<dynamic> days = data["itinerary"] ?? [];

        // Extract all activities across all days as suggestions
        final List<dynamic> suggestions = [];
        for (var day in days) {
          final List<dynamic> acts = day["activities"] ?? [];
          suggestions.addAll(acts);
        }

        setState(() {
          _aiSuggestions = suggestions;
          _loadingAiSuggestions = false;
        });
      } else if (aiResult is Failure<Map<String, dynamic>>) {
        setState(() {
          _aiSuggestionsError = "Failed to load AI suggestions";
          _loadingAiSuggestions = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiSuggestionsError = "AI Service offline";
        _loadingAiSuggestions = false;
      });
    }
  }

  int _getAiCategoryEnum(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case "landmark":
      case "culture":
      case "adventure":
      case "entertainment":
      case "nature":
        return 0; // Sightseeing
      case "food":
        return 1; // Food
      case "transport":
        return 2; // Transport
      case "accommodation":
        return 3; // Accommodation
      case "relaxation":
        return 4; // Relaxation
      case "shopping":
        return 5; // Shopping
      default:
        return 6; // Other
    }
  }

  Future<void> _addAiSuggestionToItinerary(Map<String, dynamic> act) async {
    final dateStr = _currentDayDate.toIso8601String().split('T').first;
    final startDatetime = DateTime.parse("${dateStr}T09:00:00Z");
    final endDatetime = DateTime.parse("${dateStr}T10:00:00Z");

    final name = act["name"] ?? "Activity";
    final categoryStr = act["category"] ?? "Landmark";
    final desc = act["description"] ?? "";
    final cost = (act["estimatedCost"] as num?)?.toDouble() ?? 0.0;
    final tips = act["tips"] ?? "";

    final payload = {
      "tripId": _tripState.id,
      "placeId": convertToMongoObjectId("ai_${DateTime.now().millisecondsSinceEpoch}"),
      "name": name,
      "bookingReference": "",
      "startDatetime": startDatetime.toUtc().toIso8601String(),
      "endDatetime": endDatetime.toUtc().toIso8601String(),
      "currency": "USD",
      "bookingUrl": "",
      "confirmationDocumentUrl": "",
      "activityDetailsDto": {
        "categoryDto": _getAiCategoryEnum(categoryStr),
        "participants": [],
        "meetingPoint": "",
        "duration": 60,
        "difficulty": "Easy",
        "ageRestriction": "None",
        "cost": cost,
        "tips": tips,
        "imageUrl": _getPlaceImageUrl(_getAiCategoryEnum(categoryStr), name),
      },
      "notes": desc,
    };

    AppToast.success("Adding $name...");

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.post<dynamic>(
        "/TripActivity",
        data: payload,
        fromJson: (json) => json,
      );

      if (result is Success<dynamic>) {
        AppToast.success("Added to itinerary!");
        _fetchActivities();
      } else if (result is Failure<dynamic>) {
        AppToast.error(result.message);
      }
    } catch (e) {
      AppToast.error("Failed to add: $e");
    }
  }

  Future<void> _fetchActivities() async {
    setState(() => _loadingActivities = true);
    try {
      final apiService = sl<ApiService>();
      final result = await apiService.get<List<dynamic>>(
        "/TripActivity?TripId=${_tripState.id}",
        fromJson: (json) => json as List<dynamic>,
      );

      if (result is Success<List<dynamic>>) {
        final start = _tripState.startDate ?? DateTime.now();
        final List<TripActivityModel> all = result.data
            .map(
              (item) {
                final model = TripActivityModel.fromJson(item as Map<String, dynamic>);
                final diffDays = DateTime(model.startDatetime.year, model.startDatetime.month, model.startDatetime.day)
                    .difference(DateTime(start.year, start.month, start.day))
                    .inDays;
                return model.copyWith(dayId: "${diffDays + 1}");
              },
            )
            .toList();

        setState(() {
          // Filter locally by tripId and sort by startDatetime
          _activities = all
              .where((act) => act.tripId == _tripState.id)
              .toList();
          _activities.sort(
            (a, b) => a.startDatetime.compareTo(b.startDatetime),
          );
          _loadingActivities = false;
        });
      } else {
        setState(() => _loadingActivities = false);
      }
    } catch (e) {
      setState(() => _loadingActivities = false);
    }
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _searchLocations(text);
  }

  Future<void> _searchLocations(String query) async {
    setState(() => _searchingLocations = true);
    final mapApiService = sl<GoogleMapsApiService>();
    final result = await mapApiService.searchPlaces(query);

    result.fold((failure) => setState(() => _searchingLocations = false), (
      places,
    ) {
      if (_searchController.text.trim().isNotEmpty) {
        setState(() {
          _suggestions = places;
          _searchingLocations = false;
        });
      }
    });
  }

  String _getPlaceImageUrl(int category, String name) {
    switch (category) {
      case 1: // Food
        return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800";
      case 2: // Transport
        return "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800";
      case 3: // Accommodation
        return "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800";
      case 4: // Relaxation
        return "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800";
      case 5: // Shopping
        return "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800";
      case 0: // Sightseeing
        return "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800";
      default:
        return "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800";
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
        types.contains("subway_station") ||
        types.contains("train_station") ||
        types.contains("bus_station")) {
      return 2; // Transport
    }
    if (types.contains("lodging") ||
        types.contains("hotel") ||
        types.contains("accommodation")) {
      return 3; // Accommodation
    }
    if (types.contains("spa") ||
        types.contains("beauty_salon") ||
        types.contains("gym") ||
        types.contains("physiotherapist")) {
      return 4; // Relaxation
    }
    if (types.contains("shopping_mall") ||
        types.contains("store") ||
        types.contains("clothing_store") ||
        types.contains("supermarket")) {
      return 5; // Shopping
    }
    if (types.contains("attraction") ||
        types.contains("museum") ||
        types.contains("landmark") ||
        types.contains("park") ||
        types.contains("natural_feature")) {
      return 0; // Sightseeing
    }
    return 6; // Other
  }

  Future<void> _addActivity(PlaceModel suggestion) async {
    // Unfocus and clear search
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() => _suggestions = []);

    final dateStr = _currentDayDate.toIso8601String().split('T').first;
    final startDatetime = DateTime.parse("${dateStr}T09:00:00Z");
    final endDatetime = DateTime.parse("${dateStr}T10:00:00Z");

    final cat = _getCategoryEnum(suggestion.types);

    final payload = {
      "tripId": _tripState.id,
      "placeId": convertToMongoObjectId(suggestion.placeId.isNotEmpty
          ? suggestion.placeId
          : "place_${DateTime.now().millisecondsSinceEpoch}"),
      "name": suggestion.name,
      "bookingReference": "",
      "startDatetime": startDatetime.toUtc().toIso8601String(),
      "endDatetime": endDatetime.toUtc().toIso8601String(),
      "currency": "USD",
      "bookingUrl": "",
      "confirmationDocumentUrl": "",
      "activityDetailsDto": {
        "categoryDto": cat,
        "participants": [],
        "meetingPoint": suggestion.address,
        "duration": 60,
        "difficulty": "Easy",
        "ageRestriction": "None",
        "cost": 0.0,
        "tips": "Added to itinerary",
        "imageUrl": _getPlaceImageUrl(cat, suggestion.name),
      },
      "notes": suggestion.description,
    };

    AppToast.success("Adding ${suggestion.name}...");

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.post<dynamic>(
        "/TripActivity",
        data: payload,
        fromJson: (json) => json,
      );

      if (result is Success<dynamic>) {
        AppToast.success("Added successfully!");
        _fetchActivities();
      } else if (result is Failure<dynamic>) {
        AppToast.error(result.message);
      }
    } catch (e) {
      AppToast.error("Failed to add activity: $e");
    }
  }

  Future<void> _deleteActivity(String activityId) async {
    AppToast.success("Removing activity...");
    try {
      final apiService = sl<ApiService>();
      final result = await apiService.delete<dynamic>(
        "/TripActivity/$activityId",
        fromJson: (json) => json,
      );

      if (result is Success<dynamic>) {
        AppToast.success("Removed successfully!");
        _fetchActivities();
      } else if (result is Failure<dynamic>) {
        AppToast.error(result.message);
      }
    } catch (e) {
      AppToast.error("Failed to remove activity: $e");
    }
  }

  void _showInAppNotification({
    required String title,
    required String message,
    required String cta,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onAccept,
  }) {
    _dismissNotification();

    _notificationOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 50.h,
          left: 16.w,
          right: 16.w,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: -100.0, end: 0.0),
              builder: (context, slideY, child) {
                return Transform.translate(
                  offset: Offset(0, slideY),
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(220),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24.sp,
                      ),
                    ),
                    12.w.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          4.h.verticalSpace,
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    12.w.horizontalSpace,
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      onPressed: () {
                        _dismissNotification();
                        onAccept();
                      },
                      child: Text(
                        cta,
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_notificationOverlay!);

    // Automatically dismiss after 7 seconds
    Future.delayed(const Duration(seconds: 7), () {
      _dismissNotification();
    });
  }

  void _dismissNotification() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  void _showRecommendationDialog({
    required String title,
    required String content,
    required VoidCallback onAccept,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.teal, size: 20.sp),
            8.w.horizontalSpace,
            Text(
              "WanderSouls AI",
              style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          content,
          style: context.text.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Keep Original Plan",
              style: TextStyle(color: context.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              onAccept();
            },
            child: const Text("Accept Recommendation"),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDelayOptimization() async {
    TripActivityModel? echoPoint;
    for (final a in _activities) {
      if (a.name.toLowerCase().contains("echo point")) {
        echoPoint = a;
        break;
      }
    }
    
    if (echoPoint == null && _activities.isNotEmpty) {
      echoPoint = _activities[(_activities.length > 1) ? 1 : 0];
    }

    if (echoPoint != null) {
      await _deleteActivity(echoPoint.id);
    }

    TripActivityModel? kundalaLake;
    for (final a in _activities) {
      if (a.name.toLowerCase().contains("kundala lake")) {
        kundalaLake = a;
        break;
      }
    }

    if (kundalaLake == null && _activities.isNotEmpty) {
      kundalaLake = _activities.last;
    }

    if (kundalaLake != null) {
      final newStart = DateTime(
        kundalaLake.startDatetime.year,
        kundalaLake.startDatetime.month,
        kundalaLake.startDatetime.day,
        15,
        30,
      );
      final newEnd = newStart.add(const Duration(hours: 1));
      final payload = {
        "id": kundalaLake.id,
        "tripId": kundalaLake.tripId,
        "name": kundalaLake.name,
        "startDatetime": newStart.toIso8601String(),
        "endDatetime": newEnd.toIso8601String(),
        "category": kundalaLake.category,
        "cost": kundalaLake.cost,
        "tips": kundalaLake.tips,
        "notes": kundalaLake.notes,
        "imageUrl": kundalaLake.imageUrl,
      };

      try {
        final apiService = sl<ApiService>();
        await apiService.put<dynamic>("/TripActivity/${kundalaLake.id}", data: payload, fromJson: (json) => json);
      } catch (e) {
        debugPrint("Error updating activity: $e");
      }
    }

    await _fetchActivities();
    AppToast.success("Itinerary optimized successfully!");
  }

  Future<void> _applyRainAlternative() async {
    TripActivityModel? dam;
    for (final a in _activities) {
      final nameLower = a.name.toLowerCase();
      if (nameLower.contains("dam") || nameLower.contains("lake") || nameLower.contains("park")) {
        dam = a;
        break;
      }
    }

    if (dam == null && _activities.isNotEmpty) {
      dam = _activities.first;
    }

    if (dam != null) {
      final payload = {
        "id": dam.id,
        "tripId": dam.tripId,
        "name": "Munnar Tea Museum",
        "startDatetime": dam.startDatetime.toIso8601String(),
        "endDatetime": dam.endDatetime.toIso8601String(),
        "category": 0,
        "cost": 10.0,
        "tips": "Indoor alternative recommended due to expected rain.",
        "notes": "Explore the history of tea plantation in Munnar inside this museum.",
        "imageUrl": "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800",
      };

      try {
        final apiService = sl<ApiService>();
        await apiService.put<dynamic>("/TripActivity/${dam.id}", data: payload, fromJson: (json) => json);
      } catch (e) {
        debugPrint("Error swapping activity: $e");
      }
    }

    await _fetchActivities();
    AppToast.success("Outdoor activity replaced with indoor alternative!");
  }

  Future<void> _applyWeatherClearRestore() async {
    TripActivityModel? museum;
    for (final a in _activities) {
      if (a.name.toLowerCase().contains("museum")) {
        museum = a;
        break;
      }
    }

    if (museum == null && _activities.isNotEmpty) {
      museum = _activities.first;
    }

    if (museum != null) {
      final payload = {
        "id": museum.id,
        "tripId": museum.tripId,
        "name": "Mattupetty Dam",
        "startDatetime": museum.startDatetime.toIso8601String(),
        "endDatetime": museum.endDatetime.toIso8601String(),
        "category": 0,
        "cost": 0.0,
        "tips": "Weather cleared up! Restored outdoor activity.",
        "notes": "Enjoy the scenic beauty of Mattupetty Dam under clear skies.",
        "imageUrl": "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800",
      };

      try {
        final apiService = sl<ApiService>();
        await apiService.put<dynamic>("/TripActivity/${museum.id}", data: payload, fromJson: (json) => json);
      } catch (e) {
        debugPrint("Error restoring activity: $e");
      }
    }

    await _fetchActivities();
    AppToast.success("Mattupetty Dam restored to itinerary!");
  }

  void _showNotificationSimulatorSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "In-App Notification Simulator",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.onSurface,
                ),
              ),
              8.h.verticalSpace,
              Text(
                "Select a scenario to trigger an in-app notification:",
                style: context.text.bodySmall?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
              16.h.verticalSpace,
              
              _buildSimulatorOption(
                sheetCtx,
                icon: Icons.wb_sunny_outlined,
                title: "1. Morning Reminder (30-min-before)",
                description: "Notify user 30 minutes before first activity",
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showInAppNotification(
                    title: "Ready for today?",
                    message: "Your first experience starts in 30 minutes. Check your itinerary and get ready for an amazing day.",
                    cta: "View Today's Plan",
                    icon: Icons.wb_sunny_outlined,
                    iconColor: Colors.amber,
                    onAccept: () {
                      AppToast.success("Enjoy your day!");
                    },
                  );
                },
              ),
              
              _buildSimulatorOption(
                sheetCtx,
                icon: Icons.timer_outlined,
                title: "2. Trip Delay Optimization",
                description: "AI optimizes itinerary due to a 45-min delay",
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showInAppNotification(
                    title: "We've optimized your itinerary",
                    message: "You're running behind schedule. To avoid rushing, we've skipped Echo Point and adjusted the rest of your day. Your next activity is Kundala Lake at 3:30 PM.",
                    cta: "See New Plan",
                    icon: Icons.auto_awesome,
                    iconColor: Colors.teal,
                    onAccept: () {
                      _showRecommendationDialog(
                        title: "AI Itinerary Optimization",
                        content: "You're running behind schedule. To avoid rushing, WanderSouls AI recommends skipping Echo Point and updating Kundala Lake to start at 3:30 PM.",
                        onAccept: () async {
                          await _applyDelayOptimization();
                        },
                      );
                    },
                  );
                },
              ),
              
              _buildSimulatorOption(
                sheetCtx,
                icon: Icons.cloud_outlined,
                title: "3. Rain Detection (Outdoor to Indoor)",
                description: "Weather warning: replace outdoor Dam with indoor Museum",
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showInAppNotification(
                    title: "Weather update",
                    message: "Rain is expected during your next outdoor activity. We've found a better option nearby so you can keep enjoying your day.",
                    cta: "View AI Recommendation",
                    icon: Icons.cloud,
                    iconColor: Colors.blue,
                    onAccept: () {
                      _showRecommendationDialog(
                        title: "Rain Alert & AI Recommendation",
                        content: "Rain is expected at 3:00 PM when you're scheduled to visit Mattupetty Dam (outdoor). WanderSouls AI recommends swapping it for the Munnar Tea Museum (indoor).",
                        onAccept: () async {
                          await _applyRainAlternative();
                        },
                      );
                    },
                  );
                },
              ),
              
              _buildSimulatorOption(
                sheetCtx,
                icon: Icons.sunny,
                title: "4. Weather Improves (Restore Outdoor)",
                description: "Rain cleared: restore Mattupetty Dam back to timeline",
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showInAppNotification(
                    title: "Good news — the weather cleared up",
                    message: "The rain has moved away and Mattupetty Dam is looking good again. We've updated your itinerary to make the most of the weather.",
                    cta: "View Updated Plan",
                    icon: Icons.sunny,
                    iconColor: Colors.orange,
                    onAccept: () {
                      _showRecommendationDialog(
                        title: "Weather Cleared Up",
                        content: "The weather has improved at Mattupetty Dam. WanderSouls AI recommends restoring it to your itinerary instead of the Tea Museum.",
                        onAccept: () async {
                          await _applyWeatherClearRestore();
                        },
                      );
                    },
                  );
                },
              ),
              12.h.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulatorOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.primary.withAlpha(20),
        child: Icon(icon, color: context.colors.primary, size: 20.sp),
      ),
      title: Text(
        title,
        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        description,
        style: context.text.labelSmall?.copyWith(color: context.onSurfaceVariant),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter activities for the selected day
    final dayActivities = _activities
        .where((act) => act.dayId == "${_selectedDayIndex + 1}")
        .toList();

    // Map activities to MarkerData for the Google Map
    final List<MarkerData> markers = [];
    // To generate coordinates, we use dummy offsets or fallbacks since rating/address details are stored,
    // but in case lat/lng is not stored in activity details we can use the main destination lat/lng as base.
    // For locations suggestion API, the rating/lat/lng is populated. Let's map coordinates:
    for (var act in dayActivities) {
      // Typically activities from suggest locations have coordinates. Let's assume a default center if null.
      markers.add(
        MarkerData(
          id: act.id,
          title: act.name,
          lat:
              22.5726 +
              (markers.length *
                  0.01), // dummy offset so they don't overlap if not provided
          lng: 88.3639 + (markers.length * 0.01),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchActivities();
          await _fetchAiSuggestions();
        },
        color: context.primary,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTripHeader(context, markers),
                  _buildDaySelector(context),
                  _buildAiSuggestionsList(context),
                  _buildSearchAndSuggestions(context),
                  if (_loadingActivities)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildActivitiesTimeline(context, dayActivities),
                  _buildAttachmentsSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSuggestionsList(BuildContext context) {
    if (_loadingAiSuggestions) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: context.primary, size: 18.sp),
                8.w.horizontalSpace,
                Text(
                  "AI Suggestions Loading...",
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            12.h.verticalSpace,
            const LinearProgressIndicator(),
          ],
        ),
      );
    }

    if (_aiSuggestionsError != null) {
      return const SizedBox.shrink(); // Hide if failed to avoid visual clutter
    }

    if (_aiSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: context.primary, size: 18.sp),
              8.w.horizontalSpace,
              Text(
                "🪄 AI Suggestions for ${_tripState.mainDestination}",
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            scrollDirection: Axis.horizontal,
            itemCount: _aiSuggestions.length,
            separatorBuilder: (context, index) => 12.w.horizontalSpace,
            itemBuilder: (context, index) {
              final act = _aiSuggestions[index];
              final name = act["name"] ?? "Activity";
              final category = act["category"] ?? "Landmark";
              final cost = act["estimatedCost"] != null
                  ? "\$${act["estimatedCost"]}"
                  : "Free";

              return Container(
                width: 200.w,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: context.borderColor.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addAiSuggestionToItinerary(
                            act as Map<String, dynamic>,
                          ),
                          child: Icon(
                            Icons.add_circle,
                            color: context.primary,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),
                    4.h.verticalSpace,
                    Text(
                      category,
                      style: context.text.bodySmall?.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cost,
                          style: context.text.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (act["duration"] != null)
                          Text(
                            act["duration"],
                            style: context.text.bodySmall?.copyWith(
                              color: context.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        16.h.verticalSpace,
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      backgroundColor: context.surface,
      leading: Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: CircularIcon(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.sp,
            color: context.onSurface,
          ),
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: CircularIcon(
            icon: Icon(
              Icons.notifications_active_outlined,
              size: 20.sp,
              color: Colors.amber,
            ),
            onTap: _showNotificationSimulatorSheet,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: CircularIcon(
            icon: Icon(
              Icons.edit_note_rounded,
              size: 22.sp,
              color: context.onSurface,
            ),
            onTap: _showEditTripDialog,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: CircularIcon(
            icon: Icon(
              Icons.hotel_outlined,
              size: 20.sp,
              color: context.onSurface,
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TripBookingsSheet(tripId: _tripState.id),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _tripState.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: context.shimmerBase,
                child: Icon(
                  Icons.image_rounded,
                  size: 64.sp,
                  color: context.onSurfaceVariant.withAlpha(60),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(80)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeader(BuildContext context, List<MarkerData> markers) {
    return Container(
      color: context.surface,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tripState.name,
                      style: context.text.titleLarge?.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    6.h.verticalSpace,
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16.sp,
                          color: context.primary,
                        ),
                        4.w.horizontalSpace,
                        Text(
                          _tripState.mainDestination,
                          style: context.bodyMedium?.copyWith(
                            color: context.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        12.w.horizontalSpace,
                        Text(
                          _tripState.flag,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ],
                    ),
                    if (_tripState.description.isNotEmpty) ...[
                      8.h.verticalSpace,
                      Text(
                        _tripState.description,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          16.h.verticalSpace,

          // Interactive Map
          Container(
            height: 180.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: context.softShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: MapView(markers: markers),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditItinerary() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditItineraryScreen(
          trip: _tripState,
          initialActivities: _activities,
        ),
      ),
    );

    if (result == true) {
      _fetchActivities();
    }
  }

  Widget _buildDaySelector(BuildContext context) {
    return Container(
      height: 48.h,
      margin: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              scrollDirection: Axis.horizontal,
              itemCount: _totalDays,
              separatorBuilder: (context, index) => 8.w.horizontalSpace,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedDayIndex;
                final date = (_tripState.startDate ?? DateTime.now()).add(
                  Duration(days: index),
                );
                final formattedDate = "${date.day}/${date.month}";

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : context.mutedBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.primary.withAlpha(40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Day ${index + 1}",
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white70
                                : context.onSurfaceVariant,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: GestureDetector(
              onTap: _openEditItinerary,
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: context.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSuggestions(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText:
                  "Search places to add to Day ${_selectedDayIndex + 1}...",
              hintStyle: context.text.bodyMedium?.copyWith(
                color: context.onSurfaceVariant.withAlpha(120),
              ),
              prefixIcon: Icon(Icons.search, color: context.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _suggestions = []);
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.mutedBackground,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_searchingLocations)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(),
            ),
          if (_suggestions.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.only(top: 8.h),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.primaryTint,
                      child: Icon(
                        Icons.place,
                        color: context.primary,
                        size: 18.sp,
                      ),
                    ),
                    title: Text(
                      suggestion.name,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      suggestion.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: context.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _addActivity(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? "PM" : "AM";
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return "${formattedHour.toString().padLeft(2, '0')}:$formattedMinute $period";
  }

  Future<void> _launchMaps(String query) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        AppToast.error("Could not launch Maps");
      }
    } catch (e) {
      AppToast.error("Failed to launch maps: $e");
    }
  }

  void _confirmDelete(BuildContext context, TripActivityModel activity) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Delete Activity"),
        content: Text(
          "Are you sure you want to remove ${activity.name}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _deleteActivity(activity.id);
            },
            child: Text(
              "Delete",
              style: TextStyle(
                color: context.colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTransitionRow(
    BuildContext context,
    TripActivityModel prevActivity,
    TripActivityModel nextActivity,
  ) {
    final seed = prevActivity.name.hashCode.abs() + nextActivity.name.hashCode.abs();
    final carDuration = 5 + (seed % 15);
    final bikeDuration = carDuration * 2 + (seed % 5);
    final transitDuration = carDuration + 10 + (seed % 10);
    final walkDuration = carDuration * 3 + (seed % 10);

    final modes = [
      (icon: Icons.directions_car, duration: "$carDuration min"),
      (icon: Icons.directions_bike, duration: "$bikeDuration min"),
      (icon: Icons.directions_transit, duration: "$transitDuration min"),
      (icon: Icons.directions_walk, duration: "$walkDuration min"),
      (icon: Icons.local_taxi, duration: "-"),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (timeline column alignment)
          SizedBox(
            width: 32.w,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.primary.withAlpha(40),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Icon(
                    Icons.near_me_outlined,
                    size: 14.sp,
                    color: context.onSurfaceVariant.withAlpha(120),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.primary.withAlpha(40),
                  ),
                ),
              ],
            ),
          ),
          16.w.horizontalSpace,
          // Right Column (Travel mode cards)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: context.onSurfaceVariant.withAlpha(8),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: modes.map((mode) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.icon,
                        size: 16.sp,
                        color: context.onSurfaceVariant.withAlpha(150),
                      ),
                      4.h.verticalSpace,
                      Text(
                        mode.duration,
                        style: context.text.labelSmall?.copyWith(
                          fontSize: 9.sp,
                          color: context.onSurfaceVariant.withAlpha(150),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    TripActivityModel activity,
    bool isFirst,
    bool isLast,
  ) {
    final categoryIcon = _getCategoryIcon(activity.category);
    final rating = 4.0 + (activity.name.hashCode.abs() % 10) / 10.0;
    final reviews = 100 + (activity.name.hashCode.abs() % 9000);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 32.w,
            child: Column(
              children: [
                // Top line segment
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : context.primary.withAlpha(40),
                  ),
                ),
                // Category Icon
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: context.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 14.sp,
                    color: context.primary,
                  ),
                ),
                // Bottom line segment
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : context.primary.withAlpha(40),
                  ),
                ),
              ],
            ),
          ),
          16.w.horizontalSpace,
          // Content Card
          Expanded(
            child: InkWell(
              onTap: () => _showActivityDetails(activity),
              borderRadius: BorderRadius.circular(16.r),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: context.borderColor.withAlpha(30)),
                ),
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: CachedNetworkImage(
                        imageUrl: (activity.imageUrl != null && activity.imageUrl!.isNotEmpty)
                            ? activity.imageUrl!
                            : "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600",
                        height: 150.h,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 150.h,
                          color: context.shimmerBase,
                          child: Icon(
                            Icons.image_rounded,
                            size: 48.sp,
                            color: context.onSurfaceVariant.withAlpha(60),
                          ),
                        ),
                      ),
                    ),
                    // Details Section
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  activity.name,
                                  style: context.text.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: context.colors.error,
                                  size: 18.sp,
                                ),
                                onPressed: () => _confirmDelete(context, activity),
                              ),
                            ],
                          ),
                          6.h.verticalSpace,
                          // Stars & Reviews Row
                          Row(
                            children: [
                              ...List.generate(5, (starIndex) {
                                final starRating = starIndex + 1;
                                if (rating >= starRating) {
                                  return Icon(Icons.star, color: Colors.amber, size: 12.sp);
                                } else if (rating >= starRating - 0.5) {
                                  return Icon(Icons.star_half, color: Colors.amber, size: 12.sp);
                                } else {
                                  return Icon(Icons.star_border, color: Colors.amber, size: 12.sp);
                                }
                              }),
                              6.w.horizontalSpace,
                              Text(
                                "(${rating.toStringAsFixed(1)})",
                                style: context.text.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              4.w.horizontalSpace,
                              Text(
                                "$reviews reviews",
                                style: context.text.labelSmall?.copyWith(
                                  color: context.onSurfaceVariant.withAlpha(120),
                                ),
                              ),
                            ],
                          ),
                          8.h.verticalSpace,
                          // Operating Hours
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                size: 14.sp,
                                color: context.onSurfaceVariant.withAlpha(150),
                              ),
                              6.w.horizontalSpace,
                              Text(
                                "${_formatTime(activity.startDatetime)} - ${_formatTime(activity.endDatetime)}",
                                style: context.text.bodySmall?.copyWith(
                                  color: context.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          6.h.verticalSpace,
                          // Price
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on_outlined,
                                size: 14.sp,
                                color: context.onSurfaceVariant.withAlpha(150),
                              ),
                              6.w.horizontalSpace,
                              Text(
                                activity.cost > 0
                                    ? "\$${activity.cost.toStringAsFixed(2)}"
                                    : "Free",
                                style: context.text.bodySmall?.copyWith(
                                  color: context.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          8.h.verticalSpace,
                          // View on Google Maps
                          InkWell(
                            onTap: () => _launchMaps(activity.name),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14.sp,
                                  color: Colors.teal,
                                ),
                                4.w.horizontalSpace,
                                Text(
                                  "View on Google Maps",
                                  style: context.text.bodySmall?.copyWith(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildActivitiesTimeline(
    BuildContext context,
    List<TripActivityModel> activities,
  ) {
    if (activities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40.w),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.map_outlined,
              size: 48.sp,
              color: context.onSurfaceVariant.withAlpha(80),
            ),
            12.h.verticalSpace,
            Text(
              "No activities planned for this day.",
              style: context.text.bodyMedium?.copyWith(
                color: context.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            4.h.verticalSpace,
            Text(
              "Search and add places above to start building your itinerary!",
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.onSurfaceVariant.withAlpha(120),
              ),
            ),
          ],
        ),
      );
    }

    final List<Widget> children = [];
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      final isFirst = i == 0;
      final isLast = i == activities.length - 1;

      children.add(
        _buildActivityItem(
          context,
          activity,
          isFirst,
          isLast,
        ),
      );

      if (!isLast) {
        children.add(
          _buildTravelTransitionRow(
            context,
            activity,
            activities[i + 1],
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: children,
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
        return Icons.directions_car;
      case 3:
        return Icons.hotel;
      case 4:
        return Icons.spa;
      case 5:
        return Icons.shopping_bag;
      case 6:
      default:
        return Icons.location_on_outlined;
    }
  }

  Future<void> _showActivityDetails(TripActivityModel baseModel) async {
    AppToast.success("Loading activity details...");
    TripActivityModel? latestModel;
    try {
      final apiService = sl<ApiService>();
      final res = await apiService.get<dynamic>(
        "/TripActivity/${baseModel.id}",
        fromJson: (d) => d,
      );
      if (res is Success && res.data != null) {
        latestModel = TripActivityModel.fromJson(res.data["data"] ?? res.data);
      }
    } catch (e) {
      debugPrint("Failed to load activity details: $e");
    }

    final model = latestModel ?? baseModel;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(model.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (model.notes != null && model.notes!.isNotEmpty) ...[
                  Text(
                    "Details / Notes:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(model.notes!),
                  12.h.verticalSpace,
                ],
                Text(
                  "Start Time:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                Text("${model.startDatetime.toLocal()}"),
                12.h.verticalSpace,
                if (model.cost > 0) ...[
                  Text(
                    "Estimated Cost:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text("\$${model.cost}"),
                  12.h.verticalSpace,
                ],
                if (model.bookingReference != null &&
                    model.bookingReference!.isNotEmpty) ...[
                  Text(
                    "Booking Reference:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(model.bookingReference!),
                  12.h.verticalSpace,
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    return Container(
      color: context.surface,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attachment, color: context.primary, size: 20.sp),
                  8.w.horizontalSpace,
                  Text(
                    "Trip Documents",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (_uploadingAttachment)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.add_a_photo_outlined,
                    color: context.primary,
                    size: 22.sp,
                  ),
                  onPressed: _pickAndUploadAttachment,
                ),
            ],
          ),
          12.h.verticalSpace,
          if (_attachments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                "No tickets or vouchers attached yet. Tap the camera icon to save ticket snaps.",
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant.withAlpha(120),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _attachments.map((blobPath) {
                final displayFilename = blobPath
                    .split('/')
                    .last
                    .replaceAll(RegExp(r'^\d+_'), '');
                return InputChip(
                  avatar: Icon(
                    Icons.description_outlined,
                    size: 16.sp,
                    color: context.primary,
                  ),
                  label: Text(
                    displayFilename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  onPressed: () => _downloadAndOpenAttachment(blobPath),
                  onDeleted: () async {
                    setState(() {
                      _attachments.remove(blobPath);
                    });
                    await _saveAttachments();
                    AppToast.success("Attachment removed");
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
