import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class ArticleCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String date;
  final double ratio;
  final double? cardWidth;

  const ArticleCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
    this.ratio = 16 / 12,
    this.cardWidth,
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

  @override
  Widget build(BuildContext context) {
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
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
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
                                "5 min read",
                                style: context.text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
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
                  Icon(
                    Icons.more_vert_rounded,
                    color: context.onSurfaceVariant,
                    size: 18.sp,
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
