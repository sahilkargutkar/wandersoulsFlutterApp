import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/map_view.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/date_tabs.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/expandable_place_card.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/circular_icon.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip? trip;
  static const String routeName = "/TripDetailsScreen";

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late final Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip ?? sampleTrip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildTripHeader(context),
                SizedBox(height: 60.h, child: _buildTabs(context)),
                _buildPlacesList(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          print(_trip.name);
        },
        backgroundColor: context.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.h,
      pinned: true,
      backgroundColor: context.surface,

      //  // 👇 Title appears ONLY when collapsed
      // title: Text(
      //   widget.trip?.name ?? '',
      //   maxLines: 1,
      //   overflow: TextOverflow.ellipsis,
      //   style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      // ),
      leading: CircularIcon(
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 18.sp,
          color: context.onSurface,
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      actions: [
        CircularIcon(
          icon: Icon(Icons.share, size: 20.sp, color: context.onSurface),

          onTap: () => Navigator.pop(context),
        ),
        CircularIcon(
          icon: Icon(Icons.more_vert, size: 20.sp, color: context.onSurface),

          onTap: () => Navigator.pop(context),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _trip.imageUrl,

              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 64.sp, color: Colors.grey),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(10)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeader(BuildContext context) {
    return Container(
      color: context.surface,
      padding: EdgeInsets.all(20.w),
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
                      _trip.name,
                      style: context.titleLarge?.copyWith(fontSize: 20.sp),
                    ),
                    4.h.height,
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16.sp,
                          color: context.onSurface,
                        ),
                        4.w.width,
                        Text(
                          _trip.country,
                          style: context.bodyMedium?.copyWith(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: context.primary),
                onPressed: () {},
              ),
            ],
          ),
          16.h.height,
          Container(
            height: 150.h,
            decoration: BoxDecoration(
              color: Colors.green[200],
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: MapView(),

            //  Center(
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Icon(
            //         Icons.map_outlined,
            //         size: 48.sp,
            //         color: Colors.grey[400],
            //       ),
            //       8.h.height,
            //       Text(
            //         'Map View',
            //         style: context.text.bodySmall?.copyWith(
            //           color: Colors.grey[600],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ),
        ],
      ),
    );
  }

  List<String> tabs = ['December 16th', 'December 17th', "December 18"];
  Widget _buildTabs(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: tabs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) =>
            DateTabs(label: tabs[index], isSelected: index == 0),
        separatorBuilder: (BuildContext context, int index) => 8.w.width,
      ),
    );
  }

  Widget _buildPlacesList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: _trip.places.length,
      itemBuilder: (context, index) => ExpandablePlaceCard(
        place: _trip.places[index],
        icon: Icons.restaurant,
      ),
    );
  }
}
