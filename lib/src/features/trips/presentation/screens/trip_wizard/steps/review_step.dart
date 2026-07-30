import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

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
                "Review Summary",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              32.h.verticalSpace,
              Expanded(
                child: ListView(
                  children: [
                    _buildSection(
                      context,
                      icon: Icons.location_on_outlined,
                      title: "Destination",
                      value: state.destination?.name ?? "Unknown",
                      onEdit: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildSection(
                      context,
                      icon: Icons.notes_outlined,
                      title: "Trip Details",
                      value:
                          "Name: ${state.name ?? 'Unnamed'}\nDescription: ${state.description?.isNotEmpty == true ? state.description : 'None'}\nPrivacy: ${state.isPublic ? 'Public 🌍' : 'Private 🔒'}",
                      onEdit: () {
                        context.read<TripWizardCubit>().goToStep(0);
                      },
                    ),
                    _buildSection(
                      context,
                      icon: Icons.people_outline,
                      title: "Party",
                      value: _getPartyTitle(state.partyType ?? ""),
                      onEdit: () {
                        context.read<TripWizardCubit>().goToStep(1);
                      },
                    ),
                    _buildSection(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: "Trip Dates",
                      value:
                          "${_formatDate(state.startDate)} to ${_formatDate(state.endDate)}",
                      onEdit: () {
                        context.read<TripWizardCubit>().goToStep(2);
                      },
                    ),
                    _buildInterestsSection(context, state),
                    _buildSection(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Budget",
                      value: _getBudgetText(state),
                      onEdit: () {
                        context.read<TripWizardCubit>().goToStep(4);
                      },
                    ),
                    if (state.collaborators.isNotEmpty)
                      _buildSection(
                        context,
                        icon: Icons.group_add_outlined,
                        title: "Collaborators",
                        value:
                            "${state.collaborators.length} person(s) invited",
                        onEdit: () {
                          context.read<TripWizardCubit>().goToStep(5);
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                child: CommonButton(
                  title: "Create Trip",
                  onPressed: () {
                    context.read<TripWizardCubit>().saveTrip();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: context.colors.onSurfaceVariant),
          12.w.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                4.h.verticalSpace,
                Text(
                  value,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              size: 20.sp,
              color: context.colors.primary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(BuildContext context, TripWizardState state) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.star_border,
            size: 20.sp,
            color: context.colors.onSurfaceVariant,
          ),
          12.w.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${state.interests.length} Interests",
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                8.h.verticalSpace,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: state.interests
                      .map(
                        (i) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            color: context.colors.surface,
                            border: Border.all(
                              color: context.colors.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            i,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<TripWizardCubit>().goToStep(3);
            },
            icon: Icon(
              Icons.edit_outlined,
              size: 20.sp,
              color: context.colors.primary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String _getPartyTitle(String value) {
    switch (value) {
      case "solo":
        return "Only Me 🧍‍♂️";
      case "couple":
        return "A Couple ❤️";
      case "family":
        return "Family 👨‍👩‍👧";
      case "friends":
        return "Friends 🥂";
      case "work":
        return "Work 💼";
      default:
        return value;
    }
  }

  String _getBudgetTitle(String value) {
    switch (value) {
      case "cheap":
        return "Cheap 💰";
      case "balanced":
        return "Balanced ⚖️";
      case "luxury":
        return "Luxury 💎";
      case "flexible":
        return "Flexible 🔀";
      default:
        return value;
    }
  }

  String _getBudgetText(TripWizardState state) {
    String value = _getBudgetTitle(state.budgetLevel ?? "");
    if (state.totalEstimated > 0) {
      value +=
          " (${state.currency} ${state.totalEstimated.toStringAsFixed(0)})";

      final categoryDetails = <String>[];
      if (state.transportationBudget > 0) {
        categoryDetails.add(
          "Trans: ${state.currency} ${state.transportationBudget.toStringAsFixed(0)}",
        );
      }
      if (state.accommodationBudget > 0) {
        categoryDetails.add(
          "Acc: ${state.currency} ${state.accommodationBudget.toStringAsFixed(0)}",
        );
      }
      if (state.foodBudget > 0) {
        categoryDetails.add(
          "Food: ${state.currency} ${state.foodBudget.toStringAsFixed(0)}",
        );
      }
      if (state.activitiesBudget > 0) {
        categoryDetails.add(
          "Act: ${state.currency} ${state.activitiesBudget.toStringAsFixed(0)}",
        );
      }

      if (categoryDetails.isNotEmpty) {
        value += "\n" + categoryDetails.join(" · ");
      }
    }
    return value;
  }
}
