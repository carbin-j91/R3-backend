class User {
  final String id;
  final String email;
  final String? nickname; // 닉네임은 없을 수도 있으므로 ?를 붙입니다.
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.nickname,
    required this.isActive,
    required this.createdAt,
  });

  // JSON 데이터를 User 객체로 변환하는 팩토리 생성자
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
