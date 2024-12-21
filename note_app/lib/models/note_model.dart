class Note {
  int? id;
  String title;
  String content;
  DateTime createdAt;

  Note(
      {this.id,
      required this.title,
      required this.content,
      DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  // Chuyển đổi từ Map sang Note
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // Chuyển đổi Note sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
