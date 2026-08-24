class BlogModel {
  final String id;
  final String title;
  final String desc;
  final String image;
  final String category;
  final String readTime;
  final String author;
  final bool featured;
  final String createdAt;
  final String updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.image,
    required this.category,
    required this.readTime,
    required this.author,
    required this.featured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      desc: json['desc'] as String? ?? json['description'] as String? ?? '',
      image: json['image'] as String? ?? json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
      readTime: json['readTime'] as String? ?? '',
      author: json['author'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'desc': desc,
      'image': image,
      'category': category,
      'readTime': readTime,
      'author': author,
      'featured': featured,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
