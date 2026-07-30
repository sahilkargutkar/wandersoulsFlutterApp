import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class DatesStep extends StatefulWidget {
  const DatesStep({super.key});

  @override
  State<DatesStep> createState() => _DatesStepState();
}

class _DatesStepState extends State<DatesStep> {
  DateTime _currentMonth = DateTime.now();

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
                "When will your adventure begin and end? 📅",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              8.h.verticalSpace,
              Text(
                "Choose the dates for your trip. This helps us plan the perfect itinerary for your travel period.",
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              32.h.verticalSpace,
              // Custom Calendar
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                            });
                          },
                          icon: Icon(Icons.chevron_left, color: context.colors.onSurface),
                        ),
                        Text(
                          _monthYearString(_currentMonth),
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                            });
                          },
                          icon: Icon(Icons.chevron_right, color: context.colors.onSurface),
                        ),
                      ],
                    ),
                    16.h.verticalSpace,
                    _buildDaysOfWeek(context),
                    16.h.verticalSpace,
                    Expanded(child: _buildCalendarGrid(context, state)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                child: CommonButton(
                  title: "Continue",
                  onPressed: state.startDate == null || state.endDate == null
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

  String _monthYearString(DateTime date) {
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return "${months[date.month - 1]} ${date.year}";
  }

  Widget _buildDaysOfWeek(BuildContext context) {
    const days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Text(
                d,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurfaceVariant,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, TripWizardState state) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startingWeekday = firstDayOfMonth.weekday; // 1=Monday, 7=Sunday

    int totalCells = daysInMonth + startingWeekday - 1;
    int rows = (totalCells / 7).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        if (index < startingWeekday - 1 || index >= totalCells) {
          return const SizedBox.shrink();
        }

        int day = index - startingWeekday + 2;
        DateTime date = DateTime(_currentMonth.year, _currentMonth.month, day);
        bool isSelectedStart = state.startDate != null && DateUtils.isSameDay(state.startDate, date);
        bool isSelectedEnd = state.endDate != null && DateUtils.isSameDay(state.endDate, date);
        bool isInRange = state.startDate != null &&
            state.endDate != null &&
            date.isAfter(state.startDate!) &&
            date.isBefore(state.endDate!);
        
        bool isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        Color bgColor = Colors.transparent;
        Color textColor = context.colors.onSurface;

        if (isSelectedStart || isSelectedEnd) {
          bgColor = context.colors.primary;
          textColor = context.colors.onPrimary;
        } else if (isInRange) {
          bgColor = context.colors.primary.withOpacity(0.15);
        } else if (isPast) {
          textColor = context.colors.onSurface.withOpacity(0.3);
        }

        return GestureDetector(
          onTap: isPast
              ? null
              : () {
                  final cubit = context.read<TripWizardCubit>();
                  if (state.startDate == null || (state.startDate != null && state.endDate != null)) {
                    cubit.setDates(date, null);
                  } else if (state.startDate != null && state.endDate == null) {
                    if (date.isBefore(state.startDate!)) {
                      cubit.setDates(date, state.startDate!);
                    } else {
                      cubit.setDates(state.startDate!, date);
                    }
                  }
                },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              color: bgColor,
              shape: (isSelectedStart || isSelectedEnd) ? BoxShape.circle : BoxShape.rectangle,
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: context.text.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: (isSelectedStart || isSelectedEnd) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
