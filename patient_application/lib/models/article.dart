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
    return Article(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      thumbnailUrl: json['thumbnail_url'],
      authorName: json['author_name'],
      publishDate: DateTime.parse(json['publish_date']),
      categories:
          json['categories'] != null
              ? List<String>.from(json['categories'])
              : [],
      isFeatured: json['is_featured'] ?? false,
      viewCount: json['view_count'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
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
