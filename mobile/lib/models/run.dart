import 'dart:convert';

/// 백엔드 Run 스키마와 1:1 대응하되,
/// - route/splits/chart_data 가 List<Map<String,dynamic>> 또는 JSON string 으로 와도 안전 파싱
/// - snake_case(backend)와 camelCase(mobile) 키를 모두 수용
class Run {
  final String id;
  final String userId;
  final double distance; // meters
  final double duration; // seconds
  final DateTime createdAt;

  final String? title;
  final String? notes;
  final double? avgPace;
  final List<Map<String, dynamic>>? route;
  final double? caloriesBurned;
  final int? avgCadence;
  final double? totalElevationGain;
  final List<Map<String, dynamic>>? splits;
  final List<Map<String, dynamic>>? chartData; // <- 상세 차트 데이터
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

  factory Run.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v);
        if (p != null) return p;
      }
      return null;
    }

    int? toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    List<Map<String, dynamic>>? toListMap(dynamic v) {
      if (v == null) return null;
      if (v is List) {
        return v.where((e) => e != null).map<Map<String, dynamic>>((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList();
      }
      if (v is String && v.isNotEmpty) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded
                .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map),
                )
                .toList();
          }
        } catch (_) {
          // 무시: 잘못된 문자열 포맷
        }
      }
      return null;
    }

    // snake/camel 혼용 대응
    final route = toListMap(json['route']);
    final splits = toListMap(json['splits']);
    final chartData = toListMap(json['chart_data'] ?? json['chartData']);

    return Run(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId']) as String,
      distance: toDouble(json['distance']) ?? 0.0,
      duration: toDouble(json['duration']) ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),

      title: json['title'] as String?,
      notes: json['notes'] as String?,
      avgPace: toDouble(json['avg_pace']),
      route: route,
      caloriesBurned: toDouble(json['calories_burned']),
      avgCadence: toInt(json['avg_cadence']),
      totalElevationGain: toDouble(json['total_elevation_gain']),
      splits: splits,
      chartData: chartData, // ✅ 저장 후에도 항상 파싱
      status: json['status'] as String?,
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : null,
      isEdited: (json['is_edited'] as bool?) ?? false,
    );
  }
}
