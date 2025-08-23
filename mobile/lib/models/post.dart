import 'package:mobile/models/user.dart'; // 작성자 정보를 담기 위해 User 모델을 가져옵니다.

class Post {
  final String id;
  final String title;
  final String? content;
  final String userId;
  final DateTime createdAt;
  final User? author; // 작성자 정보 (nullable)

  Post({
    required this.id,
    required this.title,
    this.content,
    required this.userId,
    required this.createdAt,
    this.author,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      // author 필드가 null이 아닐 경우에만 User.fromJson을 호출합니다.
      author: json['author'] != null ? User.fromJson(json['author']) : null,
    );
  }
}
