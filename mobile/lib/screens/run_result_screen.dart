import 'package:flutter/material.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/widgets/run_detail_widget.dart';
import 'package:mobile/services/api_service.dart'; // ApiService import

class RunResultScreen extends StatelessWidget {
  final String runId;
  final RunUpdate initialRunData; // 이제 초기 데이터로 받습니다.

  const RunResultScreen({
    super.key,
    required this.runId,
    required this.initialRunData,
  });

  // 1. '저장' 버튼을 눌렀을 때 실행될 함수를 이 화면이 직접 가집니다.
  Future<void> _saveRun(BuildContext context) async {
    try {
      // status를 'finished'로 설정하여 최종 저장합니다.
      await ApiService.updateRun(
        runId,
        initialRunData.copyWith(status: 'finished'),
      );
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기록 저장에 실패했습니다.')));
      }
    }
  }

  // 2. '삭제' 버튼을 눌렀을 때 실행될 함수
  void _discardRun(BuildContext context) {
    // TODO: 백엔드에 임시 기록 삭제 API 호출 (선택사항)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final tempRun = Run(
      id: runId,
      userId: '',
      distance: initialRunData.distance ?? 0.0,
      duration: initialRunData.duration ?? 0.0,
      avgPace: initialRunData.avgPace,
      route: initialRunData.route
          ?.map((p) => {'lat': p['lat']!, 'lng': p['lng']!})
          .toList(),
      createdAt: DateTime.now(),
      caloriesBurned: initialRunData.caloriesBurned,
      totalElevationGain: initialRunData.totalElevationGain,
      avgCadence: initialRunData.avgCadence,
      splits: initialRunData.splits,
      chartData: initialRunData.chartData,
      status: initialRunData.status,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 결과'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: RunDetailWidget(run: tempRun)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _discardRun(context),
                      child: const Text('삭제'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveRun(context),
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
