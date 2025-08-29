import 'dart:convert';

class RunCreate {
  final double distance;
  final double duration;
  final double? avgPace;
  final double? caloriesBurned; // <-- 이 줄을 추가합니다.
  final List<Map<String, double>> route;
  final List<Map<String, dynamic>>? splits;

  RunCreate({
    required this.distance,
    required this.duration,
    this.avgPace,
    this.caloriesBurned, // <-- 생성자에 추가합니다.
    required this.route,
    this.splits,
  });

  String toJson() {
    return jsonEncode({
      'distance': distance,
      'duration': duration,
      'avg_pace': avgPace,
      'calories_burned': caloriesBurned, // <-- JSON 변환에 추가합니다.
      'route': route,
      'splits': splits,
    });
  }
}
