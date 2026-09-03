import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
import 'package:wonder_souls/src/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:wonder_souls/src/config/utils/trip_image_helper.dart';

const Map<String, Map<String, double>> _cityCoordinatesFallback = {
  'tokyo': {'lat': 35.6762, 'lng': 139.6503},
  'osaka': {'lat': 34.6937, 'lng': 135.5023},
  'japan': {'lat': 35.6762, 'lng': 139.6503},
  'paris': {'lat': 48.8566, 'lng': 2.3522},
  'nice': {'lat': 43.7102, 'lng': 7.2620},
  'france': {'lat': 48.8566, 'lng': 2.3522},
  'london': {'lat': 51.5074, 'lng': -0.1278},
  'uk': {'lat': 51.5074, 'lng': -0.1278},
  'united kingdom': {'lat': 51.5074, 'lng': -0.1278},
  'rome': {'lat': 41.9028, 'lng': 12.4964},
  'milan': {'lat': 45.4642, 'lng': 9.1900},
  'italy': {'lat': 41.9028, 'lng': 12.4964},
  'new york': {'lat': 40.7128, 'lng': -74.0060},
  'usa': {'lat': 40.7128, 'lng': -74.0060},
  'united states': {'lat': 40.7128, 'lng': -74.0060},
  'sydney': {'lat': -33.8688, 'lng': 151.2093},
  'australia': {'lat': -33.8688, 'lng': 151.2093},
  'delhi': {'lat': 28.6139, 'lng': 77.2090},
  'mumbai': {'lat': 19.0760, 'lng': 72.8777},
  'kolkata': {'lat': 22.5726, 'lng': 88.3639},
  'india': {'lat': 28.6139, 'lng': 77.2090},
};

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
  bool _hasTriggeredScheduledNotification = false;

  double? _destinationLat;
  double? _destinationLng;
  String? _destinationPlaceId;
  final Map<String, Map<String, double>> _resolvedActivityCoords = {};

  // Search & suggestions
  final TextEditingController _searchController = TextEditingController();
  List<PlaceModel> _suggestions = [];
  bool _searchingLocations = false;
  final FocusNode _searchFocusNode = FocusNode();

  // AI Suggestions
  List<dynamic> _aiSuggestions = [];
  bool _loadingAiSuggestions = false;
  bool _showAiSuggestions = false;

  List<String> _attachments = [];
  bool _uploadingAttachment = false;

  @override
  void initState() {
    super.initState();
    _tripState = widget.trip;
    _resolveTripCoverPhoto();
    _fetchTripDetails();
    _fetchActivities();
    _loadAttachments();
    _searchController.addListener(_onSearchChanged);
    _fetchDestinationCoordinates();
    _resolveDayActivityCoordinates();
  }

  void _resolveTripCoverPhoto() {
    final destKey = _tripState.mainDestination.trim().isNotEmpty
        ? _tripState.mainDestination.trim()
        : _tripState.name.trim();
    if (destKey.isEmpty) return;

    final cached = TripImageHelper.getCachedPhoto(destKey);
    if (cached != null && cached != _tripState.imageUrl) {
      if (mounted) {
        setState(() {
          _tripState = _tripState.copyWith(imageUrl: cached);
        });
      }
      return;
    }

    if (!_tripState.imageUrl.contains("places.googleapis.com") &&
        !_tripState.imageUrl.contains("maps.googleapis.com")) {
      TripImageHelper.resolvePhoto(destKey).then((uri) {
        if (uri != null && mounted) {
          setState(() {
            _tripState = _tripState.copyWith(imageUrl: uri);
          });
        }
      });
    }
  }

  Future<void> _resolveDestinationPlaceId(String city) async {
    try {
      final googlePlacesService = GooglePlacesNewService();
      final placeIdResult = await googlePlacesService.searchPlaceId(city);
      if (placeIdResult != null && mounted) {
        setState(() {
          _destinationPlaceId = placeIdResult;
        });
      }
    } catch (e) {
      debugPrint("Error resolving destination place ID: $e");
    }
  }

  Future<void> _fetchDestinationCoordinates() async {
    final city = _tripState.mainDestination.trim().toLowerCase();
    if (city.isEmpty) {
      AppToast.error("Destination name is empty!");
      return;
    }

    // 1. Try local fallback first
    for (final entry in _cityCoordinatesFallback.entries) {
      if (city.contains(entry.key)) {
        AppToast.success("Location matched fallback: ${entry.key}");
        if (mounted) {
          setState(() {
            _destinationLat = entry.value['lat'];
            _destinationLng = entry.value['lng'];
          });
        }
        _resolveDestinationPlaceId(city);
        return;
      }
    }

    // 2. Query backend Locations API
    try {
      final apiService = sl<ApiService>();
      final result = await apiService.getLocations(1, 5, _tripState.mainDestination);
      bool resolved = false;
      result.fold(
        (failure) => debugPrint("Failed to fetch location from backend: ${failure.message}"),
        (places) {
          if (places.isNotEmpty) {
            for (final p in places) {
              if (p.latitude != null && p.longitude != null) {
                AppToast.success("Resolved from backend: ${p.name}");
                if (mounted) {
                  setState(() {
                    _destinationLat = p.latitude;
                    _destinationLng = p.longitude;
                    _destinationPlaceId = p.placeId;
                  });
                }
                resolved = true;
                break;
              }
            }
          }
        },
      );
      if (resolved) return;
    } catch (e) {
      debugPrint("Error fetching destination from backend API: $e");
    }

    // 3. Query Google Maps Geocoding API if not found in fallback or backend API
    try {
      final mapsService = sl<GoogleMapsApiService>();
      final result = await mapsService.getLatLngFromAddress(_tripState.mainDestination);
      result.fold(
        (failure) => AppToast.error("Resolve failed: ${failure.message}"),
        (coords) {
          AppToast.success("Resolved via Google: ${coords['lat']}, ${coords['lng']}");
          if (mounted) {
            setState(() {
              _destinationLat = coords['lat'];
              _destinationLng = coords['lng'];
            });
          }
          _resolveDestinationPlaceId(_tripState.mainDestination);
        },
      );
    } catch (e) {
      AppToast.error("Error geocoding: $e");
    }
  }

  Future<void> _resolveDayActivityCoordinates() async {
    final dayActivities = _activities
        .where((act) => act.dayId == "${_selectedDayIndex + 1}")
        .toList();

    final mapsService = sl<GoogleMapsApiService>();

    for (final act in dayActivities) {
      if (_resolvedActivityCoords.containsKey(act.id)) continue;

      final query = "${act.name}, ${_tripState.mainDestination}";

      try {
        final result = await mapsService.getLatLngFromAddress(query);
        result.fold(
          (failure) => debugPrint("Failed to resolve activity '${act.name}': ${failure.message}"),
          (coords) {
            if (mounted) {
              setState(() {
                _resolvedActivityCoords[act.id] = coords;
              });
            }
          },
        );
      } catch (e) {
        debugPrint("Error resolving activity: $e");
      }
    }
  }

  Future<void> _loadAttachments() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("attachments_${_tripState.id}");
    if (list != null && mounted) {
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
        if (mounted) {
          setState(() {
            _attachments.add(blobPath);
            _uploadingAttachment = false;
          });
        }
        await _saveAttachments();
        AppToast.success("Attachment uploaded successfully!");
      } else {
        if (mounted) {
          setState(() => _uploadingAttachment = false);
        }
        AppToast.error("Failed to upload attachment");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAttachment = false);
      }
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
      if (res is Success && res.data != null) {
        final Map<String, dynamic> dataMap;
        if (res.data is Map<String, dynamic> && res.data.containsKey("data")) {
          dataMap = res.data["data"] as Map<String, dynamic>;
        } else if (res.data is Map<String, dynamic>) {
          dataMap = res.data as Map<String, dynamic>;
        } else {
          return;
        }

        final updatedTrip = TripData.fromJson(dataMap);
        final destKey = updatedTrip.mainDestination.trim().isNotEmpty
            ? updatedTrip.mainDestination.trim()
            : updatedTrip.name.trim();
        final cached = TripImageHelper.getCachedPhoto(destKey);

        setState(() {
          if (cached != null) {
            _tripState = updatedTrip.copyWith(imageUrl: cached);
          } else if (_tripState.imageUrl.contains("places.googleapis.com") ||
              _tripState.imageUrl.contains("maps.googleapis.com")) {
            _tripState = updatedTrip.copyWith(imageUrl: _tripState.imageUrl);
          } else {
            _tripState = updatedTrip;
          }
        });
        _fetchDestinationCoordinates();
      }
    } catch (e) {
      debugPrint("Error fetching trip details: $e");
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.onSurface.withAlpha(200),
          ),
        ),
        8.h.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.mutedBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
        12.h.verticalSpace,
      ],
    );
  }

  void _confirmDeleteTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Delete Trip"),
        content: const Text(
          "Are you sure you want to delete this trip? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx); // close confirm dialog
              Navigator.pop(context); // close edit dialog

              AppToast.success("Deleting trip...");
              try {
                final apiService = sl<ApiService>();
                final res = await apiService.delete<dynamic>(
                  "/Trips/${_tripState.id}",
                  fromJson: (d) => d,
                );
                if (res is Success) {
                  AppToast.success("Trip deleted successfully!");
                  if (context.mounted) {
                    Navigator.pop(context); // return to My Trips screen
                  }
                } else {
                  AppToast.error("Failed to delete trip");
                }
              } catch (e) {
                AppToast.error("Error deleting trip: $e");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showEditTripDialog() {
    final nameController = TextEditingController(text: _tripState.name);
    final descController =
        TextEditingController(text: _tripState.description);
    final budgetController = TextEditingController(
      text: _tripState.totalBudget > 0
          ? _tripState.totalBudget.toStringAsFixed(0)
          : "2000",
    );
    DateTime start = _tripState.startDate ?? DateTime.now();
    DateTime end =
        _tripState.endDate ?? DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              backgroundColor: context.surface,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Edit Trip Details",
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18.sp,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      16.h.verticalSpace,

                      _buildFormField(controller: nameController, label: "Trip Name"),
                      _buildFormField(controller: descController, label: "Description", maxLines: 3),
                      _buildFormField(
                        controller: budgetController,
                        label: "Total Budget (${_tripState.currency.isNotEmpty ? _tripState.currency : 'USD'})",
                        keyboardType: TextInputType.number,
                      ),

                      Text(
                        "Trip Dates",
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.onSurface.withAlpha(200),
                        ),
                      ),
                      8.h.verticalSpace,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.borderColor.withAlpha(40)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
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
                              child: Text(
                                "Start: ${start.day}/${start.month}",
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.primary,
                                ),
                              ),
                            ),
                          ),
                          8.w.horizontalSpace,
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.borderColor.withAlpha(40)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
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
                              child: Text(
                                "End: ${end.day}/${end.month}",
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      24.h.verticalSpace,

                      // Actions Row (Delete & Save)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            ),
                            onPressed: () => _confirmDeleteTrip(context),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text(
                              "Delete",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primary,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;
                              Navigator.pop(context);

                              AppToast.success("Updating trip...");
                              try {
                                final apiService = sl<ApiService>();
                                final currentUser = sl<AuthLocalDataSource>().getUser();
                                final ownerId = currentUser?.id ?? "";
                                final ownerName = currentUser?.name ?? "";

                                final enteredBudget = double.tryParse(budgetController.text.trim()) ?? _tripState.totalBudget;
                                final totalBudgetVal = enteredBudget > 0 ? enteredBudget : 2000.0;

                                final payload = {
                                  if (_tripState.id.isNotEmpty) "id": _tripState.id,
                                  if (_tripState.id.isNotEmpty) "tripId": _tripState.id,
                                  if (ownerId.isNotEmpty) "ownerId": ownerId,
                                  if (ownerId.isNotEmpty) "OwnerId": ownerId,
                                  if (ownerName.isNotEmpty) "ownerName": ownerName,
                                  if (ownerName.isNotEmpty) "OwnerName": ownerName,
                                  "name": name,
                                  "description": descController.text.trim(),
                                  "startDate": start.toUtc().toIso8601String(),
                                  "endDate": end.toUtc().toIso8601String(),
                                  "mainDestination": _tripState.mainDestination,
                                  "whoIsGoing": _tripState.tripType.toLowerCase(),
                                  "isPublic": false,
                                  "travelTastes": _tripState.travelTastes,
                                  "imageUrl": _tripState.imageUrl,
                                  "image": _tripState.imageUrl,
                                  "coverImage": _tripState.imageUrl,
                                  "budget": {
                                    "budgetType": _tripState.category.toLowerCase(),
                                    "totalEstimated": totalBudgetVal,
                                    "currency": _tripState.currency.isNotEmpty
                                        ? _tripState.currency
                                        : "USD",
                                    "byCategory": {
                                      "transportation": _tripState.transportBudget > 0
                                          ? _tripState.transportBudget
                                          : (totalBudgetVal * 0.25),
                                      "accommodation": _tripState.accommodationBudget > 0
                                          ? _tripState.accommodationBudget
                                          : (totalBudgetVal * 0.35),
                                      "food": _tripState.foodBudget > 0
                                          ? _tripState.foodBudget
                                          : (totalBudgetVal * 0.25),
                                      "activities": _tripState.activitiesBudget > 0
                                          ? _tripState.activitiesBudget
                                          : (totalBudgetVal * 0.15),
                                      "others": 0.0,
                                    },
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
                                } else if (res is Failure) {
                                  AppToast.error(res.message);
                                } else {
                                  AppToast.error("Failed to update trip details");
                                }
                              } catch (e) {
                                AppToast.error("Error updating trip: $e");
                              }
                            },
                            child: Text(
                              "Save",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  List<Map<String, dynamic>> _generateFallbackAiSuggestions(
    String destination,
    List<String> tastes,
  ) {
    final destLower = destination.trim().toLowerCase();

    // 1. Oman / Muscat
    if (destLower.contains("muscat") ||
        destLower.contains("oman") ||
        destLower.contains("salalah") ||
        destLower.contains("nizwa")) {
      return [
        {
          "name": "Sultan Qaboos Grand Mosque",
          "category": "Culture",
          "description":
              "Marvel at stunning Islamic architecture, hand-woven Persian carpet, and Swarovski crystal chandelier.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips":
              "Modest dress required (arms & legs covered, headscarf for women). Best visited before 11 AM.",
        },
        {
          "name": "Mutrah Souq & Corniche",
          "category": "Shopping",
          "description":
              "Wander vibrant alleyways filled with frankincense, silver jewelry, spices, and waterfront strolls.",
          "estimatedCost": 0,
          "duration": "2.5h",
          "tips":
              "Great for evening sunset walks and authentic Omani souvenirs.",
        },
        {
          "name": "Bimmah Sinkhole & Wadi Shab",
          "category": "Adventure",
          "description":
              "Swim in turquoise limestone sinkhole and hike through dramatic wadi canyons with hidden waterfalls.",
          "estimatedCost": 15,
          "duration": "4h",
          "tips": "Bring sturdy water shoes and waterproof phone pouch.",
        },
        {
          "name": "Royal Opera House Muscat",
          "category": "Landmark",
          "description":
              "Experience breathtaking modern Omani marble architecture and world-class performances.",
          "estimatedCost": 10,
          "duration": "1.5h",
          "tips":
              "Check performance schedule in advance or take the morning architectural tour.",
        },
        {
          "name": "Bait Al Zubair Museum",
          "category": "Culture",
          "description":
              "Discover Omani history, weapons, khanjars (daggers), and traditional costumes.",
          "estimatedCost": 8,
          "duration": "1.5h",
          "tips": "Located in Old Muscat near Al Alam Palace.",
        },
        {
          "name": "Al Alam Palace & Portuguese Forts",
          "category": "Landmark",
          "description":
              "Ceremonial palace of Sultan Haitham flanked by historic 16th-century Al Jalali & Al Mirani forts.",
          "estimatedCost": 0,
          "duration": "1h",
          "tips": "Palace exterior is open for stunning photography.",
        },
      ];
    }

    // 2. Paris / France
    if (destLower.contains("paris") || destLower.contains("france")) {
      return [
        {
          "name": "Eiffel Tower & Champ de Mars",
          "category": "Landmark",
          "description":
              "Iconic iron lattice tower with panoramic views over Paris and evening sparkling light show.",
          "estimatedCost": 25,
          "duration": "2.5h",
          "tips": "Book summit tickets online in advance to skip long lines.",
        },
        {
          "name": "Louvre Museum",
          "category": "Culture",
          "description":
              "World's largest art museum housing the Mona Lisa, Venus de Milo, and Winged Victory.",
          "estimatedCost": 20,
          "duration": "3h",
          "tips":
              "Enter through Carrousel du Louvre entrance for shorter lines.",
        },
        {
          "name": "Montmartre & Sacré-Cœur",
          "category": "Culture",
          "description":
              "Bohemian hilltop neighborhood with cobbled alleys, artist cafes, and panoramic dome views.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips": "Visit Place du Tertre for live portrait artists.",
        },
        {
          "name": "Seine River Sunset Cruise",
          "category": "Relaxation",
          "description":
              "Glide past Notre-Dame, Musée d'Orsay, and historic illuminated bridges.",
          "estimatedCost": 18,
          "duration": "1h",
          "tips": "Depart around twilight for sunset and city illuminations.",
        },
      ];
    }

    // 3. Tokyo / Japan
    if (destLower.contains("tokyo") || destLower.contains("japan")) {
      return [
        {
          "name": "Senso-ji Temple & Asakusa",
          "category": "Culture",
          "description":
              "Tokyo's oldest Buddhist temple featuring Nakamise-dori traditional market street.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips":
              "Try warm melon pan and dango sweets along Nakamise street.",
        },
        {
          "name": "Shibuya Crossing & Hachiko Statue",
          "category": "Landmark",
          "description":
              "The world's most famous scramble crossing surrounded by giant video screens.",
          "estimatedCost": 0,
          "duration": "1h",
          "tips":
              "View the crossing from Shibuya Sky or Starbucks above for great photos.",
        },
        {
          "name": "Meiji Shrine & Yoyogi Park",
          "category": "Nature",
          "description":
              "Peaceful evergreen forest shrine dedicated to Emperor Meiji in the heart of the city.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips": "Wash hands at the temizuya water pavilion before entering.",
        },
        {
          "name": "teamLab Planets TOKYO",
          "category": "Entertainment",
          "description":
              "Immersive digital art museum where you walk through water and infinite crystal universes.",
          "estimatedCost": 32,
          "duration": "2.5h",
          "tips":
              "Wear pants that can be rolled above knees as you walk in water.",
        },
      ];
    }

    // 4. Dubai / UAE
    if (destLower.contains("dubai") || destLower.contains("uae")) {
      return [
        {
          "name": "Burj Khalifa Observation Deck",
          "category": "Landmark",
          "description":
              "Soar up to Level 124/125 for unmatched 360-degree views of Dubai's skyline and desert.",
          "estimatedCost": 45,
          "duration": "2h",
          "tips":
              "Sunset prime hours (5:00 PM - 6:30 PM) offer the best lighting.",
        },
        {
          "name": "Dubai Mall & Fountain Show",
          "category": "Entertainment",
          "description":
              "World's largest shopping destination with indoor aquarium and synchronized dancing fountain.",
          "estimatedCost": 0,
          "duration": "2.5h",
          "tips": "Fountain shows start every 30 minutes in the evening.",
        },
        {
          "name": "Desert Safari & Bedouin Camp",
          "category": "Adventure",
          "description":
              "Exciting 4x4 dune bashing, sandboarding, camel rides, and BBQ dinner under stars.",
          "estimatedCost": 55,
          "duration": "5h",
          "tips":
              "Wear comfortable shoes and light layers for cooler desert night temperatures.",
        },
        {
          "name": "Old Dubai & Gold Souk Abra Ride",
          "category": "Culture",
          "description":
              "Traditional 1 AED wooden boat ride across Dubai Creek connecting Deira spice & gold souks.",
          "estimatedCost": 5,
          "duration": "2h",
          "tips": "Carry cash for the traditional Abra boat crossing.",
        },
      ];
    }

    // 5. London / UK
    if (destLower.contains("london") ||
        destLower.contains("uk") ||
        destLower.contains("england")) {
      return [
        {
          "name": "British Museum & Rosetta Stone",
          "category": "Culture",
          "description":
              "World-famous museum dedicated to human history, art, and ancient Egyptian artifacts.",
          "estimatedCost": 0,
          "duration": "3h",
          "tips": "Admission is free! Pre-book timed entry ticket online.",
        },
        {
          "name": "Tower Bridge & Tower of London",
          "category": "Landmark",
          "description":
              "Historic royal fortress and castle housing the Crown Jewels with iconic bridge walk.",
          "estimatedCost": 35,
          "duration": "2.5h",
          "tips": "Join a Yeoman Warder (Beefeater) tour included with ticket.",
        },
        {
          "name": "Big Ben & Westminster Abbey",
          "category": "Landmark",
          "description":
              "Iconic Elizabeth Tower clock and coronation church of British monarchs since 1066.",
          "estimatedCost": 0,
          "duration": "1.5h",
          "tips": "Best photo angle is from across Westminster Bridge.",
        },
      ];
    }

    // 6. Generic / Any Destination
    final capDest = destination.isNotEmpty
        ? "${destination[0].toUpperCase()}${destination.substring(1)}"
        : "Destination";

    return [
      {
        "name": "$capDest Historic Old Town & Heritage Walk",
        "category": "Culture",
        "description":
            "Explore historic plazas, ancient architecture, local artisan shops, and hidden courtyards.",
        "estimatedCost": 0,
        "duration": "2h",
        "tips":
            "Best explored on foot in the morning when streets are lively and quiet.",
      },
      {
        "name": "Local Culinary & Street Food Tasting",
        "category": "Food",
        "description":
            "Sample authentic regional delicacies, local specialty dishes, and street food markets.",
        "estimatedCost": 20,
        "duration": "2h",
        "tips":
            "Ask locals for their favorite neighborhood stalls for the most authentic flavor.",
      },
      {
        "name": "$capDest Panoramic Viewpoint & Sunset Spot",
        "category": "Nature",
        "description":
            "Catch panoramic sunset views overlooking $capDest and surrounding landscape.",
        "estimatedCost": 0,
        "duration": "1.5h",
        "tips":
            "Arrive 30 minutes before sunset for the best lighting and photography.",
      },
      {
        "name": "$capDest Central Market & Crafts Fair",
        "category": "Shopping",
        "description":
            "Browse authentic handicrafts, local spices, handmade souvenirs, and fresh regional produce.",
        "estimatedCost": 0,
        "duration": "2h",
        "tips":
            "Friendly bargaining is often customary at open-air market stalls.",
      },
      {
        "name": "$capDest Cultural Museum & Art Gallery",
        "category": "Culture",
        "description":
            "Immerse yourself in regional history, contemporary arts, and cultural exhibitions.",
        "estimatedCost": 12,
        "duration": "2h",
        "tips": "Audio guides provide rich context for the key exhibits.",
      },
    ];
  }

  Future<void> _fetchAiSuggestions() async {
    if (mounted) {
      setState(() {
        _loadingAiSuggestions = true;
      });
    }

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

    List<dynamic> suggestions = [];

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
        for (var day in days) {
          final List<dynamic> acts = day["activities"] ?? [];
          suggestions.addAll(acts);
        }
      }
    } catch (e) {
      debugPrint("Live AI suggestion service not reachable: $e");
    }

    // If live AI suggestions were empty or service unavailable, seamlessly use curated destination suggestions!
    if (suggestions.isEmpty) {
      suggestions = _generateFallbackAiSuggestions(
        _tripState.mainDestination,
        _tripState.travelTastes,
      );
    }

    if (mounted) {
      setState(() {
        _aiSuggestions = suggestions;
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
      final result = await apiService.get<dynamic>(
        "/TripActivity?TripId=${_tripState.id}",
        fromJson: (json) => json,
      );

      if (result is Success<dynamic> && result.data != null) {
        final dynamic rawData = result.data;
        final List<dynamic> list;
        if (rawData is Map<String, dynamic> && rawData.containsKey("data")) {
          list = rawData["data"] as List<dynamic>;
        } else if (rawData is List<dynamic>) {
          list = rawData;
        } else {
          list = [];
        }

        final start = _tripState.startDate ?? DateTime.now();
        final List<TripActivityModel> all = list
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

        if (mounted) {
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
        }
        _resolveDayActivityCoordinates();
 
        // Trigger scheduled morning reminder notification automatically on load
        if (!_hasTriggeredScheduledNotification && _activities.isNotEmpty) {
          _hasTriggeredScheduledNotification = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _showInAppNotification(
                title: "Ready for today?",
                message:
                    "Your first experience starts in 30 minutes. Check your itinerary and get ready for an amazing day.",
                cta: "View Today's Plan",
                icon: Icons.wb_sunny_outlined,
                iconColor: Colors.amber,
                onAccept: () {
                  AppToast.success("Enjoy your day!");
                },
              );
            }
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingActivities = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching activities: $e");
      if (mounted) {
        setState(() => _loadingActivities = false);
      }
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

    result.fold((failure) {
      if (mounted) {
        setState(() => _searchingLocations = false);
      }
    }, (
      places,
    ) {
      if (_searchController.text.trim().isNotEmpty && mounted) {
        setState(() {
          _suggestions = places;
          _searchingLocations = false;
        });
      }
    });
  }

  String _getPlaceImageUrl(int category, String name) {
    return TripActivityModel.getFallbackImage(category, name);
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

  /*
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
  */



  @override
  Widget build(BuildContext context) {
    // Filter activities for the selected day
    final dayActivities = _activities
        .where((act) => act.dayId == "${_selectedDayIndex + 1}")
        .toList();

    // Map activities to MarkerData for the Google Map
    final List<MarkerData> markers = [];
    final double baseLat = _destinationLat ?? 22.5726;
    final double baseLng = _destinationLng ?? 88.3639;

    // Highlight the main destination with a location marker
    markers.add(
      MarkerData(
        id: "destination_${_tripState.id}",
        title: _tripState.mainDestination,
        lat: baseLat,
        lng: baseLng,
      ),
    );

    // Check if any event has a placeId different from the destination's placeId
    bool hasDifferentPlaceId = false;
    if (_destinationPlaceId != null && _destinationPlaceId!.isNotEmpty) {
      final normalizedDestPlaceId = convertToMongoObjectId(_destinationPlaceId!);
      for (var act in dayActivities) {
        if (act.placeId.isNotEmpty) {
          final normalizedActPlaceId = convertToMongoObjectId(act.placeId);
          if (normalizedActPlaceId != normalizedDestPlaceId) {
            hasDifferentPlaceId = true;
            break;
          }
        }
      }
    }

    if (!hasDifferentPlaceId) {
      // Add activity markers resolved dynamically or fallback offset
      for (var act in dayActivities) {
        if (_resolvedActivityCoords.containsKey(act.id)) {
          final coords = _resolvedActivityCoords[act.id]!;
          markers.add(
            MarkerData(
              id: act.id,
              title: act.name,
              lat: coords['lat']!,
              lng: coords['lng']!,
            ),
          );
        } else {
          markers.add(
            MarkerData(
              id: act.id,
              title: act.name,
              lat: baseLat + (markers.length * 0.005),
              lng: baseLng + (markers.length * 0.005),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: context.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchActivities();
          if (_showAiSuggestions) {
            await _fetchAiSuggestions();
          }
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
    if (!_showAiSuggestions) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.primary.withAlpha(12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.primary.withAlpha(30)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: context.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.primary,
                  size: 20.sp,
                ),
              ),
              12.w.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Smart Suggestions",
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    2.h.verticalSpace,
                    Text(
                      "Get personalized recommendations for ${_tripState.mainDestination}",
                      style: context.text.bodySmall?.copyWith(
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              8.w.horizontalSpace,
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _showAiSuggestions = true;
                  });
                  if (_aiSuggestions.isEmpty) {
                    _fetchAiSuggestions();
                  }
                },
                icon: Icon(Icons.auto_awesome, size: 14.sp),
                label: Text(
                  "Explore",
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingAiSuggestions) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.mutedBackground,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: context.primary, size: 18.sp),
                      8.w.horizontalSpace,
                      Text(
                        "Generating AI recommendations...",
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAiSuggestions = false;
                        _loadingAiSuggestions = false;
                      });
                    },
                    child: Icon(Icons.close_rounded, size: 18.sp, color: context.onSurfaceVariant),
                  ),
                ],
              ),
              12.h.verticalSpace,
              const LinearProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_aiSuggestions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.mutedBackground,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: context.onSurfaceVariant, size: 20.sp),
              12.w.horizontalSpace,
              Expanded(
                child: Text(
                  "No suggestions available.",
                  style: context.text.bodySmall?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: _fetchAiSuggestions,
                child: const Text("Retry"),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18.sp),
                onPressed: () {
                  setState(() => _showAiSuggestions = false);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: context.primary, size: 18.sp),
              8.w.horizontalSpace,
              Expanded(
                child: Text(
                  "AI Suggestions for ${_tripState.mainDestination}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _fetchAiSuggestions,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: context.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: context.primary,
                        size: 14.sp,
                      ),
                      4.w.horizontalSpace,
                      Text(
                        "Refresh",
                        style: TextStyle(
                          color: context.primary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              8.w.horizontalSpace,
              GestureDetector(
                onTap: () {
                  setState(() => _showAiSuggestions = false);
                },
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: context.onSurfaceVariant.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: context.onSurfaceVariant,
                    size: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            scrollDirection: Axis.horizontal,
            itemCount: _aiSuggestions.length,
            separatorBuilder: (context, index) => 12.w.horizontalSpace,
            itemBuilder: (context, index) {
              final act = _aiSuggestions[index];
              final name = act["name"] ?? "Activity";
              final category = act["category"] ?? "Landmark";
              final description = act["description"] ?? "";
              final cost = act["estimatedCost"] != null &&
                      (act["estimatedCost"] as num) > 0
                  ? "\$${act["estimatedCost"]}"
                  : "Free";
              final duration = act["duration"] ?? "1-2h";

              return Container(
                width: 220.w,
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
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        6.w.horizontalSpace,
                        GestureDetector(
                          onTap: () => _addAiSuggestionToItinerary(
                            act as Map<String, dynamic>,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: context.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: context.primary,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    4.h.verticalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: context.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      4.h.verticalSpace,
                      Expanded(
                        child: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            fontSize: 10.5.sp,
                            color: context.onSurfaceVariant.withAlpha(180),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cost,
                          style: context.text.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5.sp,
                            color: cost == "Free" ? Colors.green : context.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11.sp,
                              color: context.onSurfaceVariant.withAlpha(150),
                            ),
                            3.w.horizontalSpace,
                            Text(
                              duration,
                              style: context.text.bodySmall?.copyWith(
                                fontSize: 10.5.sp,
                                color: context.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        12.h.verticalSpace,
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
              Icons.account_balance_wallet_outlined,
              size: 20.sp,
              color: context.onSurface,
            ),
            onTap: () {
              context.push('/BudgetExpensesScreen', extra: _tripState);
            },
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
              Icons.bed_rounded,
              size: 20.sp,
              color: context.onSurface,
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TripBookingsSheet(
                  tripId: _tripState.id,
                  initialTabIndex: 0,
                ),
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
              imageUrl: TripImageHelper.getDisplayImageUrl(_tripState),
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
                        Expanded(
                          child: Text(
                            _tripState.mainDestination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyMedium?.copyWith(
                              color: context.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        6.w.horizontalSpace,
                        Text(
                          _tripState.flag,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        12.w.horizontalSpace,
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 14.sp,
                          color: context.onSurfaceVariant,
                        ),
                        4.w.horizontalSpace,
                        Text(
                          _tripState.dateRange,
                          style: context.text.bodySmall?.copyWith(
                            color: context.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
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
                  onTap: () {
                    setState(() => _selectedDayIndex = index);
                    _resolveDayActivityCoordinates();
                  },
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
                  side: BorderSide(color: context.borderColor.withAlpha(100)),
                ),
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section with delete overlay
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                          child: CachedNetworkImage(
                            imageUrl: activity.displayImageUrl,
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
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(6.w),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              onPressed: () => _confirmDelete(context, activity),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Details Section
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                if (model.confirmationDocumentUrl != null &&
                    model.confirmationDocumentUrl!.isNotEmpty) ...[
                  Text(
                    "Confirmation Document:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  4.h.verticalSpace,
                  InkWell(
                    onTap: () => _downloadAndOpenAttachment(model.confirmationDocumentUrl!),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: context.primary, size: 18.sp),
                        8.w.horizontalSpace,
                        Expanded(
                          child: Text(
                            model.confirmationDocumentUrl!.split('/').last,
                            style: TextStyle(
                              color: context.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.h.verticalSpace,
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary.withAlpha(20),
                      foregroundColor: context.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _uploadDocumentForActivity(model);
                    },
                    icon: Icon(Icons.upload_file_rounded, size: 18.sp),
                    label: const Text("Upload Document"),
                  ),
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

  Future<void> _uploadDocumentForActivity(TripActivityModel activity) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    AppToast.success("Uploading document...");
    final filename = pickedFile.path.split("/").last;
    final extension = filename.split(".").last;
    final blobPath =
        "attachments/${_tripState.id}_activity_${activity.id}_${DateTime.now().millisecondsSinceEpoch}.$extension";

    try {
      final apiService = sl<ApiService>();
      final uploadRes = await apiService.uploadFile(pickedFile.path, blobPath);

      if (uploadRes is Success<String>) {
        final updatedActivity = activity.copyWith(confirmationDocumentUrl: blobPath);
        final updateRes = await apiService.put<dynamic>(
          "/TripActivity/${activity.id}",
          data: updatedActivity.toJson(),
          fromJson: (d) => d,
        );

        if (updateRes is Success) {
          AppToast.success("Document uploaded and saved successfully!");
          _fetchActivities();
        } else {
          AppToast.error("Failed to update activity with document path");
        }
      } else {
        AppToast.error("Failed to upload document file");
      }
    } catch (e) {
      AppToast.error("Error uploading document: $e");
    }
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
