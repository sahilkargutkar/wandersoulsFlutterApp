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
import 'package:dio/dio.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
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
  bool _loadingTrip = false;
  int _selectedDayIndex = 0;
  List<TripActivityModel> _activities = [];
  bool _loadingActivities = false;

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
    final blobPath = "attachments/${_tripState.id}_${DateTime.now().millisecondsSinceEpoch}.$extension";

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
    setState(() => _loadingTrip = true);
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
    } finally {
      setState(() => _loadingTrip = false);
    }
  }

  void _showEditTripDialog() {
    final nameController = TextEditingController(text: _tripState.name);
    final descController = TextEditingController(text: _tripState.description);
    DateTime start = _tripState.startDate ?? DateTime.now();
    DateTime end = _tripState.endDate ?? DateTime.now().add(const Duration(days: 3));

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
                      decoration: const InputDecoration(labelText: "Description"),
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
                          "currency": "USD"
                        }
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
    final end = _tripState.endDate ?? DateTime.now().add(const Duration(days: 3));

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
          "activities": 0
        }
      },
      "tripName": _tripState.name,
      "description": ""
    };

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.aiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ));

      final response = await dio.post(
        ApiConstants.generateItinerary,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
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
      } else {
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
      "placeId": "ai_${DateTime.now().millisecondsSinceEpoch}",
      "dayId": "${_selectedDayIndex + 1}",
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
        "imageUrl": _getPlaceImageUrl(_getAiCategoryEnum(categoryStr), name)
      },
      "notes": desc
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
        "/TripActivity",
        fromJson: (json) => json as List<dynamic>,
      );

      if (result is Success<List<dynamic>>) {
        final List<TripActivityModel> all = result.data
            .map((item) => TripActivityModel.fromJson(item as Map<String, dynamic>))
            .toList();

        setState(() {
          // Filter locally by tripId and sort by startDatetime
          _activities = all.where((act) => act.tripId == _tripState.id).toList();
          _activities.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
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

    result.fold(
      (failure) => setState(() => _searchingLocations = false),
      (places) {
        if (_searchController.text.trim().isNotEmpty) {
          setState(() {
            _suggestions = places;
            _searchingLocations = false;
          });
        }
      },
    );
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
    if (types.contains("restaurant") || types.contains("food") || types.contains("cafe") || types.contains("bar")) {
      return 1; // Food
    }
    if (types.contains("transit_station") || types.contains("airport") || types.contains("subway_station") || types.contains("train_station") || types.contains("bus_station")) {
      return 2; // Transport
    }
    if (types.contains("lodging") || types.contains("hotel") || types.contains("accommodation")) {
      return 3; // Accommodation
    }
    if (types.contains("spa") || types.contains("beauty_salon") || types.contains("gym") || types.contains("physiotherapist")) {
      return 4; // Relaxation
    }
    if (types.contains("shopping_mall") || types.contains("store") || types.contains("clothing_store") || types.contains("supermarket")) {
      return 5; // Shopping
    }
    if (types.contains("attraction") || types.contains("museum") || types.contains("landmark") || types.contains("park") || types.contains("natural_feature")) {
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
      "placeId": suggestion.placeId.isNotEmpty ? suggestion.placeId : "place_${DateTime.now().millisecondsSinceEpoch}",
      "dayId": "${_selectedDayIndex + 1}",
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
        "imageUrl": _getPlaceImageUrl(cat, suggestion.name)
      },
      "notes": suggestion.description
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

  @override
  Widget build(BuildContext context) {
    // Filter activities for the selected day
    final dayActivities = _activities.where((act) => act.dayId == "${_selectedDayIndex + 1}").toList();

    // Map activities to MarkerData for the Google Map
    final List<MarkerData> markers = [];
    // To generate coordinates, we use dummy offsets or fallbacks since rating/address details are stored,
    // but in case lat/lng is not stored in activity details we can use the main destination lat/lng as base.
    // For locations suggestion API, the rating/lat/lng is populated. Let's map coordinates:
    for (var act in dayActivities) {
      // Typically activities from suggest locations have coordinates. Let's assume a default center if null.
      markers.add(MarkerData(
        id: act.id,
        title: act.name,
        lat: 22.5726 + (markers.length * 0.01), // dummy offset so they don't overlap if not provided
        lng: 88.3639 + (markers.length * 0.01),
      ));
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
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ))
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
                  style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
              final cost = act["estimatedCost"] != null ? "\$${act["estimatedCost"]}" : "Free";

              return Container(
                width: 200.w,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: context.borderColor.withAlpha(20),
                  ),
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
                          onTap: () => _addAiSuggestionToItinerary(act as Map<String, dynamic>),
                          child: Icon(Icons.add_circle, color: context.primary, size: 22.sp),
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
                child: Icon(Icons.image_rounded, size: 64.sp, color: context.onSurfaceVariant.withAlpha(60)),
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
                final date = (_tripState.startDate ?? DateTime.now()).add(Duration(days: index));
                final formattedDate = "${date.day}/${date.month}";

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? context.primary : context.mutedBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.primary.withAlpha(40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Day ${index + 1}",
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : context.onSurfaceVariant,
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
              hintText: "Search places to add to Day ${_selectedDayIndex + 1}...",
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                      child: Icon(Icons.place, color: context.primary, size: 18.sp),
                    ),
                    title: Text(
                      suggestion.name,
                      style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      suggestion.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: context.onSurfaceVariant),
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

  Widget _buildActivitiesTimeline(BuildContext context, List<TripActivityModel> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40.w),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 48.sp, color: context.onSurfaceVariant.withAlpha(80)),
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final categoryIcon = _getCategoryIcon(activity.category);
        final isLast = index == activities.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line & icon
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 16.sp,
                    color: context.primary,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80.h,
                    color: context.primary.withAlpha(40),
                  ),
              ],
            ),
            16.w.horizontalSpace,

            // Activity content card
            Expanded(
              child: InkWell(
                onTap: () => _showActivityDetails(activity),
                borderRadius: BorderRadius.circular(12.r),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(
                      color: context.borderColor.withAlpha(30),
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: 16.h),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.name,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                                6.h.verticalSpace,
                                Text(
                                  activity.notes!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: context.colors.error, size: 20.sp),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text("Delete Activity"),
                                content: Text("Are you sure you want to remove ${activity.name}?"),
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
                                    child: Text("Delete", style: TextStyle(color: context.colors.error)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(int category) {
    switch (category) {
      case 0:
        return Icons.museum;
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
        return Icons.place;
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
    } catch (_) {}

    final model = latestModel ?? baseModel;

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
                  Text("Details / Notes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  Text(model.notes!),
                  12.h.verticalSpace,
                ],
                Text("Start Time:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                Text("${model.startDatetime.toLocal()}"),
                12.h.verticalSpace,
                if (model.cost > 0) ...[
                  Text("Estimated Cost:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  Text("\$${model.cost}"),
                  12.h.verticalSpace,
                ],
                if (model.bookingReference != null && model.bookingReference!.isNotEmpty) ...[
                  Text("Booking Reference:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
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
                  icon: Icon(Icons.add_a_photo_outlined, color: context.primary, size: 22.sp),
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
                final displayFilename = blobPath.split('/').last.replaceAll(RegExp(r'^\d+_'), '');
                return InputChip(
                  avatar: Icon(Icons.description_outlined, size: 16.sp, color: context.primary),
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
