import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 필요합니다.
import 'package:mobile/models/run.dart';
import 'package:mobile/services/api_service.dart';

// 이제 HomeScreen은 러닝 기록을 보여주는 역할을 담당합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 러닝 기록'), // 제목을 더 명확하게 변경
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<Run>>(
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
                  '아직 러닝 기록이 없습니다.\n첫 번째 기록을 만들어보세요!',
                  textAlign: TextAlign.center,
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
      ),
    );
  }
}

// 하나의 러닝 기록을 표시하는 재사용 가능한 위젯
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
          // TODO: 기록 상세 보기 화면으로 이동
        },
      ),
    );
  }
}
