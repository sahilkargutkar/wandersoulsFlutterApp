import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/saved_trips_screen.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';


class ListDestination extends StatelessWidget {
  const ListDestination({super.key});
  static const String routeName = "/ListDestination";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        centerTitle: true,
        leading: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => Navigator.pop(context),
          child: SizedBox(
            width: 40.w,
            height: 40.w,
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_new, // better centered than arrow_back_ios
                size: 20.sp,
                color: context.onSurface,
              ),
            ),
          ),
        ),
        title: Text('Popular Destinations', style: context.titleLarge),
        actions: [
          // balances leading so title is truly centered
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
          
          ),
        ],
      ),
      body: SavedTripsScreen(

       
      ),
    );
  }
}
