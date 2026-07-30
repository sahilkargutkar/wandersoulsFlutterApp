import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';

import 'package:wonder_souls/src/config/utils/common_widgets/destination_card.dart';

import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';

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

  bool isLoading = false;

  bool isInitialLoading = true;

  bool hasMore = true;

  int page = 1;

  final int pageSize = 10;

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
    }

    setState(() {
      isLoading = true;
    });

    final result = await service.getLocations(page, pageSize, "");

    result.fold(
      (failure) {
        debugPrint(failure.message);

        setState(() {
          isLoading = false;
          isInitialLoading = false;
        });
      },

      (success) {
        setState(() {
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
          // Navigate to trip details
        },

        child: DestinationCard(
          imageUrl:
              "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",

          city: destination.name,

          country: destination.address,

          flagEmoji: "📍",

          place: destination,

          /// Full width card in list view
          cardWidth: MediaQuery.of(context).size.width - 40.w,
        ),
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
          'Popular Destinations',
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

      body: isInitialLoading
          ? _buildLoader()
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
                  /// PAGINATION LOADER
                  if (index >= destinations.length) {
                    return _buildLoader();
                  }

                  final destination = destinations[index];

                  return _buildDestinationCard(destination);
                },
              ),
            ),
    );
  }
}
