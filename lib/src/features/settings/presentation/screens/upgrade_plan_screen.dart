import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  static const String routeName = "/UpgradePlanScreen";

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  int _selectedPlan =
      0; // 0: Explorer Pro ($19.99/mo), 1: Globetrotter Elite ($39.99/mo)
  int _selectedPayment =
      0; // 0: Visa ending in 4242, 1: Apple Pay, 2: Google Pay
  bool _processing = false;
  bool _success = false;

  final List<Map<String, dynamic>> _plans = [
    {
      "name": "Explorer Pro",
      "price": "\$19.99",
      "period": "month",
      "description": "Best for solo globetrotters and couples.",
      "features": [
        "Unlimited AI Itinerary Generations",
        "Unlimited Travel Collaborators",
        "Offline Trip Downloads",
        "Ad-Free Map View",
      ],
    },
    {
      "name": "Globetrotter Elite",
      "price": "\$39.99",
      "period": "month",
      "description": "Best for tour guides, families, and organizations.",
      "features": [
        "Everything in Pro Plan",
        "Multi-Destination Optimization",
        "Priority Support & Local Guides",
        "Dedicated Travel Concierge",
      ],
    },
  ];

  void _showAddCardBottomSheet() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20.w,
            20.h,
            20.w,
            MediaQuery.of(context).viewInsets.bottom + 20.h,
          ),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Credit Card",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              16.h.verticalSpace,
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Cardholder Name"),
              ),
              12.h.verticalSpace,
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Card Number"),
              ),
              12.h.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: "Expiry Date (MM/YY)",
                      ),
                    ),
                  ),
                  16.w.horizontalSpace,
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "CVV"),
                    ),
                  ),
                ],
              ),
              24.h.verticalSpace,
              CommonButton(
                title: "Save Card",
                useGradient: true,
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      numberController.text.isEmpty)
                    return;
                  Navigator.pop(context);
                  AppToast.success("Card added successfully!");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPayment() async {
    setState(() => _processing = true);

    // Simulate processing payment delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_plan", _plans[_selectedPlan]["name"]);

    if (mounted) {
      setState(() {
        _processing = false;
        _success = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return Scaffold(
        backgroundColor: context.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              24.h.verticalSpace,
              Text(
                "Processing payment securely...",
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_success) {
      return Scaffold(
        backgroundColor: context.surface,
        body: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 80,
              ),
              24.h.verticalSpace,
              Text(
                "Upgrade Successful!",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              12.h.verticalSpace,
              Text(
                "You are now subscribed to ${_plans[_selectedPlan]["name"]} plan. Enjoy unlimited travel wizard integrations!",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
              32.h.verticalSpace,
              CommonButton(
                title: "Get Started",
                useGradient: true,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          "Upgrade Plan",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Subscription",
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            12.h.verticalSpace,
            Column(
              children: List.generate(_plans.length, (index) {
                final plan = _plans[index];
                final isSelected = _selectedPlan == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPlan = index),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? context.primary
                            : context.borderColor.withAlpha(50),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      color: isSelected
                          ? context.primaryTint.withAlpha(20)
                          : context.mutedBackground,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plan["name"],
                              style: context.text.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${plan["price"]}/${plan["period"]}",
                              style: context.text.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: context.primary,
                              ),
                            ),
                          ],
                        ),
                        8.h.verticalSpace,
                        Text(
                          plan["description"],
                          style: context.text.bodySmall?.copyWith(
                            color: context.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            24.h.verticalSpace,
            Text(
              "Payment Method",
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            12.h.verticalSpace,
            _buildPaymentMethodRow(
              0,
              "Visa ending in 4242",
              Icons.credit_card_rounded,
            ),
            _buildPaymentMethodRow(1, "Apple Pay", Icons.apple_rounded),
            _buildPaymentMethodRow(2, "Google Pay", Icons.android_rounded),

            16.h.verticalSpace,
            TextButton.icon(
              onPressed: _showAddCardBottomSheet,
              icon: const Icon(Icons.add),
              label: const Text("Add New Payment Method"),
            ),

            32.h.verticalSpace,
            // Price Breakdown Summary
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Plan Subscription:",
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      Text(
                        _plans[_selectedPlan]["price"],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  8.h.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tax (0%):", style: TextStyle(fontSize: 13.sp)),
                      Text(
                        "\$0.00",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Amount:",
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _plans[_selectedPlan]["price"],
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            28.h.verticalSpace,
            CommonButton(
              title: "Pay Now",
              useGradient: true,
              onPressed: _processPayment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(int index, String name, IconData icon) {
    final isSelected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? context.primary : Colors.transparent,
          ),
          color: context.mutedBackground,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.onSurface),
            16.w.horizontalSpace,
            Expanded(child: Text(name)),
            if (isSelected)
              Icon(Icons.check_circle, color: context.primary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
