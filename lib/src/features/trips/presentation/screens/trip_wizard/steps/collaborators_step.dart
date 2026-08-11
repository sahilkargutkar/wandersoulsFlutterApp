import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/success.dart';
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
  List<dynamic> _allUsers = [];
  List<dynamic> _searchResults = [];
  bool _isLoadingUsers = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    if (_allUsers.isEmpty) {
      setState(() => _isLoadingUsers = true);
      try {
        final apiService = sl<ApiService>();
        final res = await apiService.get<dynamic>(
          "/User",
          fromJson: (data) => data,
        );
        if (res is Success && res.data != null && res.data["data"] is List) {
          _allUsers = res.data["data"] as List;
        }
      } catch (e) {
        debugPrint("Error fetching users: $e");
      } finally {
        setState(() => _isLoadingUsers = false);
      }
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _searchResults = _allUsers.where((u) {
        final email = (u["email"] as String? ?? "").toLowerCase();
        final name = (u["name"] as String? ?? "").toLowerCase();
        return email.contains(lowercaseQuery) || name.contains(lowercaseQuery);
      }).toList();
    });
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
                      onChanged: _searchUsers,
                      decoration: InputDecoration(
                        hintText: "Search name or email...",
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
                          setState(() {
                            _searchResults = [];
                          });
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
                        setState(() {
                          _searchResults = [];
                        });
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
              if (_isLoadingUsers)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 180.h),
                  margin: EdgeInsets.only(top: 8.h),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: context.colors.onSurface.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final name = user["name"] ?? "";
                      final email = user["email"] ?? "";
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14.r,
                          backgroundColor: context.colors.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: context.colors.primary, size: 16.sp),
                        ),
                        title: Text(name, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(email, style: context.text.bodySmall),
                        onTap: () {
                          context.read<TripWizardCubit>().addCollaborator(email);
                          _emailController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
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
