import 'package:flutter/material.dart';

/// A wrapper widget that scales its child down on press for tactile feedback.
class AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const AnimatedPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isClickable = widget.onTap != null;

    return GestureDetector(
      onTapDown: isClickable ? (_) => _controller.forward() : null,
      onTapUp: isClickable ? (_) => _controller.reverse() : null,
      onTapCancel: isClickable ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double scale =
              1.0 - (_controller.value * (1.0 - widget.scaleFactor));
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
