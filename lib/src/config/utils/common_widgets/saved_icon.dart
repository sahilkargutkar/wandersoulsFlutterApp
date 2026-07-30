import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/saved_places_cubit.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/animated_press.dart';

class SavedIcon extends StatefulWidget {
  final PlaceModel place;
  const SavedIcon({super.key, required this.place});

  @override
  State<SavedIcon> createState() => _SavedIconState();
}

class _SavedIconState extends State<SavedIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _wasSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SavedPlacesCubit, List<PlaceModel>>(
      listenWhen: (previous, current) => true,
      listener: (context, savedList) {
        final isSaved = savedList.any((p) {
          if (p.placeId.isNotEmpty && widget.place.placeId.isNotEmpty) {
            return p.placeId == widget.place.placeId;
          }
          return p.name == widget.place.name;
        });
        if (isSaved && !_wasSaved) {
          _controller.forward(from: 0.0);
        }
        _wasSaved = isSaved;
      },
      builder: (context, savedList) {
        final isSaved = savedList.any((p) {
          if (p.placeId.isNotEmpty && widget.place.placeId.isNotEmpty) {
            return p.placeId == widget.place.placeId;
          }
          return p.name == widget.place.name;
        });

        _wasSaved = isSaved;

        return AnimatedPress(
          onTap: () {
            context.read<SavedPlacesCubit>().toggleSave(widget.place);
          },
          scaleFactor: 0.88,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: context.colors.surface.withAlpha(230),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 20.sp,
                color: isSaved
                    ? context.colors.primary
                    : context.colors.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}
