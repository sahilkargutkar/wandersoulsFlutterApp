import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class CollaboratorsStep extends StatefulWidget {
  const CollaboratorsStep({super.key});

  @override
  State<CollaboratorsStep> createState() => _CollaboratorsStepState();
}

class _CollaboratorsStepState extends State<CollaboratorsStep> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
                "Invite your travel buddies 🤝",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              8.h.verticalSpace,
              Text(
                "Add friends or family to collaborate on your itinerary. You can skip this if you're going solo or adding them later.",
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              32.h.verticalSpace,
              // Add collaborator field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Enter email address",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: context.colors.onSurface.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: context.colors.onSurface.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: context.colors.primary),
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          context.read<TripWizardCubit>().addCollaborator(value.trim());
                          _emailController.clear();
                        }
                      },
                    ),
                  ),
                  12.w.horizontalSpace,
                  InkWell(
                    onTap: () {
                      if (_emailController.text.trim().isNotEmpty) {
                        context.read<TripWizardCubit>().addCollaborator(_emailController.text.trim());
                        _emailController.clear();
                      }
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.add, color: context.colors.onPrimary),
                    ),
                  )
                ],
              ),
              24.h.verticalSpace,
              // List of added collaborators
              Expanded(
                child: ListView.separated(
                  itemCount: state.collaborators.length,
                  separatorBuilder: (_, __) => 12.h.verticalSpace,
                  itemBuilder: (context, index) {
                    final collab = state.collaborators[index];
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.colors.onSurface.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12.r),
                        color: context.colors.surface,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18.r,
                            backgroundColor: context.colors.primary.withOpacity(0.1),
                            child: Icon(Icons.person, color: context.colors.primary, size: 20.sp),
                          ),
                          12.w.horizontalSpace,
                          Expanded(
                            child: Text(
                              collab["userEmail"] ?? "",
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: context.colors.onSurfaceVariant),
                            onPressed: () {
                              context.read<TripWizardCubit>().removeCollaborator(collab["userEmail"] ?? "");
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 16.h),
                child: CommonButton(
                  title: state.collaborators.isEmpty ? "Skip & Continue" : "Continue",
                  onPressed: () {
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
