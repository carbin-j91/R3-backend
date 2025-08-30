import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/widgets/run_detail_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class RunResultScreen extends StatefulWidget {
  final String runId;
  final RunUpdate runData;
  final Future<void> Function() onSave;
  final VoidCallback onDiscard;

  const RunResultScreen({
    super.key,
    required this.runId,
    required this.runData,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<RunResultScreen> createState() => _RunResultScreenState();
}

class _RunResultScreenState extends State<RunResultScreen> {
  bool _showChart = false;
  NaverMapController? _mapController;
  final String _touchMarkerId = 'touch_marker';

  @override
  Widget build(BuildContext context) {
    // 이제 Run 모델에 모든 필드가 있으므로 에러 없이 객체를 생성할 수 있습니다.
    final tempRun = Run(
      id: widget.runId,
      userId: '',
      distance: widget.runData.distance ?? 0.0,
      duration: widget.runData.duration ?? 0.0,
      avgPace: widget.runData.avgPace,
      route: widget.runData.route
          .map((p) => {'lat': p['lat']!, 'lng': p['lng']!})
          .toList(),
      createdAt: DateTime.now(),
      caloriesBurned: widget.runData.caloriesBurned,
      totalElevationGain: widget.runData.totalElevationGain,
      avgCadence: widget.runData.avgCadence,
      splits: widget.runData.splits,
      chartData: widget.runData.chartData,
      status: widget.runData.status,
    );

    final routePoints = (tempRun.route ?? [])
        .map((p) => NLatLng(p['lat'], p['lng']))
        .toList();
    final chartData = tempRun.chartData ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 결과'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 지도와 상세 정보를 분리하여 보여주기 위해 Expanded와 SingleChildScrollView 사용
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 지도 영역
                    SizedBox(
                      height: 300,
                      child: NaverMap(
                        options: const NaverMapViewOptions(
                          locationButtonEnable: false,
                        ),
                        onMapReady: (controller) {
                          _mapController = controller;
                          if (routePoints.isNotEmpty) {
                            controller.updateCamera(
                              NCameraUpdate.fitBounds(
                                NLatLngBounds.from(routePoints),
                                padding: const EdgeInsets.all(
                                  50,
                                ), // <- EdgeInsets 필요
                              ),
                            );
                            controller.addOverlay(
                              NPolylineOverlay(
                                id: 'path',
                                coords: routePoints,
                                color: Colors.blueAccent,
                                width: 5,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    // '상세히 보기' 버튼
                    TextButton.icon(
                      icon: Icon(
                        _showChart
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                      label: const Text(AppStrings.viewDetails),
                      onPressed: () => setState(() => _showChart = !_showChart),
                    ),
                    // 차트 영역
                    if (_showChart && chartData.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final paceInSeconds = spot.y;
                                      final paceMinutes = (paceInSeconds / 60)
                                          .floor();
                                      final paceSeconds = (paceInSeconds % 60)
                                          .round();
                                      return LineTooltipItem(
                                        '${paceMinutes.toString().padLeft(2, '0')}\'${paceSeconds.toString().padLeft(2, '0')}"',
                                        const TextStyle(color: Colors.white),
                                      );
                                    }).toList();
                                  },
                                ),
                                touchCallback: (event, touchResponse) {
                                  if (touchResponse == null ||
                                      touchResponse.lineBarSpots == null)
                                    return;
                                  if (event is FlTapUpEvent ||
                                      event is FlLongPressEnd) {
                                    _mapController?.deleteOverlay(
                                      NOverlayInfo(
                                        type: NOverlayType.marker,
                                        id: _touchMarkerId,
                                      ),
                                    );
                                  } else {
                                    final spotIndex = touchResponse
                                        .lineBarSpots!
                                        .first
                                        .spotIndex;
                                    if (spotIndex < chartData.length) {
                                      final pointData = chartData[spotIndex];
                                      final nLatLng = NLatLng(
                                        pointData['lat'],
                                        pointData['lng'],
                                      );
                                      _mapController?.updateCamera(
                                        NCameraUpdate.scrollAndZoomTo(
                                          target: nLatLng,
                                          zoom: 18,
                                        ),
                                      );
                                      _mapController?.addOverlay(
                                        NMarker(
                                          id: _touchMarkerId,
                                          position: nLatLng,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chartData
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value['pace'],
                                        ),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  color: Colors.blueAccent,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blueAccent.withAlpha(50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 저장/삭제 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDiscard,
                      child: const Text('삭제'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
