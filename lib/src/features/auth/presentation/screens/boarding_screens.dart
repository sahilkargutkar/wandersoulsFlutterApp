import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/boarding_static_data.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < walkthroughList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (_) => false,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      walkthroughList.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
            colors: [context.colors.primary, context.colors.primary],
          ),
        ),
        child: Stack(
          children: [
            /// 🔹 IMAGE — TOP 50%
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.65,
              child: SafeArea(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: walkthroughList.length,
                  onPageChanged: (index) {
                    setState(() => currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 30.w,
                        right: 30.w,
                        top: 10.h,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.sp),

                          topRight: Radius.circular(16.sp),
                        ),
                        child: Image.asset(
                          walkthroughList[index].image,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// 🔹 BOTTOM CONTAINER — BOTTOM 50%
            Positioned(
              top: screenHeight * 0.55,
              left: 0,
              right: 0,
              bottom: 0,
              child: Card(
                elevation: 6,
                shadowColor: Colors.black.withAlpha(20),
                margin: EdgeInsets
                    .zero, // important when used in Stack / Positioned
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                clipBehavior:
                    Clip.antiAlias, // clips children to rounded corners
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 32,
                    ),
                    child: Column(
                      children: [
                        Text(
                          walkthroughList[currentPage].title,
                          textAlign: TextAlign.center,
                          style: context.text.titleLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        16.h.height,

                        Flexible(
                          child: Text(
                            walkthroughList[currentPage].description,
                            textAlign: TextAlign.center,
                            style: context.text.labelMedium?.copyWith(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),

                        24.h.height,

                        /// Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            walkthroughList.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == currentPage ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == currentPage
                                    ? context.colors.primary
                                    : context.colors.onSurfaceVariant.withAlpha(
                                        100,
                                      ),
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
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 32.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: GestureDetector(
                                    onTap: _skipToEnd,
                                    child: Text(
                                      'Skip',
                                      style: context.text.titleMedium?.copyWith(
                                        color: context.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (currentPage != walkthroughList.length - 1)
                              12.w.width,
                            Expanded(
                              child: CommonButton(
                                title: 'Continue',
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
          ],
        ),
      ),
    );
  }
}
