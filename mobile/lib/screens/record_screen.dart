import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/run_detail_screen.dart';
import 'package:mobile/utils/format_utils.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: AppStrings.recordTabRuns),
                  Tab(text: AppStrings.recordTabJournal),
                  Tab(text: AppStrings.recordTabAlbum),
                ],
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blueAccent,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const RunningRecordsList(),
                    const Center(child: Text('훈련일지 화면입니다.')),
                    const Center(child: Text('앨범 화면입니다.')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RunningRecordsList extends StatefulWidget {
  const RunningRecordsList({super.key});

  @override
  State<RunningRecordsList> createState() => _RunningRecordsListState();
}

class _RunningRecordsListState extends State<RunningRecordsList> {
  Future<List<Run>>? _runsFuture;

  @override
  void initState() {
    super.initState();
    _runsFuture = ApiService.getRuns();
  }

  void _refreshRuns() {
    setState(() {
      _runsFuture = ApiService.getRuns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Run>>(
      future: _runsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('기록을 불러오는데 실패했습니다: ${snapshot.error}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _refreshRuns,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasData) {
          final runs = snapshot.data!;
          if (runs.isEmpty) {
            return const Center(
              child: Text(
                '아직 러닝 기록이 없습니다.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          // 목록이 비어있지 않다면, 새로고침 가능한 목록을 보여줍니다.
          return RefreshIndicator(
            onRefresh: () async => _refreshRuns(),
            child: ListView.builder(
              itemCount: runs.length,
              itemBuilder: (context, index) {
                return RunListItem(
                  run: runs[index],
                  onRecordDeleted: _refreshRuns, // 삭제 후 목록을 새로고침하기 위한 콜백
                );
              },
            ),
          );
        }
        return const Center(child: Text('기록을 불러올 수 없습니다.'));
      },
    );
  }
}

class RunListItem extends StatelessWidget {
  final Run run;
  final VoidCallback onRecordDeleted; // 기록이 삭제되었을 때 호출될 함수

  const RunListItem({
    super.key,
    required this.run,
    required this.onRecordDeleted,
  });

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes분 $remainingSeconds초';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.directions_run,
          color: Colors.blueAccent,
          size: 40,
        ),
        title: Text(
          run.title ?? FormatUtils.formatDate(run.createdAt), // 제목이 없으면 날짜를 표시
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '거리: ${(run.distance / 1000).toStringAsFixed(2)} km / 시간: ${_formatDuration(run.duration)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          // 2. 이제 이 코드가 정상적으로 작동합니다.
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => RunDetailScreen(runId: run.id),
            ),
          );
          // 상세 화면에서 true를 돌려받으면 (삭제가 성공하면), 목록을 새로고침합니다.
          if (result == true) {
            onRecordDeleted();
          }
        },
      ),
    );
  }
}
