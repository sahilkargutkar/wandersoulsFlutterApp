import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/static_data.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonder_souls/src/config/utils/rss_feed_parser.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';

class ListArticle extends StatefulWidget {
  const ListArticle({super.key});
  static const String routeName = "/ListArticle";

  @override
  State<ListArticle> createState() => _ListArticleState();
}

class _ListArticleState extends State<ListArticle> {
  List<Map<String, String>> _dynamicArticles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://www.wanderingsouls.in/feed/');
      if (response.statusCode == 200 && response.data != null) {
        final feedContent = response.data.toString();
        final parsed = RssFeedParser.parse(feedContent);
        if (parsed.isNotEmpty) {
          setState(() {
            _dynamicArticles = parsed;
            _loading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch articles: $e");
    }
    setState(() {
      _dynamicArticles = articles; // Fallback
      _loading = false;
    });
  }

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

      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              itemCount: _dynamicArticles.length,
              itemBuilder: (_, index) {
                final article = _dynamicArticles[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: InkWell(
                    onTap: () {
                      final link = article['link'] ?? '';
                      if (link.isNotEmpty) {
                        launchUrl(
                          Uri.parse(link),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: ArticleCard(
                      imageUrl: article['imageUrl']!,
                      title: article['title']!,
                      date: article['date']!,
                      ratio: 16 / 9,
                      cardWidth: MediaQuery.of(context).size.width - 40.w,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
