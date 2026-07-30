import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class GeneratingStep extends StatefulWidget {
  const GeneratingStep({super.key});

  @override
  State<GeneratingStep> createState() => _GeneratingStepState();
}

class _GeneratingStepState extends State<GeneratingStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasCalled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger AI generation when this step first becomes visible
    if (!_hasCalled) {
      _hasCalled = true;
      final status = context.read<TripWizardCubit>().state.status;
      if (status == TripWizardStatus.generatingItinerary) {
        // Already triggered from cubit – no need to call again
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          context.colors.primary,
                          context.colors.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 36.sp,
                    ),
                  ),
                );
              },
            ),
            32.h.verticalSpace,
            Text(
              "Generating Itinerary...",
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            16.h.verticalSpace,
            Text(
              "Our AI is crafting a personalized day-by-day itinerary based on your preferences. This may take a moment.",
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            32.h.verticalSpace,
            SizedBox(
              width: 200.w,
              child: LinearProgressIndicator(
                backgroundColor: context.colors.onSurface.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
