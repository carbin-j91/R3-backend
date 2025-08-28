import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/my_runs_screen.dart';
import 'package:mobile/screens/run_detail_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // AppBar를 제거하고, body에서부터 시작합니다.
        body: SafeArea(
          child: Column(
            children: [
              // 1. 커스텀 탭바
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
              // 2. 탭바 아래의 내용
              Expanded(
                child: TabBarView(
                  children: [
                    // '러닝기록' 탭: 기존 RunningRecordsList 위젯을 그대로 사용
                    RunningRecordsList(),
                    // '훈련일지' 탭 (임시)
                    Center(child: Text('훈련일지 화면입니다.')),
                    // '앨범' 탭 (임시)
                    Center(child: Text('앨범 화면입니다.')),
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

// '러닝기록' 탭의 내용을 보여주는 위젯 (기존 MyRunsScreen의 코드를 재활용)
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
          return ListView.builder(
            itemCount: runs.length,
            itemBuilder: (context, index) {
              return RunListItem(run: runs[index]);
            },
          );
        }
        return const Center(child: Text('기록을 불러올 수 없습니다.'));
      },
    );
  }
}

// 하나의 러닝 기록 아이템 위젯 (기존과 동일)
class RunListItem extends StatelessWidget {
  final Run run;
  const RunListItem({super.key, required this.run});

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
          '${(run.distance / 1000).toStringAsFixed(2)} km',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '시간: ${_formatDuration(run.duration)}\n일시: ${DateFormat('yyyy년 MM월 dd일').format(run.createdAt.toLocal())}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // onTap을 누르면 RunDetailScreen으로 이동하도록 수정합니다.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RunDetailScreen(runId: run.id),
            ),
          );
        },
      ),
    );
  }
}
