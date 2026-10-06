import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wonder_souls/src/config/model/user_model.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';

class ProfileImageHelper {
  ProfileImageHelper._();

  /// Resolves an ImageProvider for the user profile image
  static ImageProvider? getImageProvider(String? profilePicture) {
    if (profilePicture == null || profilePicture.trim().isEmpty) {
      return null;
    }

    final trimmed = profilePicture.trim();

    // 1. Network image
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      return CachedNetworkImageProvider(trimmed);
    }

    // 2. Local file
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}

    return null;
  }

  /// Builds a profile avatar widget with graceful fallbacks (image -> initials -> icon)
  static Widget buildAvatar(
    BuildContext context, {
    required UserModel? user,
    double radius = 24,
    VoidCallback? onTap,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    final String name = user?.name ?? user?.userName ?? "";
    final String initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : (user?.email?.isNotEmpty == true
            ? user!.email![0].toUpperCase()
            : "U");

    final profilePicture = user?.profilePicture?.trim();
    final bool hasValidNetworkUrl = profilePicture != null &&
        (profilePicture.startsWith("http://") ||
            profilePicture.startsWith("https://"));
    final bool hasValidLocalPath = profilePicture != null &&
        !hasValidNetworkUrl &&
        profilePicture.isNotEmpty &&
        File(profilePicture).existsSync();

    Widget fallback = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.primary.withAlpha(25),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.bold,
            color: context.primary,
          ),
        ),
      ),
    );

    Widget imageContent;
    if (hasValidNetworkUrl) {
      imageContent = CachedNetworkImage(
        imageUrl: profilePicture,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: radius * 2,
          height: radius * 2,
          color: context.primary.withAlpha(15),
          child: Center(
            child: SizedBox(
              width: radius * 0.7,
              height: radius * 0.7,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.primary.withAlpha(120),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (hasValidLocalPath) {
      imageContent = Image.file(
        File(profilePicture),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      imageContent = fallback;
    }

    Widget avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? context.primary.withAlpha(80),
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(
        child: imageContent,
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
