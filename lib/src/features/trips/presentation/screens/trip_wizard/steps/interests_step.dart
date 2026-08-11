import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class InterestsStep extends StatelessWidget {
  const InterestsStep({super.key});

  final List<String> _interests = const [
    "Adventure Travel 🏕️",
    "City Breaks 🏙️",
    "Cultural Exploration 🏛️",
    "Glamping ⛺",
    "Beach Vacations 🏖️",
    "Nature Escapes 🌲",
    "Relaxing Getaways 💆",
    "Road Trips 🚗",
    "Food Tourism 🍣",
    "Backpacking 🎒",
    "Cruise Vacations 🚢",
    "Staycations 🏠",
    "Skiing/Snowboarding ⛷️",
    "Wine Tours 🍷",
    "Wildlife Safaris 🦁",
    "Art Galleries 🖼️",
    "Historical Sites 🏺",
    "Eco-Tourism 🌿",
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripWizardCubit, TripWizardState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.h.verticalSpace,
              Text(
                "Tailor your adventure to your tastes 🌟",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              8.h.verticalSpace,
              Text(
                "Select your travel preferences to customize your trip plan.",
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              32.h.verticalSpace,
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: _interests.map((interest) {
                      final isSelected = state.interests.contains(interest);
                      return ChoiceChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (_) {
                          context.read<TripWizardCubit>().toggleInterest(
                            interest,
                          );
                        },
                        selectedColor: context.colors.primary,
                        backgroundColor: context.colors.surface,
                        labelStyle: context.text.bodyMedium?.copyWith(
                          color: isSelected
                              ? context.colors.onPrimary
                              : context.colors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          side: BorderSide(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                          ),
                        ),
                        showCheckmark: false,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                child: CommonButton(
                  title: "Continue",
                  onPressed: state.interests.isEmpty
                      ? null
                      : () {
                          context.read<TripWizardCubit>().nextStep();
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
