import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wonder_souls/src/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:wonder_souls/src/features/notifications/presentation/widgets/notification_item_tile.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = "/NotificationsScreen";

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: context.onSurface,
          ),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<NotificationsCubit>().markAllAsRead();
                  },
                  icon: Icon(
                    Icons.done_all_rounded,
                    size: 16.sp,
                    color: context.primary,
                  ),
                  label: Text(
                    "Mark all read",
                    style: TextStyle(
                      color: context.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return _buildLoadingSkeleton(context);
          }

          if (state is NotificationsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is NotificationsLoaded) {
            final allCount = state.notifications.length;
            final unreadCount = state.unreadCount;
            final items = state.filteredNotifications;

            return RefreshIndicator(
              color: context.primary,
              onRefresh: () async {
                await context
                    .read<NotificationsCubit>()
                    .fetchNotifications(showLoading: false);
              },
              child: Column(
                children: [
                  // Filter Chips
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context,
                          label: "All",
                          count: allCount,
                          isSelected: state.filter == NotificationFilter.all,
                          onTap: () {
                            context
                                .read<NotificationsCubit>()
                                .setFilter(NotificationFilter.all);
                          },
                        ),
                        SizedBox(width: 8.w),
                        _buildFilterChip(
                          context,
                          label: "Unread",
                          count: unreadCount,
                          isSelected: state.filter == NotificationFilter.unread,
                          onTap: () {
                            context
                                .read<NotificationsCubit>()
                                .setFilter(NotificationFilter.unread);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Notifications list or empty state
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState(context, state.filter)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return NotificationItemTile(
                                item: item,
                                onTap: () {
                                  if (!item.isRead) {
                                    context
                                        .read<NotificationsCubit>()
                                        .markAsRead(item.id);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primary
              : (context.isDark
                  ? context.surface
                  : context.mutedBackground),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? context.primary
                : context.borderColor.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.onSurface,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(50)
                      : context.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : context.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, NotificationFilter filter) {
    final isUnreadFilter = filter == NotificationFilter.unread;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 80.h),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: context.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isUnreadFilter
                        ? Icons.mark_email_read_rounded
                        : Icons.notifications_none_rounded,
                    color: context.primary,
                    size: 38.sp,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                isUnreadFilter
                    ? "You're all caught up!"
                    : "No notifications yet",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                isUnreadFilter
                    ? "You don't have any unread notifications."
                    : "Trip reminders, booking updates, and travel announcements will show up here.",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.onSurfaceVariant,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.colors.error,
              size: 44.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              "Unable to load notifications",
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationsCubit>().fetchNotifications();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.borderColor.withAlpha(30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 80.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: context.mutedBackground,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
