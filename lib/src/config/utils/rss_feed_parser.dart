class RssFeedParser {
  static List<Map<String, String>> parse(String xmlString) {
    final List<Map<String, String>> parsedArticles = [];
    final itemRegex = RegExp(r'<item>([\s\S]*?)<\/item>');
    final titleRegex = RegExp(r'<title>([\s\S]*?)<\/title>');
    final linkRegex = RegExp(r'<link>([\s\S]*?)<\/link>');
    final pubDateRegex = RegExp(r'<pubDate>([\s\S]*?)<\/pubDate>');
    final imgRegex = RegExp(r'''<img[^>]+src=["']([^"']+)["']''');

    final matches = itemRegex.allMatches(xmlString);
    for (final match in matches) {
      final itemContent = match.group(1) ?? '';
      
      final titleMatch = titleRegex.firstMatch(itemContent);
      final linkMatch = linkRegex.firstMatch(itemContent);
      final pubDateMatch = pubDateRegex.firstMatch(itemContent);
      final imgMatch = imgRegex.firstMatch(itemContent);

      var title = titleMatch?.group(1) ?? '';
      title = title.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '').trim();
      if (title.isEmpty) continue;
      
      final link = linkMatch?.group(1) ?? '';
      
      var pubDate = pubDateMatch?.group(1) ?? '';
      String formattedDate = pubDate;
      try {
        if (pubDate.isNotEmpty) {
          final parts = pubDate.split(' ');
          if (parts.length >= 4) {
            formattedDate = "${parts[2]} ${parts[1]}, ${parts[3]}";
          }
        }
      } catch (_) {}

      var imageUrl = imgMatch?.group(1) ?? 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400';
      imageUrl = imageUrl.replaceAll('&#038;', '&');

      parsedArticles.add({
        'imageUrl': imageUrl,
        'title': title,
        'date': formattedDate,
        'link': link,
      });
    }
    return parsedArticles;
  }
}
