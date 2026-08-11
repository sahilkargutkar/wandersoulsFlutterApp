import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/upgrade_plan_screen.dart';

class BillingSubscriptionsScreen extends StatefulWidget {
  const BillingSubscriptionsScreen({super.key});

  static const String routeName = "/BillingSubscriptionsScreen";

  @override
  State<BillingSubscriptionsScreen> createState() => _BillingSubscriptionsScreenState();
}

class _BillingSubscriptionsScreenState extends State<BillingSubscriptionsScreen> {
  String _currentPlan = "Explorer Free";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPlan = prefs.getString("user_plan") ?? "Explorer Free";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _currentPlan != "Explorer Free";

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          "Billing & Subscriptions",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Plan Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: isPro
                          ? LinearGradient(
                              colors: [context.primary, context.primary.withAlpha(180)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isPro ? null : context.mutedBackground,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: isPro
                          ? [
                              BoxShadow(
                                color: context.primary.withAlpha(80),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CURRENT PLAN",
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: isPro ? Colors.white.withAlpha(200) : context.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        8.h.verticalSpace,
                        Text(
                          _currentPlan,
                          style: context.text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isPro ? Colors.white : context.onSurface,
                          ),
                        ),
                        16.h.verticalSpace,
                        Text(
                          isPro
                              ? "Next renewal date: September 11, 2026 (\$19.99/mo)"
                              : "Access basic features. Upgrade to unlock full AI planning capabilities.",
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.4,
                            color: isPro ? Colors.white.withAlpha(220) : context.onSurfaceVariant,
                          ),
                        ),
                        if (!isPro) ...[
                          24.h.verticalSpace,
                          CommonButton(
                            title: "Upgrade to Premium",
                            useGradient: true,
                            onPressed: () async {
                              final result = await Navigator.pushNamed(context, UpgradePlanScreen.routeName);
                              if (result == true) {
                                _loadCurrentPlan();
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  28.h.verticalSpace,

                  // Features list
                  Text(
                    "Plan Benefits",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  16.h.verticalSpace,
                  _buildBenefitRow(context, "Unlimited AI Itinerary Generations", true),
                  12.h.verticalSpace,
                  _buildBenefitRow(context, "Full Booking & Document Uploads", true),
                  12.h.verticalSpace,
                  _buildBenefitRow(context, "Collaborators & Multi-User Planning", true),
                  12.h.verticalSpace,
                  _buildBenefitRow(context, "Ad-Free Interactive Map View", isPro),

                  32.h.verticalSpace,

                  // Billing History
                  Text(
                    "Billing History",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  16.h.verticalSpace,
                  if (!isPro)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          "No subscription payments made yet.",
                          style: context.text.bodyMedium?.copyWith(
                            color: context.onSurfaceVariant.withAlpha(120),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    _buildInvoiceRow(context, "Aug 11, 2026", "Explorer Pro Monthly", "\$19.99", "Visa 4242"),
                    const Divider(height: 24),
                    _buildInvoiceRow(context, "Jul 11, 2026", "Explorer Pro Trial", "\$0.00", "Visa 4242"),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, String text, bool included) {
    return Row(
      children: [
        Icon(
          included ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: included ? Colors.green : context.onSurfaceVariant.withAlpha(80),
          size: 20.sp,
        ),
        12.w.horizontalSpace,
        Text(
          text,
          style: context.text.bodyMedium?.copyWith(
            color: included ? context.onSurface : context.onSurfaceVariant.withAlpha(120),
            decoration: included ? null : TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow(BuildContext context, String date, String plan, String amount, String method) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan,
              style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            4.h.verticalSpace,
            Text(
              "Paid via $method on $date",
              style: context.text.bodySmall?.copyWith(color: context.onSurfaceVariant),
            ),
          ],
        ),
        Text(
          amount,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.primary,
          ),
        ),
      ],
    );
  }
}
