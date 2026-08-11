import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  static const String routeName = "/AccountSecurityScreen";

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password"),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final oldP = oldPasswordController.text;
                final newP = newPasswordController.text;
                final confP = confirmPasswordController.text;

                if (oldP.isEmpty || newP.isEmpty) return;
                if (newP != confP) {
                  AppToast.error("Passwords do not match");
                  return;
                }

                Navigator.pop(context);
                AppToast.success("Password changed successfully!");
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Account", style: TextStyle(color: context.colors.error)),
          content: const Text(
            "Are you sure you want to delete your WanderSouls account? This will permanently delete all your trips, collaborators, documents, and subscription plans. This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
              onPressed: () {
                Navigator.pop(context);
                AppToast.success("Account deleted. Hope to see you again!");
              },
              child: const Text("Delete permanently", style: TextStyle(color: Colors.white)),
            ),
          ],
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
          "Account & Security",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Text(
            "Login Security",
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          12.h.verticalSpace,
          Card(
            color: context.mutedBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.lock_outline_rounded, color: context.primary),
              title: const Text("Change Password"),
              subtitle: const Text("Update password regularly to stay secure"),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp),
              onTap: _showChangePasswordDialog,
            ),
          ),
          24.h.verticalSpace,

          Text(
            "Advanced Authentication",
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          12.h.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: context.mutedBackground,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _biometricEnabled,
                  activeColor: context.primary,
                  title: const Text("Biometric Authentication"),
                  subtitle: const Text("Use Face ID or Fingerprint to unlock"),
                  onChanged: (val) => setState(() => _biometricEnabled = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _twoFactorEnabled,
                  activeColor: context.primary,
                  title: const Text("Two-Factor Authentication"),
                  subtitle: const Text("Add verification code step for login security"),
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
              ],
            ),
          ),
          32.h.verticalSpace,

          Text(
            "Danger Zone",
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.error,
            ),
          ),
          12.h.verticalSpace,
          Card(
            color: context.colors.error.withAlpha(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: context.colors.error.withAlpha(40)),
            ),
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: context.colors.error),
              title: Text("Delete Account", style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
              subtitle: Text("Permanently delete account & planning history", style: TextStyle(color: context.colors.error.withAlpha(200))),
              onTap: _showDeleteAccountDialog,
            ),
          ),
        ],
      ),
    );
  }
}
