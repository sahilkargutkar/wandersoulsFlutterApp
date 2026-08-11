import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/boarding_static_data.dart';
import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/common_button.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class BoardingScreens extends StatefulWidget {
  const BoardingScreens({super.key});
  static const String routeName = "/BoardingScreens";

  @override
  State<BoardingScreens> createState() => _BoardingScreensState();
}

class _BoardingScreensState extends State<BoardingScreens> {
  int currentPage = 0;
  final PageController _pageController = PageController();
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < walkthroughList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(LoginScreen.routeName);
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      walkthroughList.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.primary, context.primary.withAlpha(220)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -40.h,
              right: -40.w,
              child: Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                ),
              ),
            ),

            /// IMAGE — TOP (with Parallax effect)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.60,
              child: SafeArea(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: walkthroughList.length,
                  onPageChanged: (index) {
                    setState(() => currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final double offset = index - _pageOffset;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: 28.w,
                        right: 28.w,
                        top: 16.h,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Transform.translate(
                          offset: Offset(offset * 40.w, 0), // Parallel offset
                          child: Image.asset(
                            walkthroughList[index].image,
                            fit: BoxFit.cover,
                            alignment: Alignment(-offset * 0.4, 0),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// BOTTOM CONTAINER
            Positioned(
              top: screenHeight * 0.52,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipPath(
                clipper: ConcaveTopClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 52.h,
                        bottom: 12.h,
                        left: 32.w,
                        right: 32.w,
                      ),
                      child: Column(
                        children: [
                          // Animated Text switch on page swipe
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(0.0, 0.12),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey<int>(currentPage),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    walkthroughList[currentPage].title,
                                    textAlign: TextAlign.center,
                                    style: context.text.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                  14.h.height,
                                  Text(
                                    walkthroughList[currentPage].description,
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyLarge?.copyWith(
                                      height: 1.5,
                                      color: context.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          20.h.height,

                          /// Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              walkthroughList.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: index == currentPage ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == currentPage
                                      ? context.primary
                                      : context.onSurfaceVariant.withAlpha(60),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          24.h.height,

                          /// Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (currentPage != walkthroughList.length - 1)
                                Flexible(
                                  child: GestureDetector(
                                    onTap: _skipToEnd,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.h,
                                        horizontal: 28.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.primaryTint,
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Text(
                                        'Skip',
                                        style: context.text.titleSmall
                                            ?.copyWith(
                                              color: context.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (currentPage != walkthroughList.length - 1)
                                12.w.width,
                              Expanded(
                                child: CommonButton(
                                  title:
                                      currentPage == walkthroughList.length - 1
                                      ? 'Get Started'
                                      : 'Continue',
                                  onPressed: _nextPage,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConcaveTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(size.width / 2, 80, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
