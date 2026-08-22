import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/accommodation_model.dart';
import 'package:wonder_souls/src/features/trips/model/trip_transport_model.dart';

class TripBookingsSheet extends StatefulWidget {
  final String tripId;

  const TripBookingsSheet({super.key, required this.tripId});

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
    _tabController = TabController(length: 2, vsync: this);
    _fetchAccommodations();
    _fetchTransports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccommodations() async {
    setState(() => _loadingAccommodations = true);
    try {
      final result = await _apiService.get<List<dynamic>>(
        "/Accomodation",
        fromJson: (json) => json as List<dynamic>,
      );

      if (result is Success<List<dynamic>>) {
        final List<AccommodationModel> items = result.data
            .map((e) => AccommodationModel.fromJson(e as Map<String, dynamic>))
            .where((acc) => acc.tripId == widget.tripId)
            .toList();

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
      final result = await _apiService.get<List<dynamic>>(
        "/TripTransports",
        fromJson: (json) => json as List<dynamic>,
      );

      if (result is Success<List<dynamic>>) {
        final List<TripTransportModel> items = result.data
            .map((e) => TripTransportModel.fromJson(e as Map<String, dynamic>))
            .where((t) => t.tripId == widget.tripId)
            .toList();

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

  void _showAddAccommodationDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                        "Add Accommodation",
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

                  // Fields
                  _buildFormField(controller: nameController, label: "Hotel / Place Name"),
                  _buildFormField(controller: addressController, label: "Address"),
                  _buildFormField(controller: costController, label: "Cost (\$)", keyboardType: TextInputType.number),

                  20.h.verticalSpace,

                  // Save button
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
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(context);

                        final model = AccommodationModel(
                          tripId: widget.tripId,
                          name: name,
                          address: addressController.text.trim(),
                          cost: double.tryParse(costController.text.trim()) ?? 0.0,
                        );

                        AppToast.success("Saving accommodation...");
                        final res = await _apiService.post<dynamic>(
                          "/Accomodation",
                          data: model.toJson(),
                          fromJson: (d) => d,
                        );

                        if (res is Success) {
                          AppToast.success("Accommodation added!");
                          _fetchAccommodations();
                        } else {
                          AppToast.error("Failed to add accommodation");
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
  }

  void _showAddTransportDialog() {
    final providerController = TextEditingController();
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final costController = TextEditingController();
    String transportType = "Flight";

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
                            "Add Transport",
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
                      _buildFormField(controller: fromController, label: "Departure Location"),
                      _buildFormField(controller: toController, label: "Arrival Location"),
                      _buildFormField(controller: costController, label: "Cost (\$)", keyboardType: TextInputType.number),

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

                            final model = TripTransportModel(
                              tripId: widget.tripId,
                              type: transportType,
                              provider: providerController.text.trim(),
                              departureLocation: fromController.text.trim(),
                              arrivalLocation: toController.text.trim(),
                              cost: double.tryParse(costController.text.trim()) ?? 0.0,
                            );

                            AppToast.success("Saving transport...");
                            final res = await _apiService.post<dynamic>(
                              "/TripTransports",
                              data: model.toJson(),
                              fromJson: (d) => d,
                            );

                            if (res is Success) {
                              AppToast.success("Transport added!");
                              _fetchTransports();
                            } else {
                              AppToast.error("Failed to add transport");
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

  Future<void> _showAccommodationDetails(AccommodationModel baseModel) async {
    if (baseModel.id == null) return;

    AppToast.success("Loading details...");
    AccommodationModel? latestModel;
    try {
      final res = await _apiService.get<dynamic>(
        "/Accomodation/${baseModel.id}",
        fromJson: (d) => d,
      );
      if (res is Success && res.data != null) {
        latestModel = AccommodationModel.fromJson(res.data["data"] ?? res.data);
      }
    } catch (e) {
      debugPrint("Failed to load accommodation details: $e");
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
                if (model.address != null && model.address!.isNotEmpty) ...[
                  Text(
                    "Address:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(model.address!),
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
                _showEditAccommodationDialog(model);
              },
              child: const Text("Edit"),
            ),
          ],
        );
      },
    );
  }

  void _showEditAccommodationDialog(AccommodationModel model) {
    final nameController = TextEditingController(text: model.name);
    final addressController = TextEditingController(text: model.address);
    final costController = TextEditingController(text: model.cost.toString());
    final notesController = TextEditingController(text: model.notes);

    showDialog(
      context: context,
      builder: (context) {
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
                        "Edit Accommodation",
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

                  _buildFormField(controller: nameController, label: "Name"),
                  _buildFormField(controller: addressController, label: "Address"),
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
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(context);

                        final updated = AccommodationModel(
                          id: model.id,
                          tripId: model.tripId,
                          name: name,
                          address: addressController.text.trim(),
                          cost: double.tryParse(costController.text.trim()) ?? 0.0,
                          notes: notesController.text.trim(),
                          type: model.type,
                          bookingReference: model.bookingReference,
                          bookingUrl: model.bookingUrl,
                          confirmationDocumentUrl: model.confirmationDocumentUrl,
                          phone: model.phone,
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
                        } else {
                          AppToast.error("Failed to update accommodation");
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
        latestModel = TripTransportModel.fromJson(res.data["data"] ?? res.data);
      }
    } catch (e) {
      debugPrint("Failed to load accommodation details: $e");
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
                                    child: Text(
                                      "No accommodations added yet",
                                      style: context.text.bodyMedium?.copyWith(
                                        color: context.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16.w),
                                    itemCount: _accommodations.length,
                                    separatorBuilder: (_, __) =>
                                        12.h.verticalSpace,
                                    itemBuilder: (context, index) {
                                      final acc = _accommodations[index];
                                      return InkWell(
                                        onTap: () =>
                                            _showAccommodationDetails(acc),
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
                                                Icons.hotel_rounded,
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
                                                      acc.name,
                                                      style: context
                                                          .text
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    if (acc.address != null &&
                                                        acc.address!.isNotEmpty)
                                                      Text(
                                                        acc.address!,
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
                                                "\$${acc.cost}",
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
                              onPressed: _showAddAccommodationDialog,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "Add Accommodation",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
                              onPressed: _showAddTransportDialog,
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
}
