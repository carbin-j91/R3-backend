// 막대 차트의 개별 막대를 위한 모델
class BarChartData {
  final String label; // x축 라벨 (예: '월', '01')
  final double value; // y축 값 (예: 총 거리)

  BarChartData({required this.label, required this.value});

  factory BarChartData.fromJson(Map<String, dynamic> json) {
    return BarChartData(
      label: json['label'],
      value: (json['value'] as num).toDouble(),
    );
  }
}

// 전체 통계 응답을 위한 모델
class Stats {
  final double totalDistanceKm;
  final int totalRuns;
  final double avgPacePerKm;
  final double totalDurationSeconds;
  final List<BarChartData> chartData;

  Stats({
    required this.totalDistanceKm,
    required this.totalRuns,
    required this.avgPacePerKm,
    required this.totalDurationSeconds,
    required this.chartData,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    var chartDataList = json['chart_data'] as List;
    List<BarChartData> parsedChartData = chartDataList
        .map((i) => BarChartData.fromJson(i))
        .toList();

    return Stats(
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      totalRuns: json['total_runs'],
      avgPacePerKm: (json['avg_pace_per_km'] as num).toDouble(),
      totalDurationSeconds: (json['total_duration_seconds'] as num).toDouble(),
      chartData: parsedChartData,
    );
  }
}
