class User {
  final String id;
  final String email;
  final String? nickname;
  final bool isActive;
  final DateTime createdAt;
  final double? height;
  final double? weight;

  User({
    required this.id,
    required this.email,
    this.nickname,
    required this.isActive,
    required this.createdAt,
    this.height, // 생성자에 추가
    this.weight, // 생성자에 추가
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      height: (json['height'] as num?)?.toDouble(), // JSON 파싱 로직에 추가
      weight: (json['weight'] as num?)?.toDouble(), // JSON 파싱 로직에 추가
    );
  }
}
