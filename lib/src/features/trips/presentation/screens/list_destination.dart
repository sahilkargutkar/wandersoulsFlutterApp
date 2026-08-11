import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';

import 'package:wonder_souls/src/config/utils/common_widgets/destination_card.dart';

import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_details.dart';

class ListDestination extends StatefulWidget {
  const ListDestination({super.key});

  static const String routeName = "/ListDestination";

  @override
  State<ListDestination> createState() => _ListDestinationState();
}

class _ListDestinationState extends State<ListDestination> {
  final ApiService service = sl<ApiService>();

  final ScrollController _scrollController = ScrollController();

  List<PlaceModel> destinations = [];
  List<dynamic> _curatedDestinations = [];
  bool isLoading = false;
  bool _loadingCurated = false;
  bool isInitialLoading = true;
  bool hasMore = true;
  int page = 1;
  final int pageSize = 10;
  String? _errorMessage;
  int _selectedTab =
      0; // 0 for Popular (Locations), 1 for Curated (Destinations)

  @override
  void initState() {
    super.initState();

    fetchDestinations();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !isLoading &&
          hasMore) {
        fetchDestinations();
      }
    });
  }

  Future<void> fetchDestinations({bool refresh = false}) async {
    if (isLoading) return;

    if (refresh) {
      page = 1;
      hasMore = true;
      destinations.clear();
      _errorMessage = null;
    }

    setState(() {
      isLoading = true;
    });

    final result = await service.getLocations(page, pageSize, "");

    result.fold(
      (failure) {
        debugPrint("fetchDestinations failure: ${failure.message}");

        setState(() {
          _errorMessage = failure.message;
          isLoading = false;
          isInitialLoading = false;
        });
      },

      (success) {
        setState(() {
          _errorMessage = null;
          if (success.isEmpty) {
            hasMore = false;
          } else {
            destinations.addAll(success);
            page++;
          }

          isLoading = false;
          isInitialLoading = false;
        });
      },
    );
  }

  Future<void> _fetchCuratedDestinations() async {
    setState(() {
      _loadingCurated = true;
      _errorMessage = null;
    });
    try {
      final res = await service.get<List<dynamic>>(
        "/Destinations",
        fromJson: (json) => json as List<dynamic>,
      );
      if (res is Success<List<dynamic>>) {
        setState(() {
          _curatedDestinations = res.data;
          _loadingCurated = false;
          isInitialLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load curated destinations";
          _loadingCurated = false;
          isInitialLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loadingCurated = false;
        isInitialLoading = false;
      });
    }
  }

  void _showCreateCuratedDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController(
      text:
          "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Suggest Curated Destination"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "City / Name"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Address / Country",
                  ),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: "Image URL"),
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

                final payload = {
                  "name": name,
                  "address": addressController.text.trim(),
                  "description": descController.text.trim(),
                  "imageUrl": imageController.text.trim(),
                };

                AppToast.success("Creating curated destination...");
                final res = await service.post<dynamic>(
                  "/Destinations/create-destination",
                  data: payload,
                  fromJson: (d) => d,
                );

                if (res is Success) {
                  AppToast.success("Destination created!");
                  _fetchCuratedDestinations();
                } else {
                  AppToast.error("Failed to create destination");
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _showEditCuratedDialog(Map<String, dynamic> item) {
    final nameController = TextEditingController(text: item["name"]);
    final addressController = TextEditingController(text: item["address"]);
    final descController = TextEditingController(text: item["description"]);
    final imageController = TextEditingController(text: item["imageUrl"]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Curated Destination"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "City / Name"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Address / Country",
                  ),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: "Image URL"),
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

                final payload = {
                  "name": name,
                  "address": addressController.text.trim(),
                  "description": descController.text.trim(),
                  "imageUrl": imageController.text.trim(),
                };

                AppToast.success("Saving changes...");
                final res = await service.put<dynamic>(
                  "/Destinations/${item["id"]}",
                  data: payload,
                  fromJson: (d) => d,
                );

                if (res is Success) {
                  AppToast.success("Destination updated!");
                  _fetchCuratedDestinations();
                } else {
                  AppToast.error("Failed to update destination");
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: CircularProgressIndicator(color: context.primary),
      ),
    );
  }

  Widget _buildDestinationCard(PlaceModel destination) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          context.push(DestinationDetailsScreen.routeName, extra: destination);
        },
        child: DestinationCard(
          imageUrl:
              "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",
          city: destination.name,
          country: destination.address,
          flagEmoji: "📍",
          place: destination,
          cardWidth: MediaQuery.of(context).size.width - 40.w,
        ),
      ),
    );
  }

  Widget _buildCuratedDestinationCard(Map<String, dynamic> item) {
    final destination = PlaceModel(
      placeId: item["id"] ?? "",
      name: item["name"] ?? "",
      address: item["address"] ?? "",
      description: item["description"] ?? "",
      rating: 4.8,
      userRatingsTotal: 120,
      types: ["curated"],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          context.push(DestinationDetailsScreen.routeName, extra: destination);
        },
        child: Stack(
          children: [
            DestinationCard(
              imageUrl: item["imageUrl"] != null && item["imageUrl"].isNotEmpty
                  ? item["imageUrl"]
                  : "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",
              city: destination.name,
              country: destination.address,
              flagEmoji: "📍",
              place: destination,
              cardWidth: MediaQuery.of(context).size.width - 40.w,
            ),
            Positioned(
              top: 12.h,
              right: 12.w,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18.r,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: context.primary,
                    size: 18.sp,
                  ),
                  onPressed: () => _showEditCuratedDialog(item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48.sp,
            color: context.colors.error,
          ),
          SizedBox(height: 12.h),
          Text(
            _errorMessage ?? "Error loading destinations",
            style: context.text.bodyLarge?.copyWith(
              color: context.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => fetchDestinations(refresh: true),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        leadingWidth: 62.w,
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(left: 20.w, top: 7.h, bottom: 7.h),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: context.onSurface,
              ),
            ),
          ),
        ),
        title: Text(
          'Destinations Directory',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w, top: 7.h, bottom: 7.h),
            child: GestureDetector(
              onTap: () {
                context.push(SearchScreen.routeName);
              },
              child: Container(
                width: 42.w,
                height: 42.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 20.sp,
                  color: context.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Popular Places")),
                    selected: _selectedTab == 0,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedTab = 0;
                        });
                      }
                    },
                  ),
                ),
                12.w.horizontalSpace,
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Curated Guides")),
                    selected: _selectedTab == 1,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedTab = 1;
                        });
                        _fetchCuratedDestinations();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? (isInitialLoading
                      ? _buildLoader()
                      : _errorMessage != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          color: context.primary,
                          onRefresh: () => fetchDestinations(refresh: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            itemCount: destinations.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= destinations.length) {
                                return _buildLoader();
                              }
                              final destination = destinations[index];
                              return _buildDestinationCard(destination);
                            },
                          ),
                        ))
                : (_loadingCurated
                      ? _buildLoader()
                      : Column(
                          children: [
                            Expanded(
                              child: _curatedDestinations.isEmpty
                                  ? Center(
                                      child: Text(
                                        "No curated guides suggested yet.",
                                        style: context.text.bodyMedium
                                            ?.copyWith(
                                              color: context.onSurfaceVariant,
                                            ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      color: context.primary,
                                      onRefresh: _fetchCuratedDestinations,
                                      child: ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                          vertical: 12.h,
                                        ),
                                        itemCount: _curatedDestinations.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                              _curatedDestinations[index];
                                          return _buildCuratedDestinationCard(
                                            item,
                                          );
                                        },
                                      ),
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
                                onPressed: _showCreateCuratedDialog,
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Suggest Curated Destination",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
          ),
        ],
      ),
    );
  }
}
