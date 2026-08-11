import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class PartyStep extends StatelessWidget {
  const PartyStep({super.key});

  final List<Map<String, String>> _options = const [
    {
      "title": "Only Me 🧍‍♂️",
      "subtitle": "Traveling solo, just you.",
      "value": "solo",
    },
    {
      "title": "A Couple ❤️",
      "subtitle": "A romantic getaway for two.",
      "value": "couple",
    },
    {
      "title": "Family 👨‍👩‍👧",
      "subtitle": "Quality time with your loved ones.",
      "value": "family",
    },
    {
      "title": "Friends 🥂",
      "subtitle": "Adventure with your closest pals.",
      "value": "friends",
    },
    {
      "title": "Work 💼",
      "subtitle": "Business or corporate travel.",
      "value": "work",
    },
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
                "Who is going? 🧳",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              8.h.verticalSpace,
              Text(
                "Let's get started by selecting who you're traveling with.",
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              32.h.verticalSpace,
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => 12.h.verticalSpace,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = state.partyType == option["value"];

                    return InkWell(
                      onTap: () {
                        context.read<TripWizardCubit>().setPartyType(
                          option["value"]!,
                        );
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          color: isSelected
                              ? context.colors.primary.withValues(alpha: 0.05)
                              : Colors.transparent,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option["title"]!,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                            4.h.verticalSpace,
                            Text(
                              option["subtitle"]!,
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
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
                padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                child: CommonButton(
                  title: "Continue",
                  onPressed: state.partyType == null
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
