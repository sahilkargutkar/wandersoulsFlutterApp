import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/static_data.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class ListArticle extends StatelessWidget {
  const ListArticle({super.key});
  static const String routeName = "/ListArticle";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        centerTitle: true,
        leading: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => Navigator.pop(context),
          child: SizedBox(
            width: 40.w,
            height: 40.w,
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_new, // better centered than arrow_back_ios
                size: 20.sp,
                color: context.onSurface,
              ),
            ),
          ),
        ),

        title: Text('Popular Article ', style: context.text.titleLarge),

        actions: [
          // balances leading so title is truly centered
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Icon(Icons.search, color: context.onSurfaceVariant),
          ),
        ],
      ),

      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: articles.length,
        itemBuilder: (_, index) {
          final article = articles[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: ArticleCard(
              imageUrl: article['imageUrl']!,
              title: article['title']!,
              date: article['date']!,
              ratio: 16 / 8,
            ),
          );
        },
      ),
    );
  }
}
