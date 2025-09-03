import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/utils/format_utils.dart';
import 'package:mobile/screens/interactive_map_screen.dart'; // 2단계에서 추가할 파일

class RunDetailWidget extends StatefulWidget {
  final Run run;
  const RunDetailWidget({super.key, required this.run});

  @override
  State<RunDetailWidget> createState() => _RunDetailWidgetState();
}

class _RunDetailWidgetState extends State<RunDetailWidget> {
  bool _showSplits = false;
  final bool _showChart = false;
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
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      children: [
        // 1. 러닝 결과 요약
        _buildSummaryCard(),
        const SizedBox(height: 16),

        // 2. 구간별 기록 (접고 펴기)
        ExpansionTile(
          title: const Text("구간별 기록 보기"),
          onExpansionChanged: (isExpanded) {
            setState(() {
              _showSplits = isExpanded;
            });
          },
          initiallyExpanded: _showSplits,
          children: [_SplitsPage(splits: splits)],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 300,
          child: NaverMap(
            options: const NaverMapViewOptions(
              scrollGesturesEnable: false,
              zoomGesturesEnable: false,
            ),
            onMapReady: (controller) {
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

        // ----> 1. 새로운 '상세히 보기' 버튼 <----
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.analytics_outlined),
            label: const Text(AppStrings.viewDetails),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InteractiveMapScreen(run: widget.run),
                ),
              );
            },
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
            Row(
              children: [
                Text(
                  widget.run.title ??
                      FormatUtils.formatDate(widget.run.createdAt),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.run.isEdited) ...[
                  const SizedBox(width: 8),
                  const Text(
                    AppStrings.runIsEdited,
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    '거리',
                    FormatUtils.formatDistance(widget.run.distance),
                    isMain: true,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    '시간',
                    FormatUtils.formatDuration(widget.run.duration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 2행: 평균 페이스, 케이던스
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    '평균 페이스',
                    FormatUtils.formatPace(widget.run.avgPace),
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runCadence,
                    '${widget.run.avgCadence?.toString() ?? '--'} spm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 3행: 칼로리, 심박수, 고도
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runCalories,
                    '${widget.run.caloriesBurned?.toStringAsFixed(0) ?? '--'} kcal',
                  ),
                ),
                Expanded(child: _buildStatColumn(AppStrings.runBPM, '--')),
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runElevation,
                    '${widget.run.totalElevationGain?.toStringAsFixed(1) ?? '--'} m',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String title,
    String value, {
    bool isSub = false,
    bool isMain = false,
  }) {
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
            fontSize: isMain ? 28 : (isSub ? 18 : 22),
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
