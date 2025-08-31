import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/utils/format_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/screens/full_screen_map.dart'; // 2단계에서 추가할 파일

class RunDetailWidget extends StatefulWidget {
  final Run run;
  const RunDetailWidget({super.key, required this.run});

  @override
  State<RunDetailWidget> createState() => _RunDetailWidgetState();
}

class _RunDetailWidgetState extends State<RunDetailWidget> {
  final bool _showSplits = false;
  bool _showChart = false;
  NaverMapController? _mapController;
  final String _touchMarkerId = 'touch_marker';

  @override
  Widget build(BuildContext context) {
    final routePoints = (widget.run.route ?? [])
        .map((p) => NLatLng(p['lat'], p['lng']))
        .toList();
    final splits = (widget.run.splits ?? []).cast<Map<String, dynamic>>();
    final chartData = (widget.run.chartData ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. 러닝 결과 요약
        _buildSummaryCard(),
        const SizedBox(height: 16),

        // 2. 구간별 기록 (접고 펴기)
        ExpansionTile(
          title: const Text("구간별 기록 보기"),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          children: [_SplitsPage(splits: splits)],
        ),
        const SizedBox(height: 16),

        // 3. 지도
        GestureDetector(
          onTap: () {
            if (routePoints.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FullScreenMap(routePoints: routePoints),
                  fullscreenDialog: true,
                ),
              );
            }
          },
          child: SizedBox(
            height: 300,
            child: NaverMap(
              options: const NaverMapViewOptions(
                scrollGesturesEnable: false,
                zoomGesturesEnable: false,
              ),
              onMapReady: (controller) {
                _mapController = controller;
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
          ),
        ),
        const SizedBox(height: 8),

        // 4. 상세히 보기 (차트 접고 펴기)
        TextButton.icon(
          icon: Icon(_showChart ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          label: const Text(AppStrings.viewDetails),
          onPressed: () => setState(() => _showChart = !_showChart),
        ),

        if (_showChart && chartData.isNotEmpty)
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final pace = spot.y;
                        final paceMinutes = (pace / 60).floor();
                        final paceSeconds = (pace % 60).round();
                        return LineTooltipItem(
                          '${paceMinutes.toString().padLeft(2, '0')}\'${paceSeconds.toString().padLeft(2, '0')}"',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (event, touchResponse) {
                    if (touchResponse == null ||
                        touchResponse.lineBarSpots == null) {
                      return;
                    }
                    if (event is FlTapUpEvent || event is FlLongPressEnd) {
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
                          NCameraUpdate.scrollAndZoomTo(
                            target: nLatLng,
                            zoom: 18,
                          ),
                        );
                        _mapController?.addOverlay(
                          NMarker(id: _touchMarkerId, position: nLatLng),
                        );
                      }
                    }
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((e) {
                      final pace = e.value['pace'] as num;
                      return FlSpot(e.key.toDouble(), pace.toDouble());
                    }).toList(),
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
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.run.title ?? FormatUtils.formatDate(widget.run.createdAt),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 1행: 거리
            Text(
              FormatUtils.formatDistance(widget.run.distance),
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // 2행: 시간, 평균 페이스
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    '시간',
                    FormatUtils.formatDuration(widget.run.duration),
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    '평균 페이스',
                    FormatUtils.formatPace(widget.run.avgPace),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 3행: 칼로리, 심박수, 고도, 케이던스
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runCalories,
                    widget.run.caloriesBurned?.toStringAsFixed(0) ?? '--',
                    isSub: true,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(AppStrings.runBPM, '--', isSub: true),
                ),
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runElevation,
                    '${widget.run.totalElevationGain?.toStringAsFixed(1) ?? '--'} m',
                    isSub: true,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runCadence,
                    widget.run.avgCadence?.toString() ?? '--',
                    isSub: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, {bool isSub = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSub ? 18 : 22,
          ),
        ),
      ],
    );
  }
}

class _SplitsPage extends StatelessWidget {
  final List<Map<String, dynamic>> splits;
  const _SplitsPage({required this.splits});

  String _formatPace(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return "${minutes.toString()}'${remainingSeconds.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            AppStrings.splitsEmpty,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.splitsHeaderKm,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderPace,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.splitsHeaderElevation,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderCadence,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: splits.length,
            itemBuilder: (context, index) {
              final split = splits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('${split['split']} km')),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatPace(split['pace']),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '+${(split['elevation'] as double).toStringAsFixed(1)}m',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${split['cadence']} spm',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
