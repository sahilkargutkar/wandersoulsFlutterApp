import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/features/auth/data/datasource/auth_remote_data_source.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String userId;

  const ChangePasswordDialog({super.key, required this.userId});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _existingPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _existingPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    final existing = _existingPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (existing.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      AppToast.error("Please fill in all password fields");
      return;
    }

    if (newPass != confirm) {
      AppToast.error("New password and confirm password do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authDataSource = sl<AuthRemoteDataSource>();
      final result = await authDataSource.updatePassword(
        userId: widget.userId,
        existingPassword: existing,
        newPassword: newPass,
        confirmPassword: confirm,
      );

      if (result is Success) {
        AppToast.success("Password updated successfully!");
        if (mounted) Navigator.pop(context);
      } else {
        AppToast.error("Failed to update password. Please check current password.");
      }
    } catch (e) {
      AppToast.error("Error updating password: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: const Text("Change Password"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _existingPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password"),
            ),
            12.h.verticalSpace,
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            12.h.verticalSpace,
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm New Password"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          onPressed: _isLoading ? null : _submitChangePassword,
          child: _isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text("Update", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
