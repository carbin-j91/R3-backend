import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/services/api_service.dart';

class RunDetailScreen extends StatefulWidget {
  final String runId; // 이전 화면에서 전달받을 러닝 기록 ID

  const RunDetailScreen({super.key, required this.runId});

  @override
  State<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  Future<Run>? _runDetailFuture;

  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때 전달받은 ID로 상세 기록을 불러옵니다.
    _runDetailFuture = ApiService.getRunDetail(widget.runId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('러닝 상세 기록')),
      body: FutureBuilder<Run>(
        future: _runDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('기록을 불러오는 데 실패했습니다: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final run = snapshot.data!;
            final routePoints = (run.route ?? [])
                .map((p) => NLatLng(p['lat'], p['lng']))
                .toList();

            return Column(
              children: [
                // 1. 지도 영역
                Expanded(
                  flex: 1,
                  child: NaverMap(
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: routePoints.isNotEmpty
                            ? routePoints.first
                            : const NLatLng(37.5665, 126.9780),
                        zoom: 15,
                      ),
                    ),
                    onMapReady: (controller) {
                      if (routePoints.isNotEmpty) {
                        // 경로가 보이도록 카메라 위치 조정
                        controller.updateCamera(
                          NCameraUpdate.fitBounds(
                            NLatLngBounds.from(routePoints),
                            padding: const EdgeInsets.all(50),
                          ),
                        );
                        // 지도 위에 경로 표시
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
                // 2. 상세 기록 정보 영역
                Expanded(flex: 1, child: _buildStatsInfo(run)),
              ],
            );
          }
          return const Center(child: Text('기록을 찾을 수 없습니다.'));
        },
      ),
    );
  }

  // 상세 기록 정보를 보여주는 위젯
  Widget _buildStatsInfo(Run run) {
    // 평균 페이스 계산
    final paceInSeconds = run.distance > 0
        ? (run.duration / (run.distance / 1000))
        : 0;
    final paceMinutes = (paceInSeconds / 60).floor();
    final paceSeconds = (paceInSeconds % 60).round();
    final avgPaceFormatted =
        '${paceMinutes.toString().padLeft(2, '0')}\'${paceSeconds.toString().padLeft(2, '0')}"';

    // 시간 포맷팅
    final durationFormatted =
        '${(run.duration ~/ 60).toString().padLeft(2, '0')}:${(run.duration.toInt() % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                '거리',
                '${(run.distance / 1000).toStringAsFixed(2)} km',
              ),
              _buildStatColumn('시간', durationFormatted),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('평균 페이스', avgPaceFormatted),
              _buildStatColumn(
                '날짜',
                DateFormat('yyyy.MM.dd').format(run.createdAt.toLocal()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 통계 표시용 위젯
  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ],
    );
  }
}
