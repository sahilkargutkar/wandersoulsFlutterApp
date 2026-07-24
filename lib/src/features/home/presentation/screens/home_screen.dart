import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/features/trips/model/static_data.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_article.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/list_destination.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/destination_explorer_screen.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/article_card.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/destination_card.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
/// HomeScreen
///
/// • Main landing screen of the app
/// • Displays search bar UI (non-functional placeholder)
/// • Shows popular destinations (horizontal list)
/// • Navigates to destination list screen
/// • Navigates to trip details screen on destination tap
/// • Shows popular articles (horizontal list)
/// • Navigates to article list screen
/// • Uses reusable common widgets (DestinationCard, ArticleCard)

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Bar
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              color: context.surface.withAlpha(25),
              elevation: 2,
              shadowColor: context.softShadow,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 24,
                      color: context.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search destinations...',
                      style: context.bodyMuted?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            22.h.height,

            // 📍 Popular Destinations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Popular Destinations', style: context.titleLarge),
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, ListDestination.routeName),
                  child: Row(
                    children: [
                      Text('View All', style: context.primaryLabel),
                      4.w.width,
                      Icon(
                        Icons.arrow_forward,
                        color: context.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            16.h.height,

            AspectRatio(
              aspectRatio: 6 / 4,

              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: destinations.length,
                shrinkWrap: true,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final d = destinations[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DestinationExplorerScreen.routeName,
                        arguments: d,
                      );
                    },
                    child: DestinationCard(
                      imageUrl: d['imageUrl']!,
                      city: d['city']!,
                      country: d['country']!,
                      flagEmoji: d['flagEmoji']!,
                      cardWidth: 200.w,
                      // compact
                    ),
                  );
                },
              ),
            ),
            24.h.height,

            // 📰 Popular Articles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Popular Articles', style: context.titleLarge),
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, ListArticle.routeName),

                  child: Row(
                    children: [
                      Text('View All', style: context.primaryLabel),
                      4.w.width,
                      Icon(
                        Icons.arrow_forward,
                        color: context.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            16.h.height,

            AspectRatio(
              aspectRatio: 4 / 3,

              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: articles.length,
                shrinkWrap: true,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return ArticleCard(
                    imageUrl: article['imageUrl']!,
                    title: article['title']!,
                    date: article['date']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
