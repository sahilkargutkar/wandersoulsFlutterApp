import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_text_form_field.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class BudgetStep extends StatefulWidget {
  const BudgetStep({super.key});

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  late final TextEditingController _totalController;
  String _selectedCurrency = "USD";

  final List<Map<String, String>> _options = const [
    {
      "title": "Cheap 💰",
      "subtitle": "Budget-friendly, economical travel.",
      "value": "cheap",
    },
    {
      "title": "Balanced ⚖️",
      "subtitle": "Moderate spending for a balanced trip.",
      "value": "balanced",
    },
    {
      "title": "Luxury 💎",
      "subtitle": "High-end, indulgent experiences.",
      "value": "luxury",
    },
    {
      "title": "Flexible 🔀",
      "subtitle": "No budget restrictions.",
      "value": "flexible",
    },
  ];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<TripWizardCubit>();
    final state = cubit.state;

    _totalController = TextEditingController(text: state.totalEstimated > 0 ? state.totalEstimated.toStringAsFixed(0) : '');
    _selectedCurrency = state.currency.isNotEmpty ? state.currency : "USD";

    _totalController.addListener(_onTotalChanged);
  }

  void _onTotalChanged() {
    final total = double.tryParse(_totalController.text) ?? 0.0;
    final cubit = context.read<TripWizardCubit>();
    final state = cubit.state;

    if (total != state.totalEstimated) {
      cubit.setBudgetDetails(
        currency: _selectedCurrency,
        totalEstimated: total,
        transportation: state.transportationBudget,
        accommodation: state.accommodationBudget,
        food: state.foodBudget,
        activities: state.activitiesBudget,
      );
    }
  }

  void _onSliderChanged({
    double? trans,
    double? acc,
    double? food,
    double? act,
  }) {
    final cubit = context.read<TripWizardCubit>();
    final state = cubit.state;

    double newTrans = trans ?? state.transportationBudget;
    double newAcc = acc ?? state.accommodationBudget;
    double newFood = food ?? state.foodBudget;
    double newAct = act ?? state.activitiesBudget;

    double newTotal = state.totalEstimated;
    if (state.totalEstimated == 0) {
      newTotal = newTrans + newAcc + newFood + newAct;
      _totalController.text = newTotal > 0 ? newTotal.toStringAsFixed(0) : '';
    }

    cubit.setBudgetDetails(
      currency: _selectedCurrency,
      totalEstimated: newTotal,
      transportation: newTrans,
      accommodation: newAcc,
      food: newFood,
      activities: newAct,
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripWizardCubit, TripWizardState>(
      builder: (context, state) {
        final totalAllocated = state.transportationBudget + state.accommodationBudget + state.foodBudget + state.activitiesBudget;
        final exceeds = totalAllocated > state.totalEstimated && state.totalEstimated > 0;
        final double scale = exceeds ? totalAllocated : (state.totalEstimated > 0 ? state.totalEstimated : 1.0);

        final double transRatio = state.transportationBudget / scale;
        final double accRatio = state.accommodationBudget / scale;
        final double foodRatio = state.foodBudget / scale;
        final double actRatio = state.activitiesBudget / scale;
        final double unallocatedRatio = exceeds ? 0.0 : ((state.totalEstimated - totalAllocated) / scale);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.h.verticalSpace,
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Text(
                      "Set your trip budget 💰",
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    8.h.verticalSpace,
                    Text(
                      "Let us know your budget preference, and we'll craft an itinerary that suits your financial comfort.",
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    32.h.verticalSpace,
                    
                    // Options List
                    ..._options.map((option) {
                      final isSelected = state.budgetLevel == option["value"];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: InkWell(
                          onTap: () {
                            context.read<TripWizardCubit>().setBudgetLevel(option["value"]!);
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? context.colors.primary : context.colors.onSurface.withOpacity(0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              color: isSelected ? context.colors.primary.withOpacity(0.05) : Colors.transparent,
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
                        ),
                      );
                    }).toList(),

                    if (state.budgetLevel != null) ...[
                      24.h.verticalSpace,
                      Divider(color: context.colors.onSurface.withOpacity(0.1)),
                      16.h.verticalSpace,
                      Text(
                        "Estimated Budget Details 💳",
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      12.h.verticalSpace,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              dropdownColor: context.colors.surface,
                              style: context.text.bodyMedium?.copyWith(
                                color: context.colors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: "Currency",
                                filled: true,
                                fillColor: context.mutedBackground,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(
                                    color: context.borderColor.withAlpha(50),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(
                                    color: context.colors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              items: ["USD", "EUR", "INR", "GBP", "JPY", "AUD", "CAD"]
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCurrency = val;
                                  });
                                  final cubit = context.read<TripWizardCubit>();
                                  cubit.setBudgetDetails(
                                    currency: _selectedCurrency,
                                    totalEstimated: state.totalEstimated,
                                    transportation: state.transportationBudget,
                                    accommodation: state.accommodationBudget,
                                    food: state.foodBudget,
                                    activities: state.activitiesBudget,
                                  );
                                }
                              },
                            ),
                          ),
                          12.w.horizontalSpace,
                          Expanded(
                            flex: 3,
                            child: CommonTextFormField(
                              controller: _totalController,
                              hintText: "e.g., 2000",
                              labelText: "Total Budget",
                              keyboardType: TextInputType.number,
                              prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: context.colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      24.h.verticalSpace,
                      
                      // visual stacked allocator
                      Text(
                        "Budget Allocation Breakdown",
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      8.h.verticalSpace,
                      
                      // Segment Progress Bar
                      Container(
                        height: 14.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7.r),
                          color: context.colors.onSurface.withOpacity(0.05),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.r),
                          child: Row(
                            children: [
                              if (transRatio > 0) Expanded(flex: (transRatio * 1000).round(), child: Container(color: Colors.orange)),
                              if (accRatio > 0) Expanded(flex: (accRatio * 1000).round(), child: Container(color: Colors.blue)),
                              if (foodRatio > 0) Expanded(flex: (foodRatio * 1000).round(), child: Container(color: Colors.green)),
                              if (actRatio > 0) Expanded(flex: (actRatio * 1000).round(), child: Container(color: Colors.purple)),
                              if (unallocatedRatio > 0 && state.totalEstimated > 0) Expanded(flex: (unallocatedRatio * 1000).round(), child: Container(color: context.colors.onSurface.withOpacity(0.08))),
                            ],
                          ),
                        ),
                      ),
                      12.h.verticalSpace,
                      
                      // Legends and allocation totals
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 8.h,
                        children: [
                          _buildLegendDot(Colors.orange, "Trans: ${state.currency} ${state.transportationBudget.toStringAsFixed(0)}"),
                          _buildLegendDot(Colors.blue, "Acc: ${state.currency} ${state.accommodationBudget.toStringAsFixed(0)}"),
                          _buildLegendDot(Colors.green, "Food: ${state.currency} ${state.foodBudget.toStringAsFixed(0)}"),
                          _buildLegendDot(Colors.purple, "Act: ${state.currency} ${state.activitiesBudget.toStringAsFixed(0)}"),
                          if (state.totalEstimated > totalAllocated)
                            _buildLegendDot(context.colors.onSurface.withOpacity(0.3), "Unallocated: ${state.currency} ${(state.totalEstimated - totalAllocated).toStringAsFixed(0)}"),
                        ],
                      ),
                      if (exceeds) ...[
                        12.h.verticalSpace,
                        Text(
                          "⚠️ Warning: Total allocated (${state.currency} ${totalAllocated.toStringAsFixed(0)}) exceeds your total budget (${state.currency} ${state.totalEstimated.toStringAsFixed(0)}).",
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      24.h.verticalSpace,
                      
                      // Slider inputs
                      _buildCategorySliderCard(
                        context,
                        label: "Transportation 🚗",
                        value: state.transportationBudget,
                        maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                        icon: Icons.directions_car_outlined,
                        color: Colors.orange,
                        onChanged: (val) => _onSliderChanged(trans: val),
                      ),
                      12.h.verticalSpace,
                      _buildCategorySliderCard(
                        context,
                        label: "Accommodation 🏨",
                        value: state.accommodationBudget,
                        maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                        icon: Icons.hotel_outlined,
                        color: Colors.blue,
                        onChanged: (val) => _onSliderChanged(acc: val),
                      ),
                      12.h.verticalSpace,
                      _buildCategorySliderCard(
                        context,
                        label: "Food & Dining 🍕",
                        value: state.foodBudget,
                        maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                        icon: Icons.restaurant_outlined,
                        color: Colors.green,
                        onChanged: (val) => _onSliderChanged(food: val),
                      ),
                      12.h.verticalSpace,
                      _buildCategorySliderCard(
                        context,
                        label: "Activities 🎢",
                        value: state.activitiesBudget,
                        maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                        icon: Icons.explore_outlined,
                        color: Colors.purple,
                        onChanged: (val) => _onSliderChanged(act: val),
                      ),
                      16.h.verticalSpace,
                    ]
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                child: CommonButton(
                  title: "Continue",
                  onPressed: state.budgetLevel == null
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

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        6.w.horizontalSpace,
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySliderCard(
    BuildContext context, {
    required String label,
    required double value,
    required double maxVal,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.colors.onSurface.withOpacity(0.08)),
        color: context.colors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              12.w.horizontalSpace,
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              Text(
                "${_selectedCurrency} ${value.toStringAsFixed(0)}",
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          12.h.verticalSpace,
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.1),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 4.h,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.clamp(0.0, maxVal),
              min: 0,
              max: maxVal,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
