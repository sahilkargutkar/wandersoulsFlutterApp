import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/static_data.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_explorer_screen.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/empty_saved_card.dart';
import '../widgets/destination_card_list.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return destinations.isEmpty ? EmptySavedCard() : _buildTripList(context);
  }

  Widget _buildTripList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: destinations.length,
      itemBuilder: (_, index) {
        final d = destinations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pushNamed(
                context,
                DestinationExplorerScreen.routeName,
                arguments: d,
              );
            },
            child: DestinationCardList(
              imageUrl: d["imageUrl"] ?? "",
              city: d["city"] ?? "",
              country: d["country"] ?? "",
              flagEmoji: d["flagEmoji"] ?? "",
            ),
          ),
        );
      },
    );
  }
}
