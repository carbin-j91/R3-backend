import 'dart:convert';

class RunUpdate {
  final String? title;
  final String? notes;
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
  final DateTime? endAt;
  final bool? isEdited;

  RunUpdate({
    this.title,
    this.notes,
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
    this.endAt,
    this.isEdited,
  });

  RunUpdate copyWith({String? status}) {
    return RunUpdate(
      title: title,
      notes: notes,
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (notes != null) data['notes'] = notes;
    if (distance != null) data['distance'] = distance;
    if (duration != null) data['duration'] = duration;
    if (avgPace != null) data['avg_pace'] = avgPace;
    if (caloriesBurned != null) data['calories_burned'] = caloriesBurned;
    if (totalElevationGain != null)
      data['total_elevation_gain'] = totalElevationGain;
    if (avgCadence != null) data['avg_cadence'] = avgCadence;
    if (route != null) data['route'] = route;
    if (splits != null) data['splits'] = splits;
    // chartData는 서버로 보내지 않습니다.
    if (status != null) data['status'] = status;
    return data;
  }
}
