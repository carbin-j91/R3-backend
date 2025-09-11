import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile/models/run.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/utils/format_utils.dart';

enum ChartType { pace, elevation }

class InteractiveMapScreen extends StatefulWidget {
  final Run run;
  const InteractiveMapScreen({super.key, required this.run});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  NaverMapController? _mapController;
  final String _touchMarkerId = 'touch_marker';
  ChartType _selectedChartType = ChartType.pace;

  // 차트 데이터 생성
  List<FlSpot> _getChartSpots() {
    final chartData = widget.run.chartData ?? [];
    if (chartData.isEmpty) return [];

    return chartData.asMap().entries.map((entry) {
      final dataPoint = entry.value;
      final x = (dataPoint['time'] as num).toDouble();

      double y = 0;
      if (_selectedChartType == ChartType.pace) {
        y = (dataPoint['pace'] as num).toDouble();
        // 비정상 수치 가드
        if (y <= 0 || y > 1800) y = 0;
      } else if (_selectedChartType == ChartType.elevation) {
        if (dataPoint.containsKey('altitude')) {
          y = (dataPoint['altitude'] as num).toDouble();
        }
      }
      return FlSpot(x, y);
    }).toList();
  }

  // 정북(북쪽 ↑)으로 리셋
  Future<void> _resetNorth() async {
    if (_mapController == null) return;
    final cam = await _mapController!.getCameraPosition();
    _mapController!.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: cam.target, // 위치 유지
          zoom: cam.zoom, // 줌 유지
          bearing: 0, // 방향 초기화 (북쪽)
          tilt: 0, // 기울임 초기화
        ),
      ),
    );
  }

  LineChartBarData _lineBarData() {
    return LineChartBarData(
      spots: _getChartSpots(),
      isCurved: true,
      color: Colors.blueAccent,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.blueAccent.withAlpha(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = (widget.run.route ?? [])
        .map((p) => NLatLng(p['lat'], p['lng']))
        .toList();
    final chartData = widget.run.chartData ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('상세 분석')),
      body: Column(
        children: [
          // 지도 영역
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                NaverMap(
                  options: const NaverMapViewOptions(
                    locationButtonEnable: false,
                  ),
                  onMapReady: (controller) {
                    _mapController = controller;
                    controller.setLocationTrackingMode(
                      NLocationTrackingMode.noFollow,
                    );
                    if (routePoints.isNotEmpty) {
                      controller.updateCamera(
                        NCameraUpdate.fitBounds(
                          NLatLngBounds.from(routePoints),
                          padding: const EdgeInsets.all(50),
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
                // 우상단 정북 리셋 버튼
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    elevation: 2,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.explore),
                      tooltip: '북쪽으로 맞추기',
                      onPressed: _resetNorth,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 차트 영역
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ToggleButtons(
                    isSelected: [
                      _selectedChartType == ChartType.pace,
                      _selectedChartType == ChartType.elevation,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _selectedChartType = index == 0
                            ? ChartType.pace
                            : ChartType.elevation;
                      });
                    },
                    children: const [Text('페이스'), Text('고도')],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (spot) => Colors.blueAccent,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final yValue = spot.y;
                                String tooltipText;
                                if (_selectedChartType == ChartType.pace) {
                                  tooltipText = FormatUtils.formatPace(yValue);
                                } else {
                                  tooltipText =
                                      '${yValue.toStringAsFixed(1)} m';
                                }
                                return LineTooltipItem(
                                  tooltipText,
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                          touchCallback: (event, touchResponse) {
                            if (touchResponse == null ||
                                touchResponse.lineBarSpots == null ||
                                chartData.isEmpty) {
                              return;
                            }
                            if (event is FlTapUpEvent ||
                                event is FlLongPressEnd) {
                              _mapController?.deleteOverlay(
                                NOverlayInfo(
                                  type: NOverlayType.marker,
                                  id: _touchMarkerId,
                                ),
                              );
                            } else {
                              final spotIndex =
                                  touchResponse.lineBarSpots!.first.spotIndex;
                              if (spotIndex < chartData.length) {
                                final pointData = chartData[spotIndex];
                                final nLatLng = NLatLng(
                                  pointData['lat'],
                                  pointData['lng'],
                                );
                                _mapController?.updateCamera(
                                  NCameraUpdate.fromCameraPosition(
                                    NCameraPosition(target: nLatLng, zoom: 16),
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
                        lineBarsData: [_lineBarData()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
