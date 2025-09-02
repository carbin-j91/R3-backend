// 이 모델은 백엔드의 'Run' 스키마와 1:1로 대응합니다.
class Run {
  final String id;
  final String userId;
  final double distance;
  final double duration;
  final DateTime createdAt;

  final String? title;
  final String? notes;
  final double? avgPace;
  final List<dynamic>? route;
  final double? caloriesBurned;
  final int? avgCadence;
  final double? totalElevationGain;
  final List<dynamic>? splits;
  final List<dynamic>? chartData;
  final String? status;
  final DateTime? endAt;
  final bool isEdited;

  Run({
    required this.id,
    required this.userId,
    required this.distance,
    required this.duration,
    required this.createdAt,
    this.title,
    this.notes,
    this.avgPace,
    this.route,
    this.caloriesBurned,
    this.avgCadence,
    this.totalElevationGain,
    this.splits,
    this.chartData,
    this.status,
    this.endAt,
    this.isEdited = false,
  });

  // --- 수정된 최종 팩토리 생성자 ---
  factory Run.fromJson(Map<String, dynamic> json) {
    // 안전한 타입 변환을 위한 헬퍼 함수
    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return null;
    }

    return Run(
      id: json['id'],
      userId: json['user_id'],
      distance: toDouble(json['distance']) ?? 0.0,
      duration: toDouble(json['duration']) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),

      title: json['title'],
      notes: json['notes'],
      avgPace: toDouble(json['avg_pace']),
      route: json['route'],
      caloriesBurned: toDouble(json['calories_burned']),
      avgCadence: json['avg_cadence'],
      totalElevationGain: toDouble(json['total_elevation_gain']),
      splits: json['splits'],
      chartData:
          json['chartData'], // 서버 모델에 chartData가 없으면 이 줄은 오류를 유발할 수 있습니다.
      status: json['status'],
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      isEdited: json['is_edited'] ?? false,
    );
  }
}
