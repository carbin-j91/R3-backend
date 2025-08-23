class Run {
  final String id;
  final String userId;
  final double distance;
  final double duration;
  final double? avgPace; // 평균 페이스는 없을 수도 있으므로 ? (nullable)
  final List<dynamic>? route; // 경로 데이터는 없을 수도 있으므로 ? (nullable)
  final DateTime createdAt;

  Run({
    required this.id,
    required this.userId,
    required this.distance,
    required this.duration,
    this.avgPace,
    this.route,
    required this.createdAt,
  });

  // JSON 데이터를 Run 객체로 변환하는 '공장' 역할을 하는 생성자
  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'],
      userId: json['user_id'],
      distance: (json['distance'] as num).toDouble(), // 안전한 타입 변환
      duration: (json['duration'] as num).toDouble(), // 안전한 타입 변환
      avgPace: (json['avg_pace'] as num?)?.toDouble(),
      route: json['route'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
