import 'package:flutter/material.dart';

/// A widget that performs a staggered fade-in and slide-up animation.
class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration duration;
  final double offsetSlide;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    required this.index,
    this.delayStep = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.offsetSlide = 24.0,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _offsetY = Tween<double>(begin: widget.offsetSlide, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Run after delay
    Future.delayed(widget.delayStep * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0.0, _offsetY.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
