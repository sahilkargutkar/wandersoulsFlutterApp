import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/notifications/data/models/notification_inbox_item.dart';

class NotificationItemTile extends StatelessWidget {
  final NotificationInboxItem item;
  final VoidCallback? onTap;

  const NotificationItemTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final (icon, iconBg, iconColor) = _getNotificationTypeStyle(context, item.type);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isUnread
            ? (context.isDark
                ? context.primary.withAlpha(25)
                : context.primary.withAlpha(12))
            : context.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isUnread
              ? context.primary.withAlpha(80)
              : context.borderColor.withAlpha(40),
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? context.primary.withAlpha(15)
                : context.softShadow.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            onTap?.call();
            _showNotificationDetailsBottomSheet(context);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 22.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14.sp,
                                color: context.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            SizedBox(width: 6.w),
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: context.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.body,
                        style: context.text.bodySmall?.copyWith(
                          color: context.onSurfaceVariant,
                          fontSize: 12.sp,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.timeAgo,
                            style: context.text.bodySmall?.copyWith(
                              color: context.onSurfaceVariant.withAlpha(150),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                "NEW",
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: context.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetailsBottomSheet(BuildContext context) {
    final (icon, iconBg, iconColor) = _getNotificationTypeStyle(context, item.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: context.borderColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 24.sp),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item.timeAgo,
                          style: context.text.bodySmall?.copyWith(
                            color: context.onSurfaceVariant,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(color: context.borderColor.withAlpha(40)),
              SizedBox(height: 12.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 260.h),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    item.body.isNotEmpty
                        ? item.body
                        : "No additional details available.",
                    style: context.text.bodyMedium?.copyWith(
                      color: context.onSurface,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(bottomSheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color, Color) _getNotificationTypeStyle(
    BuildContext context,
    String type,
  ) {
    final lower = type.toLowerCase();
    if (lower.contains("trip") || lower.contains("itinerary")) {
      return (
        Icons.luggage_rounded,
        const Color(0xFFF3E8FF),
        const Color(0xFF9333EA),
      );
    } else if (lower.contains("booking") ||
        lower.contains("hotel") ||
        lower.contains("flight") ||
        lower.contains("transport")) {
      return (
        Icons.confirmation_number_rounded,
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
      );
    } else if (lower.contains("welcome") || lower.contains("account")) {
      return (
        Icons.waving_hand_rounded,
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
      );
    } else if (lower.contains("promo") ||
        lower.contains("offer") ||
        lower.contains("discount")) {
      return (
        Icons.local_offer_rounded,
        const Color(0xFFFFFBEB),
        const Color(0xFFD97706),
      );
    }

    return (
      Icons.notifications_active_rounded,
      context.primary.withAlpha(25),
      context.primary,
    );
  }
}
