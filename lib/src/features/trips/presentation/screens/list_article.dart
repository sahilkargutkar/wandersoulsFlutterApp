import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/static_data.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import 'package:go_router/go_router.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';

class ListArticle extends StatelessWidget {
  const ListArticle({super.key});
  static const String routeName = "/ListArticle";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 62.w,
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(left: 20.w, top: 7.h, bottom: 7.h),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: context.onSurface,
              ),
            ),
          ),
        ),

        title: Text(
          'Popular Articles',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),

        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w, top: 7.h, bottom: 7.h),
            child: GestureDetector(
              onTap: () {
                context.push(SearchScreen.routeName);
              },
              child: Container(
                width: 42.w,
                height: 42.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.mutedBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 20.sp,
                  color: context.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),

      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        itemCount: articles.length,
        itemBuilder: (_, index) {
          final article = articles[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 24.h),
            child: ArticleCard(
              imageUrl: article['imageUrl']!,
              title: article['title']!,
              date: article['date']!,
              ratio: 16 / 9,
              cardWidth: MediaQuery.of(context).size.width - 40.w,
            ),
          );
        },
      ),
    );
  }
}
