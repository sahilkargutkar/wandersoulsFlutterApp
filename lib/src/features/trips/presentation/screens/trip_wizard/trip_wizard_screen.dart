import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/trip_details_step.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/party_step.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/dates_step.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/interests_step.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/budget_step.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/collaborators_step.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_wizard/steps/review_step.dart';

class TripWizardScreen extends StatelessWidget {
  const TripWizardScreen({super.key, required this.destination});

  static const String routeName = "/TripWizardScreen";
  final PlaceModel destination;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripWizardCubit()..init(destination),
      child: const _TripWizardView(),
    );
  }
}

class _TripWizardView extends StatefulWidget {
  const _TripWizardView();

  @override
  State<_TripWizardView> createState() => _TripWizardViewState();
}

class _TripWizardViewState extends State<_TripWizardView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripWizardCubit, TripWizardState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == TripWizardStatus.success) {
          AppToast.success("Trip created successfully! 🎉");
          Navigator.pop(context);
          return;
        } else if (state.status == TripWizardStatus.failure) {
          AppToast.error(state.errorMessage ?? "Failed to create trip. Please try again.");
        }

        if (_pageController.hasClients && _pageController.page?.round() != state.currentStep) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      builder: (context, state) {
        // Hide appBar on generating and itinerary result steps
        final hideAppBar = state.currentStep >= 7;

        return Scaffold(
          backgroundColor: context.surface,
          appBar: hideAppBar
              ? null
              : AppBar(
                  backgroundColor: context.surface,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: context.onSurface),
                    onPressed: () {
                      if (state.currentStep > 0) {
                        context.read<TripWizardCubit>().previousStep();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: LinearProgressIndicator(
                        value: (state.currentStep + 1) / 7,
                        backgroundColor: context.onSurface.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              TripDetailsStep(),        // 0
              PartyStep(),              // 1
              DatesStep(),              // 2
              InterestsStep(),          // 3
              BudgetStep(),             // 4
              CollaboratorsStep(),      // 5
              ReviewStep(),             // 6
            ],
          ),
        );
      },
    );
  }
}
