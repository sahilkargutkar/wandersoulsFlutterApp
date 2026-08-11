import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  static const String routeName = "/PaymentMethodsScreen";

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _cards = [
    {"type": "Visa", "last4": "4242", "expiry": "12/28", "isDefault": true},
    {"type": "Mastercard", "last4": "8888", "expiry": "06/27", "isDefault": false},
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
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Payment Method",
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      decoration: const InputDecoration(labelText: "Expiry Date (MM/YY)"),
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
                title: "Add Card",
                useGradient: true,
                onPressed: () {
                  final name = nameController.text.trim();
                  final number = numberController.text.trim();
                  if (name.isEmpty || number.isEmpty) return;
                  Navigator.pop(context);

                  setState(() {
                    _cards.add({
                      "type": "Visa",
                      "last4": number.substring(number.length - 4),
                      "expiry": expiryController.text.trim(),
                      "isDefault": false,
                    });
                  });
                  AppToast.success("Payment method added successfully!");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          "Payment Methods",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Saved Cards",
              style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            16.h.verticalSpace,
            Expanded(
              child: ListView.separated(
                itemCount: _cards.length,
                separatorBuilder: (_, __) => 12.h.verticalSpace,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: context.mutedBackground,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          card["type"] == "Visa" ? Icons.credit_card : Icons.credit_card_outlined,
                          color: context.primary,
                          size: 32.sp,
                        ),
                        16.w.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${card["type"]} •••• ${card["last4"]}",
                                style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              4.h.verticalSpace,
                              Text(
                                "Expires ${card["expiry"]}",
                                style: context.text.bodySmall?.copyWith(color: context.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (card["isDefault"])
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: context.primaryTint,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              "Default",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: context.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.check),
                                        title: const Text("Set as Default"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            for (var c in _cards) {
                                              c["isDefault"] = false;
                                            }
                                            card["isDefault"] = true;
                                          });
                                          AppToast.success("Default payment card updated");
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.delete, color: context.colors.error),
                                        title: Text("Remove Card", style: TextStyle(color: context.colors.error)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            _cards.removeAt(index);
                                          });
                                          AppToast.success("Card removed");
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            CommonButton(
              title: "Add Payment Method",
              useGradient: true,
              onPressed: _showAddCardBottomSheet,
            ),
          ],
        ),
      ),
    );
  }
}
