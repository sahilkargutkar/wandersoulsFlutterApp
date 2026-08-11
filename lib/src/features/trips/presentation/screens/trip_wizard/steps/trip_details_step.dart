import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_text_form_field.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class TripDetailsStep extends StatefulWidget {
  const TripDetailsStep({super.key});

  @override
  State<TripDetailsStep> createState() => _TripDetailsStepState();
}

class _TripDetailsStepState extends State<TripDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<TripWizardCubit>();
    _nameController = TextEditingController(text: cubit.state.name);
    _descController = TextEditingController(text: cubit.state.description);

    _nameController.addListener(() {
      cubit.setName(_nameController.text.trim());
    });

    _descController.addListener(() {
      cubit.setDescription(_descController.text.trim());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripWizardCubit, TripWizardState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.h.verticalSpace,
                Text(
                  "Name your adventure ✈️",
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                8.h.verticalSpace,
                Text(
                  "Give your trip a memorable name, write a short description, and decide who can see it.",
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                32.h.verticalSpace,
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      CommonTextFormField(
                        controller: _nameController,
                        hintText: "e.g., Summer Holiday in Paris",
                        labelText: "Trip Name",
                        prefixIcon: Icon(
                          Icons.title_rounded,
                          color: context.colors.onSurfaceVariant,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Trip name is required";
                          }
                          return null;
                        },
                      ),
                      20.h.verticalSpace,
                      CommonTextFormField(
                        controller: _descController,
                        hintText:
                            "e.g., Exploring museums, trying local food, and sightseeing.",
                        labelText: "Description (Optional)",
                        prefixIcon: Icon(
                          Icons.description_outlined,
                          color: context.colors.onSurfaceVariant,
                        ),
                        maxLines: 3,
                      ),
                      24.h.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.colors.onSurface.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          color: context.colors.surface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Make Trip Public 🌍",
                                    style: context.text.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  4.h.verticalSpace,
                                  Text(
                                    "Anyone will be able to search for and view this itinerary.",
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: state.isPublic,
                              onChanged: (val) {
                                context.read<TripWizardCubit>().setIsPublic(
                                  val,
                                );
                              },
                              activeThumbColor: context.colors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                  child: CommonButton(
                    title: "Continue",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<TripWizardCubit>().nextStep();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
