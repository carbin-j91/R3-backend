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
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'],
      userId: json['user_id'],
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      title: json['title'],
      notes: json['notes'],
      avgPace: (json['avg_pace'] as num?)?.toDouble(),
      route: json['route'],
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
      avgCadence: json['avg_cadence'],
      totalElevationGain: (json['total_elevation_gain'] as num?)?.toDouble(),
      splits: json['splits'],
      chartData: json['chartData'],
      status: json['status'],
    );
  }
}
