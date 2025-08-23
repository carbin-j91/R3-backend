class User {
  final String id;
  final String email;
  final String? nickname;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.nickname,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
