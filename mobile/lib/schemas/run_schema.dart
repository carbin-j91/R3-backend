// lib/schemas/run_schema.dart

import 'dart:convert';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class RunCreate {
  final double distance;
  final double duration;
  final double? avgPace;
  final List<Map<String, double>> route;

  RunCreate({
    required this.distance,
    required this.duration,
    this.avgPace,
    required this.route,
  });

  String toJson() {
    return jsonEncode({
      'distance': distance,
      'duration': duration,
      'avg_pace': avgPace,
      'route': route,
    });
  }
}
