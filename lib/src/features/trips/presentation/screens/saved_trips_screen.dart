import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_places_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/widgets/empty_saved_card.dart';
import '../widgets/destination_card_list.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedPlacesCubit, List<PlaceModel>>(
      builder: (context, savedPlaces) {
        if (savedPlaces.isEmpty) {
          return const EmptySavedCard();
        }
        return _buildTripList(context, savedPlaces);
      },
    );
  }

  Widget _buildTripList(BuildContext context, List<PlaceModel> savedPlaces) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: savedPlaces.length,
      itemBuilder: (_, index) {
        final place = savedPlaces[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DestinationCardList(
            imageUrl: place.googleMapsUrl ?? "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?q=80&w=1200",
            city: place.name,
            country: place.address,
            flagEmoji: "📍",
            place: place,
          ),
        );
      },
    );
  }
}
