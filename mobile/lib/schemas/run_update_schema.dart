import 'dart:convert';

class RunUpdate {
  final double? distance;
  final double? duration;
  final double? avgPace;
  final double? caloriesBurned;
  final double? totalElevationGain;
  final int? avgCadence;
  final List<Map<String, double>>? route;
  final List<Map<String, dynamic>>? splits;
  final List<Map<String, dynamic>>? chartData;
  final String? status;

  RunUpdate({
    this.distance,
    this.duration,
    this.avgPace,
    this.caloriesBurned,
    this.totalElevationGain,
    this.avgCadence,
    this.route,
    this.splits,
    this.chartData,
    this.status,
  });

  RunUpdate copyWith({String? status}) {
    return RunUpdate(
      distance: distance,
      duration: duration,
      avgPace: avgPace,
      caloriesBurned: caloriesBurned,
      totalElevationGain: totalElevationGain,
      avgCadence: avgCadence,
      route: route,
      splits: splits,
      chartData: chartData,
      status: status ?? this.status,
    );
  }

  String toJson() {
    return jsonEncode({
      'distance': distance,
      'duration': duration,
      'avg_pace': avgPace,
      'calories_burned': caloriesBurned,
      'total_elevation_gain': totalElevationGain,
      'avg_cadence': avgCadence,
      'route': route,
      'splits': splits,
      'chartData': chartData,
      'status': status,
    });
  }
}
