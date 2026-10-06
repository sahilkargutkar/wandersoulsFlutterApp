import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_articles_cubit.dart';

class ArticleCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String date;
  final double ratio;
  final double? cardWidth;
  final String readTime;
  final BlogModel? blog;

  const ArticleCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
    this.ratio = 16 / 12,
    this.cardWidth,
    this.readTime = "5 min read",
    this.blog,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BlogModel get _effectiveBlog {
    if (widget.blog != null) return widget.blog!;
    return BlogModel(
      id: widget.title.hashCode.toString(),
      title: widget.title,
      desc: '',
      image: widget.imageUrl,
      category: 'Travel',
      readTime: widget.readTime,
      author: 'WanderSouls',
      featured: false,
      createdAt: widget.date,
      updatedAt: widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blogItem = _effectiveBlog;

    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: SizedBox(
          width: widget.cardWidth ?? 200.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: AspectRatio(
                  aspectRatio: widget.ratio,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: context.onSurface.withAlpha(20)),
                        errorWidget: (_, __, ___) => Container(
                          color: context.onSurface.withAlpha(20),
                          child: Icon(
                            Icons.image_rounded,
                            color: context.colors.onSurface.withAlpha(40),
                            size: 40,
                          ),
                        ),
                      ),

                      /// Glassmorphic Read Time Badge
                      Positioned(
                        top: 10.h,
                        left: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                                size: 12.sp,
                              ),
                              4.w.width,
                              Text(
                                widget.readTime,
                                style: context.text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// Bookmark button
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: BlocBuilder<SavedArticlesCubit, List<BlogModel>>(
                          builder: (context, savedArticles) {
                            final isSaved = savedArticles.any((a) =>
                                (a.id.isNotEmpty && a.id == blogItem.id) ||
                                (a.title == blogItem.title));

                            return GestureDetector(
                              onTap: () {
                                context
                                    .read<SavedArticlesCubit>()
                                    .toggleSave(blogItem);
                                if (!isSaved) {
                                  AppToast.success("Article saved to bookmarks! 🔖");
                                } else {
                                  AppToast.info("Article removed from bookmarks");
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: isSaved ? context.primary : Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              12.h.height,

              /// TITLE + MORE
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        height: 1.3,
                      ),
                    ),
                  ),
                  4.w.width,
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: context.onSurfaceVariant,
                      size: 18.sp,
                    ),
                    padding: EdgeInsets.zero,
                    color: context.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    onSelected: (value) {
                      if (value == 'save') {
                        context
                            .read<SavedArticlesCubit>()
                            .toggleSave(blogItem);
                        AppToast.success("Bookmark updated! 🔖");
                      } else if (value == 'share') {
                        Share.share(
                          "Check out this travel article on WanderSouls: ${widget.title}\nhttps://www.wandersouls.in",
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_border_rounded,
                                size: 18.sp, color: context.onSurface),
                            8.w.width,
                            Text("Save Article",
                                style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined,
                                size: 18.sp, color: context.onSurface),
                            8.w.width,
                            Text("Share", style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              6.h.height,

              /// DATE
              Text(
                widget.date,
                style: context.text.labelSmall?.copyWith(
                  color: context.onSurfaceVariant.withAlpha(160),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
