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

  void _showAddAccommodationDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Accommodation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Hotel / Place Name",
                ),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Cost (\$)"),
              ),
            ],
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
              child: const Text("Save"),
            ),
          ],
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
            return AlertDialog(
              title: const Text("Add Transport"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: transportType,
                      items: ["Flight", "Train", "Bus", "Car", "Ferry"]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => transportType = val);
                      },
                      decoration: const InputDecoration(
                        labelText: "Transport Type",
                      ),
                    ),
                    TextField(
                      controller: providerController,
                      decoration: const InputDecoration(
                        labelText: "Provider / Airline",
                      ),
                    ),
                    TextField(
                      controller: fromController,
                      decoration: const InputDecoration(
                        labelText: "Departure Location",
                      ),
                    ),
                    TextField(
                      controller: toController,
                      decoration: const InputDecoration(
                        labelText: "Arrival Location",
                      ),
                    ),
                    TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Cost (\$)"),
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
                  child: const Text("Save"),
                ),
              ],
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
        return AlertDialog(
          title: const Text("Edit Accommodation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Cost (\$)"),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: "Notes"),
              ),
            ],
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
              child: const Text("Save"),
            ),
          ],
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Transport"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(
                    labelText: "Provider / Airline",
                  ),
                ),
                TextField(
                  controller: departureController,
                  decoration: const InputDecoration(
                    labelText: "Departure Location",
                  ),
                ),
                TextField(
                  controller: arrivalController,
                  decoration: const InputDecoration(
                    labelText: "Arrival Location",
                  ),
                ),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Cost (\$)"),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: "Notes"),
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
                Navigator.pop(context);

                final updated = TripTransportModel(
                  id: model.id,
                  tripId: model.tripId,
                  type: model.type,
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
              child: const Text("Save"),
            ),
          ],
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
