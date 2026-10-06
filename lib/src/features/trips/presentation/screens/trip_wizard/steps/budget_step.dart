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
  late final TextEditingController _transController;
  late final TextEditingController _accController;
  late final TextEditingController _foodController;
  late final TextEditingController _actController;
  String _selectedCurrency = "USD";

  final List<Map<String, String>> _options = const [
    {
      "title": "Cheap 💰",
      "subtitle": "Budget-friendly, hostels, street food & transit.",
      "value": "cheap",
    },
    {
      "title": "Balanced ⚖️",
      "subtitle": "Comfortable 3-star stays & balanced activities.",
      "value": "balanced",
    },
    {
      "title": "Luxury 💎",
      "subtitle": "Top-tier hotels, fine dining & private tours.",
      "value": "luxury",
    },
    {
      "title": "Flexible 🔀",
      "subtitle": "No hard limits, spend as you go.",
      "value": "flexible",
    },
  ];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<TripWizardCubit>();
    final state = cubit.state;

    _totalController = TextEditingController(
      text: state.totalEstimated > 0
          ? state.totalEstimated.toStringAsFixed(0)
          : '',
    );
    _transController = TextEditingController(
      text: state.transportationBudget > 0
          ? state.transportationBudget.toStringAsFixed(0)
          : '',
    );
    _accController = TextEditingController(
      text: state.accommodationBudget > 0
          ? state.accommodationBudget.toStringAsFixed(0)
          : '',
    );
    _foodController = TextEditingController(
      text: state.foodBudget > 0
          ? state.foodBudget.toStringAsFixed(0)
          : '',
    );
    _actController = TextEditingController(
      text: state.activitiesBudget > 0
          ? state.activitiesBudget.toStringAsFixed(0)
          : '',
    );

    _selectedCurrency = state.currency.isNotEmpty ? state.currency : "USD";
  }

  void _onTotalChanged(String val) {
    final total = double.tryParse(val.trim()) ?? 0.0;
    final cubit = context.read<TripWizardCubit>();
    final state = cubit.state;

    cubit.setBudgetDetails(
      currency: _selectedCurrency,
      totalEstimated: total,
      transportation: state.transportationBudget,
      accommodation: state.accommodationBudget,
      food: state.foodBudget,
      activities: state.activitiesBudget,
    );
  }

  void _autoDistributeBudget(double total) {
    if (total <= 0) return;
    // Standard recommended distribution:
    // Accommodation: 35%, Transport: 25%, Food: 25%, Activities: 15%
    final acc = (total * 0.35).roundToDouble();
    final trans = (total * 0.25).roundToDouble();
    final food = (total * 0.25).roundToDouble();
    final act = (total * 0.15).roundToDouble();

    _accController.text = acc.toStringAsFixed(0);
    _transController.text = trans.toStringAsFixed(0);
    _foodController.text = food.toStringAsFixed(0);
    _actController.text = act.toStringAsFixed(0);

    final cubit = context.read<TripWizardCubit>();
    cubit.setBudgetDetails(
      currency: _selectedCurrency,
      totalEstimated: total,
      transportation: trans,
      accommodation: acc,
      food: food,
      activities: act,
    );
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

    if (trans != null) _transController.text = newTrans > 0 ? newTrans.toStringAsFixed(0) : '';
    if (acc != null) _accController.text = newAcc > 0 ? newAcc.toStringAsFixed(0) : '';
    if (food != null) _foodController.text = newFood > 0 ? newFood.toStringAsFixed(0) : '';
    if (act != null) _actController.text = newAct > 0 ? newAct.toStringAsFixed(0) : '';

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
    _transController.dispose();
    _accController.dispose();
    _foodController.dispose();
    _actController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripWizardCubit, TripWizardState>(
      builder: (context, state) {
        final totalAllocated =
            state.transportationBudget +
            state.accommodationBudget +
            state.foodBudget +
            state.activitiesBudget;
        final exceeds =
            totalAllocated > state.totalEstimated && state.totalEstimated > 0;
        final double scale = exceeds
            ? totalAllocated
            : (state.totalEstimated > 0 ? state.totalEstimated : (totalAllocated > 0 ? totalAllocated : 1.0));

        final double transRatio = state.transportationBudget / scale;
        final double accRatio = state.accommodationBudget / scale;
        final double foodRatio = state.foodBudget / scale;
        final double actRatio = state.activitiesBudget / scale;
        final double unallocatedRatio = exceeds
            ? 0.0
            : (state.totalEstimated > totalAllocated
                ? ((state.totalEstimated - totalAllocated) / scale)
                : 0.0);

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Trip Budget & Currency 💰",
                            style: context.text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: context.primaryTint,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            "Optional",
                            style: context.text.labelSmall?.copyWith(
                              color: context.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    8.h.verticalSpace,
                    Text(
                      "Set your expected total budget, currency, and category estimates. You can always change this later.",
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    24.h.verticalSpace,

                    // 1. Currency & Total Expected Budget
                    Text(
                      "1. Expected Total Budget",
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                            initialValue: _selectedCurrency,
                            dropdownColor: context.colors.surface,
                            style: context.text.bodyMedium?.copyWith(
                              color: context.colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: "Currency",
                              filled: true,
                              fillColor: context.mutedBackground,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 16.h,
                              ),
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
                            items: [
                              "USD", "EUR", "INR", "GBP", "JPY",
                              "AUD", "CAD", "AED", "SGD", "CHF", "THB"
                            ]
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
                            hintText: "e.g. 2500",
                            labelText: "Total Budget",
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: context.colors.onSurfaceVariant,
                            ),
                            onChanged: _onTotalChanged,
                          ),
                        ),
                      ],
                    ),
                    12.h.verticalSpace,

                    // Quick Budget Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [500, 1500, 3000, 5000].map((amt) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: ActionChip(
                              label: Text("$_selectedCurrency $amt"),
                              backgroundColor: context.mutedBackground,
                              labelStyle: context.text.labelSmall?.copyWith(
                                color: context.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                side: BorderSide(
                                  color: context.primary.withAlpha(40),
                                ),
                              ),
                              onPressed: () {
                                _totalController.text = amt.toString();
                                _onTotalChanged(amt.toString());
                                _autoDistributeBudget(amt.toDouble());
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    24.h.verticalSpace,

                    // 2. Category-Wise Estimation Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "2. Category-wise Breakdown",
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface,
                          ),
                        ),
                        if (state.totalEstimated > 0)
                          InkWell(
                            onTap: () => _autoDistributeBudget(state.totalEstimated),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_fix_high_rounded, size: 14.sp, color: context.primary),
                                  4.w.horizontalSpace,
                                  Text(
                                    "Auto Distribute",
                                    style: context.text.labelSmall?.copyWith(
                                      color: context.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    10.h.verticalSpace,

                    // Segmented Allocation Bar
                    Container(
                      height: 12.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        color: context.colors.onSurface.withValues(alpha: 0.08),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: Row(
                          children: [
                            if (transRatio > 0)
                              Expanded(
                                flex: (transRatio * 1000).round().clamp(1, 1000),
                                child: Container(color: Colors.orange),
                              ),
                            if (accRatio > 0)
                              Expanded(
                                flex: (accRatio * 1000).round().clamp(1, 1000),
                                child: Container(color: Colors.blue),
                              ),
                            if (foodRatio > 0)
                              Expanded(
                                flex: (foodRatio * 1000).round().clamp(1, 1000),
                                child: Container(color: Colors.green),
                              ),
                            if (actRatio > 0)
                              Expanded(
                                flex: (actRatio * 1000).round().clamp(1, 1000),
                                child: Container(color: Colors.purple),
                              ),
                            if (unallocatedRatio > 0)
                              Expanded(
                                flex: (unallocatedRatio * 1000).round().clamp(1, 1000),
                                child: Container(
                                  color: context.colors.onSurface.withValues(alpha: 0.08),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    10.h.verticalSpace,

                    // Legends
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: [
                        _buildLegendDot(Colors.orange, "Trans: $_selectedCurrency ${state.transportationBudget.toStringAsFixed(0)}"),
                        _buildLegendDot(Colors.blue, "Stay: $_selectedCurrency ${state.accommodationBudget.toStringAsFixed(0)}"),
                        _buildLegendDot(Colors.green, "Food: $_selectedCurrency ${state.foodBudget.toStringAsFixed(0)}"),
                        _buildLegendDot(Colors.purple, "Activities: $_selectedCurrency ${state.activitiesBudget.toStringAsFixed(0)}"),
                        if (state.totalEstimated > totalAllocated)
                          _buildLegendDot(
                            context.colors.onSurface.withValues(alpha: 0.3),
                            "Remaining: $_selectedCurrency ${(state.totalEstimated - totalAllocated).toStringAsFixed(0)}",
                          ),
                      ],
                    ),
                    if (exceeds) ...[
                      8.h.verticalSpace,
                      Text(
                        "⚠️ Total category estimates exceed total budget ($_selectedCurrency ${totalAllocated.toStringAsFixed(0)} / $_selectedCurrency ${state.totalEstimated.toStringAsFixed(0)})",
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    16.h.verticalSpace,

                    // Sliders
                    _buildCategorySliderCard(
                      context,
                      label: "Transportation 🚗",
                      value: state.transportationBudget,
                      maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                      icon: Icons.directions_car_outlined,
                      color: Colors.orange,
                      onChanged: (val) => _onSliderChanged(trans: val),
                    ),
                    10.h.verticalSpace,
                    _buildCategorySliderCard(
                      context,
                      label: "Accommodation / Hotel 🏨",
                      value: state.accommodationBudget,
                      maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                      icon: Icons.hotel_outlined,
                      color: Colors.blue,
                      onChanged: (val) => _onSliderChanged(acc: val),
                    ),
                    10.h.verticalSpace,
                    _buildCategorySliderCard(
                      context,
                      label: "Food & Dining 🍕",
                      value: state.foodBudget,
                      maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                      icon: Icons.restaurant_outlined,
                      color: Colors.green,
                      onChanged: (val) => _onSliderChanged(food: val),
                    ),
                    10.h.verticalSpace,
                    _buildCategorySliderCard(
                      context,
                      label: "Activities & Sightseeing 🎢",
                      value: state.activitiesBudget,
                      maxVal: state.totalEstimated > 0 ? state.totalEstimated : 1000.0,
                      icon: Icons.explore_outlined,
                      color: Colors.purple,
                      onChanged: (val) => _onSliderChanged(act: val),
                    ),
                    24.h.verticalSpace,

                    // 3. Travel Budget Style
                    Text(
                      "3. Budget Style (Optional)",
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    12.h.verticalSpace,

                    ..._options.map((option) {
                      final isSelected = state.budgetLevel == option["value"];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: InkWell(
                          onTap: () {
                            context.read<TripWizardCubit>().setBudgetLevel(
                              option["value"]!,
                            );
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
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
                                  ? context.colors.primary.withValues(
                                      alpha: 0.05,
                                    )
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(
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
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: context.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    20.h.verticalSpace,
                  ],
                ),
              ),

              // Bottom Actions (Skip & Continue)
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          // Default to flexible if not set
                          if (state.budgetLevel == null) {
                            context.read<TripWizardCubit>().setBudgetLevel("flexible");
                          }
                          context.read<TripWizardCubit>().nextStep();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: context.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          "Skip",
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    12.w.horizontalSpace,
                    Expanded(
                      flex: 2,
                      child: CommonButton(
                        title: "Continue",
                        onPressed: () {
                          if (state.budgetLevel == null) {
                            context.read<TripWizardCubit>().setBudgetLevel("flexible");
                          }
                          context.read<TripWizardCubit>().nextStep();
                        },
                      ),
                    ),
                  ],
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.colors.onSurface.withValues(alpha: 0.08),
        ),
        color: context.colors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18.sp),
              ),
              10.w.horizontalSpace,
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              Text(
                "$_selectedCurrency ${value.toStringAsFixed(0)}",
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          6.h.verticalSpace,
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.12),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 3.5.h,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
