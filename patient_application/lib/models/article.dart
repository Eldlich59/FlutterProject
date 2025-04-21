import 'package:timeago/timeago.dart' as timeago;

class Article {
  final String id;
  final String title;
  final String content;
  final String? thumbnailUrl;
  final String authorName;
  final DateTime publishDate;
  final List<String> categories;
  final bool isFeatured;
  final int viewCount;
  final List<String>? tags;

  Article({
    required this.id,
    required this.title,
    required this.content,
    this.thumbnailUrl,
    required this.authorName,
    required this.publishDate,
    required this.categories,
    this.isFeatured = false,
    this.viewCount = 0,
    this.tags,
  });

  // Tạo nội dung tóm tắt (250 ký tự)
  String get briefContent {
    if (content.length <= 250) {
      return content;
    }
    return '${content.substring(0, 250)}...';
  }

  // Thời gian đăng bài so với hiện tại
  String get timeAgo {
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    return timeago.format(publishDate, locale: 'vi');
  }

  // Factory constructor từ JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    // Handle categories which could be String, List, or null
    List<String> categoriesList = [];

    if (json['categories'] != null) {
      if (json['categories'] is String) {
        // If it's a single string (not in expected format)
        categoriesList = [json['categories']];
      } else if (json['categories'] is List) {
        // If it's a list (expected format)
        categoriesList = List<String>.from(
          json['categories'].map((item) => item.toString()),
        );
      }
    }

    // Handle tags the same way
    List<String>? tagsList;
    if (json['tags'] != null) {
      if (json['tags'] is String) {
        tagsList = [json['tags']];
      } else if (json['tags'] is List) {
        tagsList = List<String>.from(
          json['tags'].map((item) => item.toString()),
        );
      }
    }

    // Handle view_count - convert to int if it's a string
    int viewCount = 0;
    if (json['view_count'] != null) {
      if (json['view_count'] is String) {
        viewCount = int.tryParse(json['view_count']) ?? 0;
      } else if (json['view_count'] is int) {
        viewCount = json['view_count'];
      }
    }

    // Handle is_featured - convert to bool if needed
    bool isFeatured = false;
    if (json['is_featured'] != null) {
      if (json['is_featured'] is String) {
        isFeatured = json['is_featured'].toLowerCase() == 'true';
      } else if (json['is_featured'] is bool) {
        isFeatured = json['is_featured'];
      } else if (json['is_featured'] is int) {
        isFeatured = json['is_featured'] == 1;
      }
    }

    return Article(
      id: json['id'].toString(),
      title: json['title'],
      content: json['content'],
      thumbnailUrl: json['thumbnail_url'],
      authorName: json['author_name'],
      publishDate: DateTime.parse(json['publish_date']),
      categories: categoriesList,
      isFeatured: isFeatured,
      viewCount: viewCount,
      tags: tagsList,
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'thumbnail_url': thumbnailUrl,
      'author_name': authorName,
      'publish_date': publishDate.toIso8601String(),
      'categories': categories,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'tags': tags,
    };
  }
}
