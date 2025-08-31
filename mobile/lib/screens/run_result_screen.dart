import 'package:flutter/material.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/widgets/run_detail_widget.dart';

class RunResultScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tempRun = Run(
      id: runId,
      userId: '',
      distance: runData.distance ?? 0.0,
      duration: runData.duration ?? 0.0,
      avgPace: runData.avgPace,
      route: runData.route
          ?.map((p) => {'lat': p['lat']!, 'lng': p['lng']!})
          .toList(),
      createdAt: DateTime.now(),
      caloriesBurned: runData.caloriesBurned,
      totalElevationGain: runData.totalElevationGain,
      avgCadence: runData.avgCadence,
      splits: runData.splits,
      chartData: runData.chartData,
      status: runData.status,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 결과'),
        automaticallyImplyLeading: false,
      ),
      // ----> 2. body를 SafeArea로 감싸 문제를 해결합니다. <----
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: RunDetailWidget(run: tempRun)),
            // 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDiscard,
                      child: const Text('삭제'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
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
