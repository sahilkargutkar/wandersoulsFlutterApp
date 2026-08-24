import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/blogs_cubit.dart';
import 'package:wonder_souls/src/features/home/presentation/screens/search_screen.dart';

class ListArticle extends StatefulWidget {
  const ListArticle({super.key});
  static const String routeName = "/ListArticle";

  @override
  State<ListArticle> createState() => _ListArticleState();
}

class _ListArticleState extends State<ListArticle> {
  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year}";
    } catch (e) {
      return isoString;
    }
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

      body: BlocBuilder<BlogsCubit, BlogsState>(
        builder: (context, state) {
          if (state is BlogsLoading) {
            return Center(
              child: CircularProgressIndicator(color: context.primary),
            );
          }

          if (state is BlogsError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
              ),
            );
          }

          if (state is BlogsLoaded) {
            final blogs = state.blogs;
            if (blogs.isEmpty) {
              return Center(
                child: Text(
                  "No articles found",
                  style: context.text.bodyMedium?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              itemCount: blogs.length,
              itemBuilder: (_, index) {
                final blog = blogs[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: InkWell(
                    onTap: () {
                      context.push('/BlogDetail', extra: blog);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: ArticleCard(
                      imageUrl: blog.image,
                      title: blog.title,
                      date: _formatDate(blog.createdAt),
                      ratio: 16 / 9,
                      cardWidth: MediaQuery.of(context).size.width - 40.w,
                      readTime: blog.readTime,
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
