import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/api_result.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/accommodation_model.dart';
import 'package:wonder_souls/src/features/trips/model/trip_transport_model.dart';

class TripBookingsSheet extends StatefulWidget {
  final String tripId;
  final int initialTabIndex;

  const TripBookingsSheet({
    super.key,
    required this.tripId,
    this.initialTabIndex = 0,
  });

  @override
  State<TripBookingsSheet> createState() => _TripBookingsSheetState();
}

class _TripBookingsSheetState extends State<TripBookingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = sl<ApiService>();

  List<AccommodationModel> _accommodations = [];
  List<TripTransportModel> _transports = [];
  bool _loadingAccommodations = false;
  bool _loadingTransports = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _fetchAccommodations();
    _fetchTransports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic rawData, List<String> candidateKeys) {
    if (rawData is List) return rawData;
    if (rawData is Map<String, dynamic>) {
      for (final key in candidateKeys) {
        if (rawData[key] is List) return rawData[key] as List;
      }
      if (rawData["data"] is Map<String, dynamic>) {
        final inner = rawData["data"] as Map<String, dynamic>;
        for (final key in candidateKeys) {
          if (inner[key] is List) return inner[key] as List;
        }
      }
      // If a single accommodation object was returned directly
      if (rawData.containsKey("id") ||
          rawData.containsKey("Id") ||
          rawData.containsKey("name") ||
          rawData.containsKey("hotelName")) {
        return [rawData];
      }
    }
    return [];
  }

  Future<void> _fetchAccommodations() async {
    setState(() => _loadingAccommodations = true);
    try {
      // Send tripId in query payload
      ApiResult<dynamic> result = await _apiService.get<dynamic>(
        "/Accomodation?TripId=${widget.tripId}&tripId=${widget.tripId}",
        fromJson: (json) => json,
      );

      // If empty or failure, fallback to other query variants
      if (result is Failure<dynamic>) {
        result = await _apiService.get<dynamic>(
          "/Accomodation?tripId=${widget.tripId}",
          fromJson: (json) => json,
        );
        if (result is Failure<dynamic>) {
          result = await _apiService.get<dynamic>(
            "/Accomodation/by-trip/${widget.tripId}",
            fromJson: (json) => json,
          );
          if (result is Failure<dynamic>) {
            result = await _apiService.get<dynamic>(
              "/Accomodation",
              fromJson: (json) => json,
            );
          }
        }
      }

      if (result is Success<dynamic>) {
        final rawData = result.data;
        final itemsList = _extractList(rawData, [
          "data",
          "items",
          "accommodations",
          "Accommodations",
          "value",
          "results",
          "result",
        ]);

        final targetTripId = widget.tripId.trim().toLowerCase();
        final List<AccommodationModel> items = [];
        for (final item in itemsList) {
          if (item is Map<String, dynamic>) {
            try {
              final acc = AccommodationModel.fromJson(item);
              final accTripId = (acc.tripId ?? "").trim().toLowerCase();
              if (accTripId.isEmpty || accTripId == targetTripId) {
                items.add(acc);
              }
            } catch (e) {
              debugPrint("Error parsing accommodation item: $e");
            }
          }
        }

        setState(() {
          _accommodations = items;
          _loadingAccommodations = false;
        });
      } else {
        setState(() => _loadingAccommodations = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch accommodations: $e");
      setState(() => _loadingAccommodations = false);
    }
  }

  Future<void> _fetchTransports() async {
    setState(() => _loadingTransports = true);
    try {
      ApiResult<dynamic> result = await _apiService.get<dynamic>(
        "/TripTransports?TripId=${widget.tripId}&tripId=${widget.tripId}",
        fromJson: (json) => json,
      );

      if (result is Failure<dynamic>) {
        result = await _apiService.get<dynamic>(
          "/TripTransports?tripId=${widget.tripId}",
          fromJson: (json) => json,
        );
        if (result is Failure<dynamic>) {
          result = await _apiService.get<dynamic>(
            "/TripTransports",
            fromJson: (json) => json,
          );
        }
      }

      if (result is Success<dynamic>) {
        final rawData = result.data;
        final itemsList = _extractList(rawData, [
          "data",
          "items",
          "transports",
          "Transports",
          "tripTransports",
          "TripTransports",
          "value",
          "results",
          "result",
        ]);

        final targetTripId = widget.tripId.trim().toLowerCase();
        final List<TripTransportModel> items = [];
        for (final item in itemsList) {
          if (item is Map<String, dynamic>) {
            try {
              final t = TripTransportModel.fromJson(item);
              final tTripId = (t.tripId ?? "").trim().toLowerCase();
              if (tTripId.isEmpty || tTripId == targetTripId) {
                items.add(t);
              }
            } catch (e) {
              debugPrint("Error parsing transport item: $e");
            }
          }
        }

        setState(() {
          _transports = items;
          _loadingTransports = false;
        });
      } else {
        setState(() => _loadingTransports = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch transports: $e");
      setState(() => _loadingTransports = false);
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return "Dates not set";
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    String formatSingle(DateTime d) {
      final dayStr = d.day.toString();
      final suffix = (d.day >= 11 && d.day <= 13)
          ? "th"
          : (d.day % 10 == 1)
              ? "st"
              : (d.day % 10 == 2)
                  ? "nd"
                  : (d.day % 10 == 3)
                      ? "rd"
                      : "th";
      return "${weekdays[d.weekday - 1]}, ${months[d.month - 1]} $dayStr$suffix";
    }

    if (start != null && end != null) {
      return "${formatSingle(start)} — ${formatSingle(end)}";
    } else if (start != null) {
      return formatSingle(start);
    } else {
      return formatSingle(end!);
    }
  }

  String _formatShortDate(DateTime? d) {
    if (d == null) return "Select";
    return "${d.month}/${d.day}";
  }

  Widget _buildMinimalLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: context.onSurfaceVariant.withAlpha(170),
      ),
    );
  }

  Widget _buildMinimalInput({
    required TextEditingController controller,
    String? hintText,
    String? prefixText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: context.text.bodyMedium?.copyWith(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: context.text.bodyMedium?.copyWith(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w600,
          color: context.onSurfaceVariant,
        ),
        hintStyle: context.text.bodySmall?.copyWith(
          fontSize: 12.5.sp,
          color: context.onSurfaceVariant.withAlpha(120),
        ),
        filled: true,
        fillColor: context.mutedBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: maxLines > 1 ? 12.h : 10.h,
        ),
      ),
    );
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

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.onSurface,
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

  Future<void> _deleteAccommodation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Accommodation"),
        content: const Text("Are you sure you want to remove this lodging?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    AppToast.success("Deleting accommodation...");
    final res = await _apiService.delete<dynamic>(
      "/Accomodation/$id",
      fromJson: (d) => d,
    );

    if (res is Success) {
      AppToast.success("Accommodation deleted");
      _fetchAccommodations();
    } else if (res is Failure) {
      AppToast.error(res.message);
    } else {
      AppToast.error("Failed to delete accommodation");
    }
  }

  Future<void> _showAccommodationDetails(AccommodationModel baseModel) async {
    if (baseModel.id == null) {
      _showEditAccommodationDialog(baseModel);
      return;
    }

    AppToast.success("Loading details...");
    AccommodationModel? latestModel;
    try {
      final res = await _apiService.get<dynamic>(
        "/Accomodation/${baseModel.id}",
        fromJson: (d) => d,
      );
      if (res is Success && res.data != null) {
        final raw = res.data;
        final map = (raw is Map<String, dynamic> && raw["data"] is Map<String, dynamic>)
            ? raw["data"] as Map<String, dynamic>
            : (raw is Map<String, dynamic> ? raw : null);
        if (map != null) {
          latestModel = AccommodationModel.fromJson(map);
        }
      }
    } catch (e) {
      debugPrint("Failed to load accommodation details: $e");
    }

    final model = latestModel ?? baseModel;
    if (!mounted) return;
    _showEditAccommodationDialog(model);
  }

  void _showEditAccommodationDialog(AccommodationModel model) {
    final nameController = TextEditingController(text: model.name);
    final addressController = TextEditingController(text: model.address);
    final bookingRefController =
        TextEditingController(text: model.bookingReference);
    final costController = TextEditingController(
      text: model.cost > 0 ? model.cost.toStringAsFixed(0) : "",
    );
    final notesController = TextEditingController(text: model.notes);

    DateTime checkIn = model.checkInDate ?? DateTime.now();
    DateTime checkOut =
        model.checkOutDate ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              backgroundColor: context.surface,
              insetPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bed_rounded,
                                color: const Color(0xFF6D28D9),
                                size: 22.sp,
                              ),
                              8.w.horizontalSpace,
                              Text(
                                "Hotels and lodging",
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17.sp,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      16.h.verticalSpace,

                      // Field: HOTEL OR LODGING ADDRESS
                      _buildMinimalLabel("HOTEL OR LODGING ADDRESS"),
                      6.h.verticalSpace,
                      _buildMinimalInput(
                        controller: nameController,
                        hintText: "Hotel or lodging name / address",
                      ),
                      if (addressController.text.isNotEmpty &&
                          addressController.text != nameController.text) ...[
                        4.h.verticalSpace,
                        Text(
                          addressController.text,
                          style: context.text.bodySmall?.copyWith(
                            fontSize: 11.5.sp,
                            color: context.onSurfaceVariant,
                          ),
                        ),
                      ],
                      14.h.verticalSpace,

                      // 2-Column Row: CHECK-IN and CHECK-OUT
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMinimalLabel("CHECK-IN"),
                                6.h.verticalSpace,
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: checkIn,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setModalState(() => checkIn = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    height: 44.h,
                                    alignment: Alignment.centerLeft,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 14.w),
                                    decoration: BoxDecoration(
                                      color: context.mutedBackground,
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      _formatShortDate(checkIn),
                                      style: context.text.bodyMedium?.copyWith(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          12.w.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMinimalLabel("CHECK-OUT"),
                                6.h.verticalSpace,
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: checkOut,
                                      firstDate: checkIn,
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setModalState(() => checkOut = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    height: 44.h,
                                    alignment: Alignment.centerLeft,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 14.w),
                                    decoration: BoxDecoration(
                                      color: context.mutedBackground,
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      _formatShortDate(checkOut),
                                      style: context.text.bodyMedium?.copyWith(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      14.h.verticalSpace,

                      // 2-Column Row: CONFIRMATION # and COST
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMinimalLabel("CONFIRMATION #"),
                                6.h.verticalSpace,
                                _buildMinimalInput(
                                  controller: bookingRefController,
                                  hintText: "6181839458",
                                ),
                              ],
                            ),
                          ),
                          12.w.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMinimalLabel("COST"),
                                6.h.verticalSpace,
                                _buildMinimalInput(
                                  controller: costController,
                                  hintText: "Add cost",
                                  keyboardType: TextInputType.number,
                                  prefixText: "${model.currency ?? '\$'} ",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      14.h.verticalSpace,

                      // Field: NOTES
                      _buildMinimalLabel("NOTES"),
                      6.h.verticalSpace,
                      _buildMinimalInput(
                        controller: notesController,
                        hintText: "Confirmation #, Reservation name, etc.",
                        maxLines: 4,
                      ),
                      18.h.verticalSpace,

                      // Bottom Toolbar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.map_outlined,
                                  size: 20.sp,
                                  color: context.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  final query = Uri.encodeComponent(
                                    addressController.text.isNotEmpty
                                        ? addressController.text
                                        : nameController.text,
                                  );
                                  final uri = Uri.parse(
                                    "https://www.google.com/maps/search/?api=1&query=$query",
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                              ),
                              if (model.bookingUrl != null &&
                                  model.bookingUrl!.isNotEmpty)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.open_in_new_rounded,
                                    size: 19.sp,
                                    color: context.onSurfaceVariant,
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.tryParse(model.bookingUrl!);
                                    if (uri != null &&
                                        await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),
                              if (model.confirmationDocumentUrl != null &&
                                  model.confirmationDocumentUrl!.isNotEmpty)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.attach_file_rounded,
                                    size: 20.sp,
                                    color: context.onSurfaceVariant,
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.tryParse(
                                      model.confirmationDocumentUrl!,
                                    );
                                    if (uri != null &&
                                        await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              if (model.id != null && model.id!.isNotEmpty)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 21.sp,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    _deleteAccommodation(model.id!);
                                  },
                                ),
                              8.w.horizontalSpace,
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 22.w,
                                    vertical: 10.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) return;
                                  Navigator.pop(dialogCtx);

                                  final updated = model.copyWith(
                                    name: name,
                                    address: addressController.text.trim(),
                                    bookingReference:
                                        bookingRefController.text.trim(),
                                    cost: double.tryParse(
                                          costController.text.trim(),
                                        ) ??
                                        0.0,
                                    notes: notesController.text.trim(),
                                    checkInDate: checkIn,
                                    checkOutDate: checkOut,
                                  );

                                  AppToast.success("Saving changes...");
                                  final res = await _apiService.put<dynamic>(
                                    "/Accomodation/${model.id}",
                                    data: updated.toJson(),
                                    fromJson: (d) => d,
                                  );

                                  if (res is Success) {
                                    AppToast.success("Accommodation updated!");
                                    _fetchAccommodations();
                                  } else if (res is Failure) {
                                    AppToast.error(res.message);
                                  } else {
                                    AppToast.error(
                                      "Failed to update accommodation",
                                    );
                                  }
                                },
                                child: Text(
                                  "Save",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5.sp,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildAccommodationCard(AccommodationModel acc) {
    final hasConfirmation =
        acc.bookingReference != null && acc.bookingReference!.trim().isNotEmpty;
    final hasNotes = acc.notes != null && acc.notes!.trim().isNotEmpty;
    final hasAddress = acc.address != null && acc.address!.trim().isNotEmpty;

    return InkWell(
      onTap: () => _showAccommodationDetails(acc),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderColor.withAlpha(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Purple Bed Icon Badge
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.bed_rounded,
                      color: const Color(0xFF6D28D9),
                      size: 22.sp,
                    ),
                  ),
                ),
                12.w.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc.name.isNotEmpty ? acc.name : "Accommodation",
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: context.onSurface,
                        ),
                      ),
                      4.h.verticalSpace,
                      if (hasAddress)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: acc.address!));
                            AppToast.success("Address copied");
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  acc.address!,
                                  style: context.text.bodySmall?.copyWith(
                                    fontSize: 12.sp,
                                    color: context.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              4.w.horizontalSpace,
                              Icon(
                                Icons.content_copy_rounded,
                                size: 12.sp,
                                color: context.onSurfaceVariant.withAlpha(180),
                              ),
                            ],
                          ),
                        ),
                      4.h.verticalSpace,
                      Text(
                        _formatDateRange(acc.checkInDate, acc.checkOutDate),
                        style: context.text.bodySmall?.copyWith(
                          fontSize: 11.5.sp,
                          color: context.onSurfaceVariant.withAlpha(190),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action: attachment / edit
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (acc.confirmationDocumentUrl != null &&
                        acc.confirmationDocumentUrl!.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.attach_file_rounded,
                          size: 20.sp,
                          color: context.onSurfaceVariant,
                        ),
                        onPressed: () async {
                          final uri =
                              Uri.tryParse(acc.confirmationDocumentUrl!);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18.sp,
                        color: context.onSurfaceVariant,
                      ),
                      onPressed: () => _showEditAccommodationDialog(acc),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Import Confirmation Banner
          if (hasConfirmation)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: const Color(0xFF4C1D95),
                      size: 18.sp,
                    ),
                    8.w.horizontalSpace,
                    Expanded(
                      child: Text(
                        "Successfully imported. Does everything look right?",
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF312E81),
                        ),
                      ),
                    ),
                    8.w.horizontalSpace,
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 14.sp,
                          color: const Color(0xFF312E81),
                        ),
                        onPressed: () => AppToast.success("Confirmed!"),
                      ),
                    ),
                    6.w.horizontalSpace,
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.thumb_down_alt_outlined,
                          size: 14.sp,
                          color: const Color(0xFF312E81),
                        ),
                        onPressed: () => _showEditAccommodationDialog(acc),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Data Points Section (Small uppercase labels, clean values)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasConfirmation) ...[
                  Text(
                    "CONFIRMATION #",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: context.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                  4.h.verticalSpace,
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: acc.bookingReference!),
                      );
                      AppToast.success("Confirmation # copied");
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          acc.bookingReference!,
                          style: context.text.bodyMedium?.copyWith(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: context.onSurface,
                          ),
                        ),
                        6.w.horizontalSpace,
                        Icon(
                          Icons.content_copy_rounded,
                          size: 13.sp,
                          color: context.onSurfaceVariant.withAlpha(160),
                        ),
                      ],
                    ),
                  ),
                  12.h.verticalSpace,
                ],

                if (acc.cost > 0) ...[
                  Text(
                    "COST",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: context.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                  4.h.verticalSpace,
                  Text(
                    "${acc.currency ?? 'USD'} ${acc.cost.toStringAsFixed(0)}",
                    style: context.text.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: context.onSurface,
                    ),
                  ),
                  12.h.verticalSpace,
                ],

                if (hasNotes) ...[
                  Text(
                    "NOTES",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: context.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                  4.h.verticalSpace,
                  Text(
                    acc.notes!,
                    style: context.text.bodySmall?.copyWith(
                      fontSize: 11.5.sp,
                      height: 1.45,
                      color: context.onSurface.withAlpha(220),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _showTransportDetails(TripTransportModel baseModel) async {
    if (baseModel.id == null) return;

    AppToast.success("Loading details...");
    TripTransportModel? latestModel;
    try {
      final res = await _apiService.get<dynamic>(
        "/TripTransports/${baseModel.id}",
        fromJson: (d) => d,
      );
      if (res is Success && res.data != null) {
        final raw = res.data;
        final map = (raw is Map<String, dynamic> && raw["data"] is Map<String, dynamic>)
            ? raw["data"] as Map<String, dynamic>
            : (raw is Map<String, dynamic> ? raw : null);
        if (map != null) {
          latestModel = TripTransportModel.fromJson(map);
        }
      }
    } catch (e) {
      debugPrint("Failed to load transport details: $e");
    }

    final model = latestModel ?? baseModel;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${model.type} Details"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (model.provider != null && model.provider!.isNotEmpty) ...[
                  Text(
                    "Provider / Airline:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(model.provider!),
                  12.h.verticalSpace,
                ],
                if (model.departureLocation != null &&
                    model.arrivalLocation != null) ...[
                  Text(
                    "Route:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text("${model.departureLocation} ➔ ${model.arrivalLocation}"),
                  12.h.verticalSpace,
                ],
                Text(
                  "Cost:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                Text("\$${model.cost}"),
                12.h.verticalSpace,
                if (model.notes != null && model.notes!.isNotEmpty) ...[
                  Text(
                    "Notes:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(model.notes!),
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditTransportDialog(model);
              },
              child: const Text("Edit"),
            ),
          ],
        );
      },
    );
  }

  void _showEditTransportDialog(TripTransportModel model) {
    final providerController = TextEditingController(text: model.provider);
    final departureController = TextEditingController(
      text: model.departureLocation,
    );
    final arrivalController = TextEditingController(
      text: model.arrivalLocation,
    );
    final costController = TextEditingController(text: model.cost.toString());
    final notesController = TextEditingController(text: model.notes);
    String transportType = model.type;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                            "Edit Transport",
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

                      _buildDropdownField(
                        value: transportType,
                        items: ["Flight", "Train", "Bus", "Car", "Ferry"],
                        label: "Transport Type",
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => transportType = val);
                          }
                        },
                      ),
                      _buildFormField(controller: providerController, label: "Provider / Airline"),
                      _buildFormField(controller: departureController, label: "Departure Location"),
                      _buildFormField(controller: arrivalController, label: "Arrival Location"),
                      _buildFormField(controller: costController, label: "Cost (\$)", keyboardType: TextInputType.number),
                      _buildFormField(controller: notesController, label: "Notes", maxLines: 3),

                      20.h.verticalSpace,

                      SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);

                            final updated = TripTransportModel(
                              id: model.id,
                              tripId: model.tripId,
                              type: transportType,
                              provider: providerController.text.trim(),
                              departureLocation: departureController.text.trim(),
                              arrivalLocation: arrivalController.text.trim(),
                              cost: double.tryParse(costController.text.trim()) ?? 0.0,
                              notes: notesController.text.trim(),
                              currency: model.currency,
                              seatOrCabin: model.seatOrCabin,
                              departureDatetime: model.departureDatetime,
                              arrivalDatetime: model.arrivalDatetime,
                              bookingReference: model.bookingReference,
                            );

                            AppToast.success("Saving changes...");
                            final res = await _apiService.put<dynamic>(
                              "/TripTransports/${model.id}",
                              data: updated.toJson(),
                              fromJson: (d) => d,
                            );

                            if (res is Success) {
                              AppToast.success("Transport updated!");
                              _fetchTransports();
                            } else if (res is Failure) {
                              AppToast.error(res.message);
                            } else {
                              AppToast.error("Failed to update transport");
                            }
                          },
                          child: Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                        ),
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
  Widget build(BuildContext context) {
    return Container(
      height: 0.75.sh,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          12.h.verticalSpace,
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          16.h.verticalSpace,
          TabBar(
            controller: _tabController,
            labelColor: context.primary,
            unselectedLabelColor: context.onSurfaceVariant,
            indicatorColor: context.primary,
            tabs: const [
              Tab(text: "Accommodations"),
              Tab(text: "Transports"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Accommodations Tab
                _loadingAccommodations
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: _accommodations.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.bed_rounded,
                                          size: 48.sp,
                                          color: context.onSurfaceVariant
                                              .withAlpha(80),
                                        ),
                                        12.h.verticalSpace,
                                        Text(
                                          "No lodgings added yet",
                                          style: context.text.bodyMedium
                                              ?.copyWith(
                                                color: context.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16.w),
                                    itemCount: _accommodations.length,
                                    separatorBuilder: (_, __) =>
                                        14.h.verticalSpace,
                                    itemBuilder: (context, index) {
                                      final acc = _accommodations[index];
                                      return _buildAccommodationCard(acc);
                                    },
                                  ),
                          ),
                          // "+ Add another lodging" button
                          Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                            child: InkWell(
                              onTap: () => _showAddBookingOptions(
                                context,
                                "accommodation",
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 14.h,
                                  horizontal: 16.w,
                                ),
                                decoration: BoxDecoration(
                                  color: context.mutedBackground,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: context.borderColor.withAlpha(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 20.sp,
                                      color: context.onSurface,
                                    ),
                                    8.w.horizontalSpace,
                                    Text(
                                      "Add another lodging",
                                      style: context.text.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.sp,
                                        color: context.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                // Transports Tab
                _loadingTransports
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: _transports.isEmpty
                                ? Center(
                                    child: Text(
                                      "No transports added yet",
                                      style: context.text.bodyMedium?.copyWith(
                                        color: context.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16.w),
                                    itemCount: _transports.length,
                                    separatorBuilder: (_, __) =>
                                        12.h.verticalSpace,
                                    itemBuilder: (context, index) {
                                      final t = _transports[index];
                                      return InkWell(
                                        onTap: () => _showTransportDetails(t),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(14.w),
                                          decoration: BoxDecoration(
                                            color: context.mutedBackground,
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                t.type == "Flight"
                                                    ? Icons
                                                          .flight_takeoff_rounded
                                                    : Icons
                                                          .directions_transit_rounded,
                                                color: context.primary,
                                                size: 28.sp,
                                              ),
                                              12.w.horizontalSpace,
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${t.type}${t.provider != null && t.provider!.isNotEmpty ? " • ${t.provider}" : ""}",
                                                      style: context
                                                          .text
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    if (t.departureLocation !=
                                                            null &&
                                                        t.arrivalLocation !=
                                                            null)
                                                      Text(
                                                        "${t.departureLocation} ➔ ${t.arrivalLocation}",
                                                        style: context
                                                            .text
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: context
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                "\$${t.cost}",
                                                style: context.text.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: context.primary,
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
                            padding: EdgeInsets.all(16.w),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primary,
                                minimumSize: Size(double.infinity, 48.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                              ),
                              onPressed: () => _showAddBookingOptions(context, "transport"),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "Add Transport",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBookingOptions(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Add ${type == "accommodation" ? "Accommodation" : "Transport"}",
                textAlign: TextAlign.center,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              20.h.verticalSpace,
              // Email forward option card
              InkWell(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEmailForwardingInstructions(type);
                },
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.mutedBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: context.borderColor.withAlpha(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: context.primary.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          color: context.primary,
                          size: 24.sp,
                        ),
                      ),
                      16.w.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Forward Confirmation Email",
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            4.h.verticalSpace,
                            Text(
                              "Forward confirmation emails to wandersoulstechnologies05@gmail.com",
                              style: context.text.bodySmall?.copyWith(
                                color: context.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.onSurfaceVariant,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              12.h.verticalSpace,
              // Manual entry option card
              InkWell(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pop(context);
                  context.push(
                    '/AddBookingFormScreen',
                    extra: {
                      'tripId': widget.tripId,
                      'bookingType': type,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.mutedBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: context.borderColor.withAlpha(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: Colors.green,
                          size: 24.sp,
                        ),
                      ),
                      16.w.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add Manually",
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            4.h.verticalSpace,
                            Text(
                              "Enter details and upload tickets manually",
                              style: context.text.bodySmall?.copyWith(
                                color: context.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.onSurfaceVariant,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              16.h.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  void _showEmailForwardingInstructions(String type) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            "Auto Import Bookings",
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Simply forward your booking confirmation email (from airlines, Booking.com, Airbnb, Expedia, etc.) to:",
                style: context.text.bodyMedium,
              ),
              16.h.verticalSpace,
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      color: context.primary,
                      size: 16.sp,
                    ),
                    8.w.horizontalSpace,
                    Text(
                      "wandersoulstechnologies05@gmail.com",
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
              ),
              16.h.verticalSpace,
              Text(
                "We will automatically parse the booking details, add it to your itinerary and sync it to your app in a few minutes!",
                style: context.text.bodySmall?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Got It!"),
            ),
          ],
        );
      },
    );
  }
}
