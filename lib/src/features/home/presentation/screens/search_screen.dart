import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';

import 'package:wonder_souls/src/config/utils/common_widgets/app_search_bar.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/staggered_fade_slide.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_details.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const String routeName = "/SearchScreen";

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService service = sl<ApiService>();

  final TextEditingController _searchController = TextEditingController();

  Timer? debounce;

  List<PlaceModel> places = [];

  bool isLoading = false;

  void onSearch(String value) {
    if (debounce?.isActive ?? false) {
      debounce?.cancel();
    }

    debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.trim().isEmpty) {
        setState(() {
          places.clear();
          isLoading = false;
        });
        return;
      }

      setState(() {
        isLoading = true;
      });

      final result = await service.getLocations(1, 10, value);

      result.fold(
        (failure) {
          setState(() {
            places = [];
            isLoading = false;
          });
        },
        (success) {
          setState(() {
            places = success;
            isLoading = false;
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    debounce?.cancel();
    super.dispose();
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Row(
        children: [
          /// BACK BUTTON
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.sp,
                color: context.colors.onSurface,
              ),
            ),
          ),

          12.w.horizontalSpace,

          /// SEARCH BAR — using consistent AppSearchBar
          Expanded(
            child: AppSearchBar(
              hintText: "Search destinations...",
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear icon
                onSearch(value);
              },
              onClear: () {
                _searchController.clear();
                setState(() {
                  places.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(PlaceModel place, int index) {
    return StaggeredFadeSlide(
      index: index,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DestinationDetailsScreen(place: place),
            ),
          );
        },
        child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.mutedBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: context.borderColor.withAlpha(20),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: place.placeId,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.network(
                  "https://picsum.photos/200?random=$index",
                  width: 72.w,
                  height: 72.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: context.shimmerBase,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: context.colors.onSurfaceVariant.withAlpha(100),
                        size: 24.sp,
                      ),
                    );
                  },
                ),
              ),
            ),

            14.w.horizontalSpace,

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),

                  6.h.verticalSpace,

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14.sp,
                        color: context.colors.primary,
                      ),

                      4.w.horizontalSpace,

                      Expanded(
                        child: Text(
                          place.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            10.w.horizontalSpace,

            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryTint,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    ),);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.primary.withAlpha(15),
                    context.primary.withAlpha(8),
                  ],
                ),
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                size: 52.sp,
                color: context.colors.primary,
              ),
            ),

            24.h.verticalSpace,

            Text(
              "Discover Amazing Places",
              textAlign: TextAlign.center,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),

            12.h.verticalSpace,

            Text(
              "Search cities, countries and tourist attractions around the world.",
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            if (places.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 8.h),
                child: Row(
                  children: [
                    Text(
                      "${places.length} destinations found",
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : places.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                      itemCount: places.length,
                      separatorBuilder: (_, __) => 12.h.verticalSpace,
                      itemBuilder: (context, index) {
                        final place = places[index];

                        return _buildPlaceCard(place, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
