import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class BlogDetailScreen extends StatelessWidget {
  static const String routeName = "/BlogDetail";
  final BlogModel blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    // Split description by newlines to form proper clean paragraphs
    final paragraphs = blog.desc
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Hero image
          SliverAppBar(
            expandedHeight: 280.h,
            pinned: true,
            leadingWidth: 62.w,
            leading: Padding(
              padding: EdgeInsets.only(left: 20.w, top: 7.h, bottom: 7.h),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: blog.image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: context.mutedBackground,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: context.mutedBackground,
                      child: Icon(
                        Icons.image_rounded,
                        size: 48.sp,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Dark gradient overlay at the bottom for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: context.primaryTint,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      blog.category.toUpperCase(),
                      style: context.text.labelSmall?.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Blog Title
                  Text(
                    blog.title,
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Author & Info Section
                  Row(
                    children: [
                      // Author Avatar
                      CircleAvatar(
                        radius: 18.r,
                        backgroundColor: context.primary.withAlpha(20),
                        child: Text(
                          blog.author.isNotEmpty ? blog.author[0].toUpperCase() : 'W',
                          style: TextStyle(
                            color: context.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      // Author & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.author,
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(blog.createdAt),
                              style: context.text.labelSmall?.copyWith(
                                color: context.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Read Time Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: context.mutedBackground,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12.sp,
                              color: context.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              blog.readTime,
                              style: context.text.labelSmall?.copyWith(
                                color: context.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  const Divider(),
                  SizedBox(height: 12.h),

                  // Paragraphs List
                  ...paragraphs.map((para) => Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Text(
                          para,
                          style: context.text.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 14.5.sp,
                            color: context.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      )),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ];
      return "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
    } catch (e) {
      return isoString;
    }
  }
}
