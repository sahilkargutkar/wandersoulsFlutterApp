import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/features/settings/presentation/screens/terms_and_conditions_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const String routeName = "/HelpSupportScreen";

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      "q": "How does the AI Trip Wizard planning work?",
      "a":
          "WanderSouls uses advanced AI planning proxy endpoints to generate custom multi-day schedules based on your destination city, budget type, and travel tastes. You can then edit activities, invite collaborators, or add accommodations.",
    },
    {
      "q": "Can I invite collaborators to plan trips with me?",
      "a":
          "Yes! In any active trip, go to the Collaborators section, search for active users by their email or name, and click invite. Collaborators can view and edit the itinerary.",
    },
    {
      "q": "Where are my uploaded document snaps saved?",
      "a":
          "Uploaded reservation vouchers, boarding passes, or tickets are uploaded to secure Azure Blob Storage. They are associated with your trip details page for easy access.",
    },
    {
      "q": "How do I upgrade to Explorer Pro?",
      "a":
          "Navigate to Settings -> Billing & Subscriptions, and select 'Upgrade to Premium'. Select your plan and payment method to unlock unlimited itinerary plans.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          "Help & Support",
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
              "Frequently Asked Questions",
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            12.h.verticalSpace,
            Container(
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  return ExpansionTile(
                    title: Text(
                      faq["q"]!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: context.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        child: Text(
                          faq["a"]!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.5,
                            color: context.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            28.h.verticalSpace,

            Text(
              "Contact Support",
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            12.h.verticalSpace,
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: "Subject"),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Subject is required"
                        : null,
                  ),
                  12.h.verticalSpace,
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Message"),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Message is required"
                        : null,
                  ),
                  20.h.verticalSpace,
                  CommonButton(
                    title: "Send Ticket",
                    useGradient: true,
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      _subjectController.clear();
                      _messageController.clear();
                      AppToast.success(
                        "Support ticket submitted! We will email you back soon.",
                      );
                    },
                  ),
                ],
              ),
            ),
            32.h.verticalSpace,

            // Links list
            Text(
              "Links & Documents",
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            12.h.verticalSpace,
            Container(
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Privacy Policy"),
                    trailing: Icon(Icons.open_in_new_rounded, size: 14.sp),
                    onTap: () {
                      launchUrl(
                        Uri.parse("https://www.wandersouls.in/privacy-policy/"),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text("Terms & Conditions"),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp),
                    onTap: () {
                      context.push(TermsAndConditionsScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
