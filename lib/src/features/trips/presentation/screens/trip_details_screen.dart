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
import 'package:wonder_souls/src/config/utils/country_helper.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/itinerary_map_view.dart';

const Map<String, Map<String, double>> _cityCoordinatesFallback = {
  'phuket': {'lat': 7.8804, 'lng': 98.3923},
  'bangkok': {'lat': 13.7563, 'lng': 100.5018},
  'thailand': {'lat': 13.7563, 'lng': 100.5018},
  'tokyo': {'lat': 35.6762, 'lng': 139.6503},
  'osaka': {'lat': 34.6937, 'lng': 135.5023},
  'kyoto': {'lat': 35.0116, 'lng': 135.7681},
  'japan': {'lat': 35.6762, 'lng': 139.6503},
  'paris': {'lat': 48.8566, 'lng': 2.3522},
  'nice': {'lat': 43.7102, 'lng': 7.2620},
  'france': {'lat': 48.8566, 'lng': 2.3522},
  'london': {'lat': 51.5074, 'lng': -0.1278},
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
  'dubai': {'lat': 25.2048, 'lng': 55.2708},
  'muscat': {'lat': 23.5880, 'lng': 58.3829},
  'oman': {'lat': 23.5880, 'lng': 58.3829},
  'singapore': {'lat': 1.3521, 'lng': 103.8198},
  'bali': {'lat': -8.4095, 'lng': 115.1889},
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
  // ignore: unused_field
  List<PlaceModel> _suggestions = [];
  // ignore: unused_field
  bool _searchingLocations = false;
  final FocusNode _searchFocusNode = FocusNode();

  // AI Suggestions
  List<dynamic> _aiSuggestions = [];
  bool _loadingAiSuggestions = false;
  bool _showAiSuggestions = false;

  // Attachments
  List<String> _attachments = [];
  bool _uploadingAttachment = false;

  // Redesigned Itinerary & Country Suggestions
  int _itineraryViewIndex = 0; // 0: List, 1: Map
  String? _destinationCountryCode;
  List<Map<String, dynamic>> _googleCountrySuggestions = [];
  bool _loadingCountrySuggestions = false;
  final TextEditingController _sheetSearchController = TextEditingController();
  List<PlaceModel> _sheetSearchResults = [];
  bool _sheetSearching = false;

  @override
  void initState() {
    super.initState();
    _tripState = widget.trip;
    _destinationCountryCode =
        CountryHelper.getCountryCode(_tripState.mainDestination);
    _resolveTripCoverPhoto();
    _fetchTripDetails();
    _fetchActivities();
    _loadAttachments();
    _searchController.addListener(_onSearchChanged);
    _fetchDestinationCoordinates();
    _resolveDayActivityCoordinates();
    _fetchCountrySuggestions();
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

    TripImageHelper.resolvePhoto(destKey).then((uri) {
      if (uri != null && uri.isNotEmpty && mounted) {
        setState(() {
          _tripState = _tripState.copyWith(imageUrl: uri);
        });
      }
    });
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
      final key = entry.key;
      final bool matches;
      if (key.length <= 3) {
        matches = RegExp(r'\b' + RegExp.escape(key) + r'\b').hasMatch(city);
      } else {
        matches = city.contains(key);
      }
      if (matches) {
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
      String rawUrl = blobPath.trim();
      if (!rawUrl.startsWith("http://") && !rawUrl.startsWith("https://")) {
        final apiService = sl<ApiService>();
        final result = await apiService.downloadFile(blobPath);

        if (result is Success<String> && result.data.isNotEmpty) {
          rawUrl = result.data.trim();
        } else {
          AppToast.error("Failed to download file");
          return;
        }
      }

      // If the string contains a map format or JSON wrapper, extract the URL substring
      if (rawUrl.startsWith("{") && rawUrl.contains("http")) {
        final match = RegExp(r'https?://[^\s",}]+').firstMatch(rawUrl);
        if (match != null) {
          rawUrl = match.group(0)!;
        }
      }

      final url = Uri.parse(rawUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        AppToast.error("Could not launch file reader");
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
          } else if (_tripState.imageUrl.startsWith("http") &&
              !_tripState.imageUrl.contains("images.unsplash.com/photo-1488646953014-85cb44e25828")) {
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
    _sheetSearchController.dispose();
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

    // 5. Phuket / Thailand
    if (destLower.contains("phuket") ||
        destLower.contains("bangkok") ||
        destLower.contains("thailand") ||
        destLower.contains("krabi") ||
        destLower.contains("samui")) {
      return [
        {
          "name": "Phi Phi Islands & Maya Bay Boat Tour",
          "category": "Adventure",
          "description":
              "Speedboat trip to stunning turquoise lagoons, limestone cliffs, and snorkeling spots.",
          "estimatedCost": 45,
          "duration": "6h",
          "tips": "Bring reef-safe sunscreen and waterproof bag for camera.",
        },
        {
          "name": "Big Buddha & Chalong Temple",
          "category": "Culture",
          "description":
              "45-meter white marble Buddha with 360-degree panoramic views over Phuket island.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips": "Modest attire required (shoulders and knees covered).",
        },
        {
          "name": "Old Phuket Town Heritage Walk",
          "category": "Culture",
          "description":
              "Explore colorful Sino-Portuguese shophouses, street art, cafes, and local night markets.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips": "Sunday Walking Street Market is a must-visit for street food.",
        },
        {
          "name": "Patong Beach & Promthep Cape Sunset",
          "category": "Relaxation",
          "description":
              "Relax on golden sands and catch iconic Andaman Sea sunset views.",
          "estimatedCost": 0,
          "duration": "2h",
          "tips": "Visit Promthep Cape for the most famous sunset panorama in Phuket.",
        },
      ];
    }

    // 6. London / UK
    if (destLower.contains("london") ||
        destLower.contains("england") ||
        destLower.contains("united kingdom") ||
        RegExp(r'\b' + RegExp.escape("uk") + r'\b').hasMatch(destLower)) {
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
                final startLocal = start.toLocal();
                final actLocal = model.startDatetime.toLocal();
                final diffDays = DateTime(actLocal.year, actLocal.month, actLocal.day)
                    .difference(DateTime(startLocal.year, startLocal.month, startLocal.day))
                    .inDays;
                final calculatedDay = diffDays >= 0 ? "${diffDays + 1}" : "";
                final finalDayId = calculatedDay.isNotEmpty
                    ? calculatedDay
                    : (model.dayId.isNotEmpty && model.dayId != "0" ? model.dayId : "1");
                return model.copyWith(dayId: finalDayId);
              },
            )
            .toList();

        if (mounted) {
          setState(() {
            // Filter locally by tripId and sort by startDatetime
            _activities = all
                .where((act) => act.tripId.isEmpty || act.tripId == _tripState.id)
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
    final countryCode = _destinationCountryCode ??
        CountryHelper.getCountryCode(_tripState.mainDestination);
    final result = await mapApiService.searchPlaces(
      query,
      countryCode: countryCode,
      lat: _destinationLat,
      lng: _destinationLng,
    );

    result.fold((failure) {
      if (mounted) {
        setState(() => _searchingLocations = false);
      }
    }, (places) {
      if (_searchController.text.trim().isNotEmpty && mounted) {
        setState(() {
          _suggestions = places;
          _searchingLocations = false;
        });
      }
    });
  }

  Future<void> _fetchCountrySuggestions() async {
    final dest = _tripState.mainDestination.trim().isNotEmpty
        ? _tripState.mainDestination.trim()
        : _tripState.name;
    final countryCode = _destinationCountryCode ??
        CountryHelper.getCountryCode(dest);
    final countryName = CountryHelper.getCountryName(dest, countryCode);

    if (dest.isEmpty) return;

    setState(() => _loadingCountrySuggestions = true);
    try {
      final placesService = sl.isRegistered<GooglePlacesNewService>()
          ? sl<GooglePlacesNewService>()
          : GooglePlacesNewService();

      final query = "top attractions in $dest, $countryName";
      final spots = await placesService.searchPlacesByText(
        query,
        regionCode: countryCode,
        pageSize: 12,
      );

      if (spots.isNotEmpty) {
        if (mounted) {
          setState(() {
            _googleCountrySuggestions = spots;
            _loadingCountrySuggestions = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Error fetching Google Places suggestions by country: $e");
    }

    final fallbackSpots = _getCuratedCountrySuggestions(dest, countryName);
    if (mounted) {
      setState(() {
        _googleCountrySuggestions = fallbackSpots;
        _loadingCountrySuggestions = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCuratedCountrySuggestions(
      String dest, String countryName) {
    final lower = dest.toLowerCase();
    if (lower.contains("shillong") || lower.contains("meghalaya")) {
      return [
        {
          "id": "shillong_umiam_lake",
          "name": "Umiam Lake",
          "category": "NATURE & PARKS",
          "types": ["natural_feature", "park"],
          "rating": 4.6,
          "userRatingCount": 2100,
          "address": "Umiam, Meghalaya 793103",
          "photoUrl":
              "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800",
          "cost": 0.0,
          "timeRange": "9:00 AM – 10:30 AM",
        },
        {
          "id": "shillong_elephant_falls",
          "name": "Elephant Falls",
          "category": "WATERFALL",
          "types": ["natural_feature", "tourist_attraction"],
          "rating": 4.4,
          "userRatingCount": 1800,
          "address": "Upper Shillong, Meghalaya 793009",
          "photoUrl":
              "https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800",
          "cost": 20.0,
          "timeRange": "11:00 AM – 12:00 PM",
        },
        {
          "id": "shillong_wards_lake",
          "name": "Ward's Lake",
          "category": "LAKE & GARDEN",
          "types": ["park", "natural_feature"],
          "rating": 4.2,
          "userRatingCount": 950,
          "address": "Police Bazar, Shillong, Meghalaya 793001",
          "photoUrl":
              "https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=800",
          "cost": 30.0,
          "timeRange": "2:00 PM – 3:00 PM",
        },
        {
          "id": "shillong_peak",
          "name": "Shillong Peak",
          "category": "NATURE & PARKS",
          "types": ["tourist_attraction", "natural_feature"],
          "rating": 4.5,
          "userRatingCount": 3200,
          "address": "Shillong View Point, Meghalaya 793010",
          "photoUrl":
              "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800",
          "cost": 50.0,
          "timeRange": "4:00 PM – 5:30 PM",
        },
        {
          "id": "shillong_don_bosco",
          "name": "Don Bosco Museum",
          "category": "CULTURE & SIGHTS",
          "types": ["museum", "tourist_attraction"],
          "rating": 4.7,
          "userRatingCount": 2800,
          "address": "Mawlai Phudmuri, Shillong, Meghalaya 793008",
          "photoUrl":
              "https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=800",
          "cost": 100.0,
          "timeRange": "10:00 AM – 12:30 PM",
        },
      ];
    }

    return [
      {
        "id": "spot_1",
        "name": "$dest Scenic Viewpoint",
        "category": "NATURE & PARKS",
        "types": ["natural_feature", "tourist_attraction"],
        "rating": 4.6,
        "userRatingCount": 1200,
        "address": "$dest, $countryName",
        "photoUrl":
            "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800",
        "cost": 0.0,
        "timeRange": "9:00 AM – 10:30 AM",
      },
      {
        "id": "spot_2",
        "name": "$dest Heritage Center",
        "category": "CULTURE & SIGHTS",
        "types": ["museum", "point_of_interest"],
        "rating": 4.5,
        "userRatingCount": 950,
        "address": "$dest, $countryName",
        "photoUrl":
            "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800",
        "cost": 15.0,
        "timeRange": "11:00 AM – 12:30 PM",
      },
      {
        "id": "spot_3",
        "name": "$dest Botanical Gardens",
        "category": "NATURE & PARKS",
        "types": ["park", "natural_feature"],
        "rating": 4.4,
        "userRatingCount": 1600,
        "address": "$dest, $countryName",
        "photoUrl":
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
        "cost": 0.0,
        "timeRange": "2:00 PM – 4:00 PM",
      },
    ];
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

  Future<void> _addActivity(PlaceModel suggestion, [BuildContext? sheetCtx]) async {
    if (sheetCtx != null && sheetCtx.mounted) {
      Navigator.pop(sheetCtx);
    }
    // Unfocus and clear search
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() => _suggestions = []);

    final dateStr = _currentDayDate.toIso8601String().split('T').first;
    final currentDayActs =
        _activities.where((a) => a.dayId == "${_selectedDayIndex + 1}").toList();
    final nextHour = 9 + (currentDayActs.length * 2);
    final startHourStr = nextHour.toString().padLeft(2, '0');
    final endHourStr = (nextHour + 1).toString().padLeft(2, '0');
    final startDatetime = DateTime.parse("${dateStr}T$startHourStr:00:00Z");
    final endDatetime = DateTime.parse("${dateStr}T$endHourStr:00:00Z");

    final cat = _getCategoryEnum(suggestion.types);
    final currencySymbol = CountryHelper.getCurrencySymbol(
        _tripState.mainDestination, _destinationCountryCode);

    final payload = {
      "tripId": _tripState.id,
      "placeId": convertToMongoObjectId(suggestion.placeId.isNotEmpty
          ? suggestion.placeId
          : "place_${DateTime.now().millisecondsSinceEpoch}"),
      "name": suggestion.name,
      "bookingReference": "",
      "startDatetime": startDatetime.toUtc().toIso8601String(),
      "endDatetime": endDatetime.toUtc().toIso8601String(),
      "currency": currencySymbol,
      "bookingUrl": "",
      "confirmationDocumentUrl": "",
      "activityDetailsDto": {
        "categoryDto": cat,
        "participants": [],
        "meetingPoint": suggestion.address,
        "duration": 90,
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

  Future<void> _addSpotFromGoogleSuggestion(
      Map<String, dynamic> spot, BuildContext? sheetCtx) async {
    if (sheetCtx != null && sheetCtx.mounted) {
      Navigator.pop(sheetCtx);
    }

    final name = spot["name"] ?? "New Spot";
    AppToast.success("Adding $name...");

    final dateStr = _currentDayDate.toIso8601String().split('T').first;
    final currentDayActs =
        _activities.where((a) => a.dayId == "${_selectedDayIndex + 1}").toList();
    final nextHour = 9 + (currentDayActs.length * 2);
    final startHourStr = nextHour.toString().padLeft(2, '0');
    final endHourStr = (nextHour + 1).toString().padLeft(2, '0');
    final startDatetime = DateTime.parse("${dateStr}T$startHourStr:00:00Z");
    final endDatetime = DateTime.parse("${dateStr}T$endHourStr:00:00Z");

    final cat = _getCategoryEnum(spot["types"] is List
        ? (spot["types"] as List).cast<String>()
        : []);
    final currencySymbol = CountryHelper.getCurrencySymbol(
        _tripState.mainDestination, _destinationCountryCode);

    final payload = {
      "tripId": _tripState.id,
      "placeId": convertToMongoObjectId(
          spot["id"]?.toString().isNotEmpty == true
              ? spot["id"].toString()
              : "spot_${DateTime.now().millisecondsSinceEpoch}"),
      "name": name,
      "bookingReference": "",
      "startDatetime": startDatetime.toUtc().toIso8601String(),
      "endDatetime": endDatetime.toUtc().toIso8601String(),
      "currency": currencySymbol,
      "bookingUrl": "",
      "confirmationDocumentUrl": "",
      "activityDetailsDto": {
        "categoryDto": cat,
        "participants": [],
        "meetingPoint": spot["address"] ?? "",
        "duration": 90,
        "difficulty": "Easy",
        "ageRestriction": "None",
        "cost": (spot["cost"] as num?)?.toDouble() ?? 0.0,
        "tips": "Recommended spot in ${_tripState.mainDestination}",
        "imageUrl": spot["photoUrl"] ?? _getPlaceImageUrl(cat, name),
      },
      "notes": spot["address"] ?? "",
    };

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

  Future<void> _deleteActivity(String activityId, [String? activityName]) async {
    AppToast.success("Removing activity...");
    final originalActivities = List<TripActivityModel>.from(_activities);

    // Optimistically remove from state so UI updates immediately
    setState(() {
      _activities.removeWhere((a) =>
          (activityId.isNotEmpty && a.id == activityId) ||
          (activityName != null && a.name == activityName));
    });

    if (activityId.trim().isEmpty) {
      AppToast.success("Removed successfully!");
      return;
    }

    try {
      final apiService = sl<ApiService>();
      var result = await apiService.delete<dynamic>(
        "/TripActivity/$activityId",
        fromJson: (json) => json,
      );

      // Fallback 1: query parameter ?id=
      if (result is Failure<dynamic>) {
        result = await apiService.delete<dynamic>(
          "/TripActivity?id=$activityId",
          fromJson: (json) => json,
        );
      }

      // Fallback 2: query parameter ?activityId=
      if (result is Failure<dynamic>) {
        result = await apiService.delete<dynamic>(
          "/TripActivity?activityId=$activityId",
          fromJson: (json) => json,
        );
      }

      if (result is Success<dynamic>) {
        AppToast.success("Removed successfully!");
        _fetchActivities();
      } else if (result is Failure<dynamic>) {
        setState(() => _activities = originalActivities);
        AppToast.error(result.message);
      }
    } catch (e) {
      setState(() => _activities = originalActivities);
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
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7E22CE),
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => _openAddSpotSheet(context),
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30.sp,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchActivities();
          if (_showAiSuggestions) {
            await _fetchAiSuggestions();
          }
        },
        color: const Color(0xFF0D9488),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Cover Image, Back/Action buttons, Trip Title & Dates
              _buildTripHeroHeader(context),
              _buildDayProgressHeader(),
              _buildDaySelector(context),
              _buildAiSuggestionsBanner(context),
              if (_showAiSuggestions) _buildAiSuggestionsContent(context),
              _buildSearchBar(context),
              if (_loadingActivities)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                  ),
                )
              else
                _buildItinerarySection(context, dayActivities),
              _buildAttachmentsSection(context),
              80.h.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripHeroHeader(BuildContext context) {
    final displayImageUrl = TripImageHelper.getDisplayImageUrl(_tripState);

    final parts = <String>[];
    if (_tripState.dateRange.isNotEmpty) {
      parts.add(_tripState.dateRange);
    }
    if (_tripState.tripType.isNotEmpty) {
      parts.add(_tripState.tripType);
    }
    if (_tripState.category.isNotEmpty) {
      parts.add(_tripState.category);
    }
    final subtitleText = parts.isNotEmpty
        ? parts.join(" · ")
        : (_tripState.mainDestination.isNotEmpty
            ? _tripState.mainDestination
            : "Planned Trip");

    final titleText = _tripState.name.isNotEmpty
        ? (_tripState.flag.isNotEmpty
            ? "${_tripState.name} ${_tripState.flag}"
            : _tripState.name)
        : (_tripState.mainDestination.isNotEmpty
            ? "${_tripState.mainDestination} ${_tripState.flag}"
            : "My Trip");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Cover Image with floating Back, Share, and More buttons
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: CachedNetworkImage(
                imageUrl: displayImageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Image.network(
                  TripData.getTripImage(
                    _tripState.mainDestination.isNotEmpty
                        ? _tripState.mainDestination
                        : _tripState.name,
                  ),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ),

            // Top soft gradient overlay for button contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(90),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Navigation Buttons (Back on left, Share & More on right)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular Back Button
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(235),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: const Color(0xFF1E293B),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),

                    // Actions on right: Share + More Vert
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            AppToast.success("Trip link copied to clipboard");
                          },
                          child: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(235),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.share_outlined,
                                color: const Color(0xFF1E293B),
                                size: 19.sp,
                              ),
                            ),
                          ),
                        ),
                        10.w.horizontalSpace,
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          offset: const Offset(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          onSelected: (value) {
                            if (value == 'budget') {
                              context.push('/BudgetExpensesScreen', extra: _tripState);
                            } else if (value == 'edit') {
                              _showEditTripDialog();
                            } else if (value == 'bookings') {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => TripBookingsSheet(
                                  tripId: _tripState.id,
                                  initialTabIndex: 0,
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'budget',
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, size: 20),
                                  10.w.horizontalSpace,
                                  const Text("Budget & Expenses"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_note_rounded, size: 20),
                                  10.w.horizontalSpace,
                                  const Text("Edit Trip"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'bookings',
                              child: Row(
                                children: [
                                  const Icon(Icons.bed_rounded, size: 20),
                                  10.w.horizontalSpace,
                                  const Text("Bookings"),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(235),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: const Color(0xFF1E293B),
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 2. Dark Bar: Trip Name, Flag, and Dates (Exactly matches user's screenshot)
        Container(
          width: double.infinity,
          color: const Color(0xFFFFFFFF),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              6.h.verticalSpace,
              Text(
                subtitleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayProgressHeader() {
    final total = _totalDays > 0 ? _totalDays : 1;
    final current = (_selectedDayIndex + 1).clamp(1, total);
    final progress = (current / total).clamp(0.08, 1.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day 1 of 4
          Text(
            "Day $current of $total",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          6.w.horizontalSpace,

          // Horizontal Progress Bar Pill: Flexible to eliminate any right overflow
          Expanded(
            child: Container(
              height: 5.5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ),
          7.w.horizontalSpace,

          // Date Range: 14 Oct - 17 Oct 2026
          Text(
            _formatDateRangeHeader(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddSpotSheet(context),
      child: Container(
        margin: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 8.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: const Color(0xFF475569),
              size: 20.sp,
            ),
            12.w.horizontalSpace,
            Expanded(
              child: Text(
                "Search places to add to Day ${_selectedDayIndex + 1}",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSuggestionsBanner(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F4),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // White circle with purple sparkle icon
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withAlpha(15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: const Color(0xFF7E22CE),
                size: 19.sp,
              ),
            ),
          ),
          8.w.horizontalSpace,

          // Middle Column: Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "AI Smart Suggestions",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                2.h.verticalSpace,
                Text(
                  "Get personalized recommendations for Day ${_selectedDayIndex + 1}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          8.w.horizontalSpace,

          // Explore > Purple Pill Button
          GestureDetector(
            onTap: () {
              setState(() {
                _showAiSuggestions = !_showAiSuggestions;
              });
              if (_aiSuggestions.isEmpty && _showAiSuggestions) {
                _fetchAiSuggestions();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF7E22CE),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Explore",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  2.w.horizontalSpace,
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionsContent(BuildContext context) {

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

  // ignore: unused_element
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
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: context.shimmerBase,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.primary.withAlpha(100),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Image.network(
                TripData.getTripImage(
                  _tripState.mainDestination.isNotEmpty
                      ? _tripState.mainDestination
                      : _tripState.name,
                ),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: context.shimmerBase,
                  child: Icon(
                    Icons.image_rounded,
                    size: 64.sp,
                    color: context.onSurfaceVariant.withAlpha(60),
                  ),
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

  // ignore: unused_element
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
      height: 45.h,
      margin: EdgeInsets.only(top: 4.h, bottom: 10.h),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        scrollDirection: Axis.horizontal,
        itemCount: _totalDays + 1,
        separatorBuilder: (context, index) => 8.w.horizontalSpace,
        itemBuilder: (context, index) {
          if (index == _totalDays) {
            // Edit itinerary circular mint button immediately following the last day pill
            return Center(
              child: GestureDetector(
                onTap: _openEditItinerary,
                child: Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCCFBF1),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit_outlined,
                      color: const Color(0xFF0D9488),
                      size: 19.sp,
                    ),
                  ),
                ),
              ),
            );
          }

          final isSelected = index == _selectedDayIndex;
          final date = (_tripState.startDate ?? DateTime.now()).add(
            Duration(days: index),
          );
          final formattedDate = _formatShortDayDate(date);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
              _resolveDayActivityCoordinates();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 58.w,
              padding: EdgeInsets.symmetric(
                horizontal: 6.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0D9488)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Day ${index + 1}",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5.sp,
                    ),
                  ),
                  2.h.verticalSpace,
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withAlpha(220)
                          : const Color(0xFF64748B),
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatShortDayDate(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${months[date.month - 1]}";
  }

  String _formatDateRangeHeader() {
    final start = _tripState.startDate ?? DateTime.now();
    final end = _tripState.endDate ?? start.add(Duration(days: _totalDays - 1));
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    final startMonth = months[start.month - 1];
    final endMonth = months[end.month - 1];
    return "${start.day} $startMonth - ${end.day} $endMonth ${end.year}";
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? "PM" : "AM";
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return "$formattedHour:$formattedMinute $period";
  }

  Future<void> _launchMaps(String query) async {
    final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
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
              _deleteActivity(activity.id, activity.name);
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

  String _getFormattedCategoryName(int category, [String? name]) {
    if (name != null) {
      final lower = name.toLowerCase();
      if (lower.contains("ward") || lower.contains("lake & garden")) {
        return "LAKE & GARDEN";
      }
      if (lower.contains("waterfall") || lower.contains("falls")) {
        return "WATERFALL";
      }
      if (lower.contains("lake") ||
          lower.contains("dam") ||
          lower.contains("river") ||
          lower.contains("park")) {
        return "NATURE & PARKS";
      }
      if (lower.contains("museum") ||
          lower.contains("fort") ||
          lower.contains("palace") ||
          lower.contains("temple") ||
          lower.contains("church")) {
        return "CULTURE & SIGHTS";
      }
      if (lower.contains("market") ||
          lower.contains("bazaar") ||
          lower.contains("mall")) {
        return "SHOPPING";
      }
    }

    switch (category) {
      case 1:
        return "FOOD & DINING";
      case 2:
        return "TRANSPORT";
      case 3:
        return "ACCOMMODATION";
      case 4:
        return "RELAXATION & SPA";
      case 5:
        return "SHOPPING";
      case 0:
      default:
        return "NATURE & PARKS";
    }
  }

  // ===============================
  // REDESIGNED ITINERARY SECTION (MATCHES SCREENSHOT)
  // ===============================
  Widget _buildItinerarySection(
      BuildContext context, List<TripActivityModel> dayActivities) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Your itinerary" + "+ Add a spot"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Your itinerary",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22.sp,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              InkWell(
                onTap: () => _openAddSpotSheet(context),
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: const Color(0xFF0D9488),
                        size: 20.sp,
                      ),
                      4.w.horizontalSpace,
                      Text(
                        "Add a spot",
                        style: TextStyle(
                          color: const Color(0xFF0D9488),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          14.h.verticalSpace,

          // Full-width Pill Switcher: "List" and "Map"
          Container(
            width: double.infinity,
            height: 24.h,
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _itineraryViewIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _itineraryViewIndex == 0
                            ? const Color(0xFF0D9488)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: _itineraryViewIndex == 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withAlpha(40),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        "List",
                        style: TextStyle(
                          color: _itineraryViewIndex == 0
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _itineraryViewIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _itineraryViewIndex == 1
                            ? const Color(0xFF0D9488)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: _itineraryViewIndex == 1
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withAlpha(40),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        "Map",
                        style: TextStyle(
                          color: _itineraryViewIndex == 1
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          16.h.verticalSpace,

          // Content based on selected tab
          if (_itineraryViewIndex == 0)
            _buildRedesignedListView(context, dayActivities)
          else
            _buildRedesignedMapView(context, dayActivities),
        ],
      ),
    );
  }

  Widget _buildRedesignedListView(
      BuildContext context, List<TripActivityModel> dayActivities) {
    if (dayActivities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.place_outlined,
              size: 48.sp,
              color: const Color(0xFF0D9488).withAlpha(120),
            ),
            12.h.verticalSpace,
            Text(
              "No spots planned for Day ${_selectedDayIndex + 1}.",
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            6.h.verticalSpace,
            Text(
              "Tap '+ Add a spot' above to discover popular attractions in ${_tripState.mainDestination}!",
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
            16.h.verticalSpace,
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
              onPressed: () => _openAddSpotSheet(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add a spot"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(dayActivities.length, (index) {
        final activity = dayActivities[index];
        final isLast = index == dayActivities.length - 1;
        return _buildRedesignedSpotCard(context, activity, index, isLast);
      }),
    );
  }

  Widget _buildRedesignedSpotCard(
    BuildContext context,
    TripActivityModel activity,
    int index,
    bool isLast,
  ) {
    final categoryName =
        _getFormattedCategoryName(activity.category, activity.name);

    double rating = 4.2 + ((activity.name.hashCode.abs() % 8) / 10.0);
    String reviewCount =
        "${(1.2 + (activity.name.hashCode.abs() % 25) / 10.0).toStringAsFixed(1)}k";
    String? customPrice;
    String? customTime;

    // Check curated entries to match screenshot values precisely if applicable
    final curated = CountryHelper.getCuratedPlaces(_tripState.mainDestination);
    for (final p in curated) {
      final pName = (p["name"] as String? ?? "").toLowerCase();
      if (activity.name.toLowerCase().contains(pName) ||
          pName.contains(activity.name.toLowerCase())) {
        if (p["rating"] != null) {
          rating = (p["rating"] as num).toDouble();
        }
        if (p["userRatingCount"] != null) {
          final count = (p["userRatingCount"] as num).toInt();
          reviewCount = count >= 1000
              ? "${(count / 1000).toStringAsFixed(1)}k"
              : "$count";
        }
        if (p["priceText"] != null) {
          customPrice = p["priceText"] as String;
        }
        if (p["timeRange"] != null) {
          customTime = p["timeRange"] as String;
        }
        break;
      }
    }

    final timeRange = customTime ??
        "${_formatTime(activity.startDatetime)} – ${_formatTime(activity.endDatetime)}";
    final currencySymbol = CountryHelper.getCurrencySymbol(
        _tripState.mainDestination, _destinationCountryCode);
    final priceText = customPrice ??
        (activity.cost > 0
            ? "$currencySymbol${activity.cost.toStringAsFixed(0)} / person"
            : "Free");

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Square Box Thumbnail (1:1 ratio, box shape)
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: SizedBox(
              width: 110.w,
              height: 110.w,
              child: CachedNetworkImage(
                imageUrl: activity.displayImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Image.network(
                  TripActivityModel.getFallbackImage(
                      activity.category, activity.name),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: Color(0xFF94A3B8),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          8.w.horizontalSpace,

          // Right Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Category in uppercase + 3-dots popup menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          categoryName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 9.h,
                        width: 9.w,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 8.sp,
                          splashRadius: 10.r,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Color(0xFF475569),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDelete(context, activity);
                            } else if (value == 'maps') {
                              _launchMaps(activity.name);
                            } else if (value == 'details') {
                              _showActivityDetails(activity);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'maps',
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 18, color: Color(0xFF0D9488)),
                                  8.w.horizontalSpace,
                                  const Text("View on Maps"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 18),
                                  8.w.horizontalSpace,
                                  const Text("Spot Details"),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  8.w.horizontalSpace,
                                  const Text("Delete spot",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  1.h.verticalSpace,

                  // Spot Title (Allows up to 2 lines for full readable name)
                  Text(
                    activity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5.sp,
                      color: const Color(0xFF0F172A),
                      height: 1.18,
                      letterSpacing: -0.1,
                    ),
                  ),
                  3.h.verticalSpace,

                  // Rating: ★ 4.6 (2.1k)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 13.sp,
                      ),
                      3.w.horizontalSpace,
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5.sp,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      3.w.horizontalSpace,
                      Text(
                        "($reviewCount)",
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  3.h.verticalSpace,

                  // Time Range: 9:00 AM – 10:30 AM
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 9.5.sp,
                        color: const Color(0xFF64748B),
                      ),
                      5.w.horizontalSpace,
                      Text(
                        timeRange,
                        style: TextStyle(
                          fontSize: 7.5.sp,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  3.h.verticalSpace,

                  // Price Row: Free / ₹20 / person with coin currency icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF64748B),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            currencySymbol.trim().isNotEmpty
                                ? currencySymbol.trim()
                                : "₹",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      5.w.horizontalSpace,
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  4.h.verticalSpace,

                  // View on Google Maps Link with direct underline
                  InkWell(
                    onTap: () => _launchMaps(activity.name),
                    borderRadius: BorderRadius.circular(4.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 9.sp,
                            color: const Color(0xFF0D9488),
                          ),
                          4.w.horizontalSpace,
                          Text(
                            "View on Google Maps",
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildRedesignedMapView(
      BuildContext context, List<TripActivityModel> dayActivities) {
    return ItineraryMapView(
      activities: dayActivities,
      destinationName: _tripState.mainDestination,
      centerLat: _destinationLat,
      centerLng: _destinationLng,
      resolvedCoords: _resolvedActivityCoords,
    );
  }

  // ===============================
  // ADD SPOT BOTTOM SHEET (COUNTRY AWARE & GOOGLE SUGGESTIONS)
  // ===============================
  void _openAddSpotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final countryCode = _destinationCountryCode ??
              CountryHelper.getCountryCode(_tripState.mainDestination);
          final countryName =
              CountryHelper.getCountryName(_tripState.mainDestination, countryCode);

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: context.onSurfaceVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add a Spot to Day ${_selectedDayIndex + 1}",
                            style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                          4.h.verticalSpace,
                          Text(
                            "Showing places in $countryName",
                            style: context.text.bodySmall?.copyWith(
                              color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                12.h.verticalSpace,
                // Search field restricted to country
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: TextField(
                    controller: _sheetSearchController,
                    decoration: InputDecoration(
                      hintText: "Search places in $countryName...",
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF0D9488)),
                      suffixIcon: _sheetSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _sheetSearchController.clear();
                                setSheetState(
                                    () => _sheetSearchResults = []);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) async {
                      if (val.trim().isEmpty) {
                        setSheetState(() => _sheetSearchResults = []);
                        return;
                      }
                      setSheetState(() => _sheetSearching = true);
                      final mapService = sl<GoogleMapsApiService>();
                      final res = await mapService.searchPlaces(
                        val.trim(),
                        countryCode: countryCode,
                        lat: _destinationLat,
                        lng: _destinationLng,
                      );
                      res.fold(
                        (_) => setSheetState(() {
                          _sheetSearchResults = [];
                          _sheetSearching = false;
                        }),
                        (places) => setSheetState(() {
                          _sheetSearchResults = places;
                          _sheetSearching = false;
                        }),
                      );
                    },
                  ),
                ),
                12.h.verticalSpace,
                // Content area: Google Suggestions (when search empty) or Search Results
                Expanded(
                  child: _sheetSearching
                      ? const Center(child: CircularProgressIndicator())
                      : _sheetSearchResults.isNotEmpty
                          ? _buildSheetSearchResults(
                              modalCtx, _sheetSearchResults)
                          : _buildSheetCountrySuggestions(
                              modalCtx, countryName),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetSearchResults(
      BuildContext modalCtx, List<PlaceModel> places) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      itemCount: places.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = places[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF0D9488).withAlpha(25),
            child: const Icon(
              Icons.place,
              color: Color(0xFF0D9488),
              size: 20,
            ),
          ),
          title: Text(
            suggestion.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            suggestion.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              elevation: 0,
            ),
            onPressed: () => _addActivity(suggestion, modalCtx),
            child: const Text("+ Add"),
          ),
        );
      },
    );
  }

  Widget _buildSheetCountrySuggestions(
      BuildContext modalCtx, String countryName) {
    if (_loadingCountrySuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_googleCountrySuggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Search for places in $countryName above to add to your itinerary.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      itemCount: _googleCountrySuggestions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 16.sp, color: const Color(0xFF0D9488)),
                6.w.horizontalSpace,
                Text(
                  "Popular spots in ${_tripState.mainDestination.isNotEmpty ? _tripState.mainDestination : countryName}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          );
        }

        final spot = _googleCountrySuggestions[index - 1];
        final name = spot["name"]?.toString() ?? "Spot";
        final rating = (spot["rating"] as num?)?.toDouble() ?? 4.5;
        final count = (spot["userRatingCount"] as num?)?.toInt() ?? 1000;
        final photoUrl = spot["photoUrl"]?.toString();
        final category = spot["category"]?.toString() ??
            _getFormattedCategoryName(0, name);

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 64.w,
                        height: 64.h,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.network(
                          TripActivityModel.getFallbackImage(0, name),
                          width: 64.w,
                          height: 64.h,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.network(
                        TripActivityModel.getFallbackImage(0, name),
                        width: 64.w,
                        height: 64.h,
                        fit: BoxFit.cover,
                      ),
              ),
              12.w.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    4.h.verticalSpace,
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12.sp),
                        2.w.horizontalSpace,
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        2.w.horizontalSpace,
                        Text(
                          "(${(count / 1000).toStringAsFixed(1)}k)",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _addSpotFromGoogleSuggestion(spot, modalCtx),
                child: const Text("+ Add"),
              ),
            ],
          ),
        );
      },
    );
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
