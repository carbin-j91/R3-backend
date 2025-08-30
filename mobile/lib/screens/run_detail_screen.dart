import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile/l10n/app_strings.dart'; // 1. 다국어 지원을 위해 AppStrings를 가져옵니다.
import 'package:mobile/models/run.dart';
import 'package:mobile/screens/edit_run_screen.dart'; // 2. 수정 화면을 가져옵니다.
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/format_utils.dart'; // 3. 포맷팅 도구를 가져옵니다.
import 'package:mobile/widgets/run_detail_widget.dart';

class RunDetailScreen extends StatefulWidget {
  final String runId;

  const RunDetailScreen({super.key, required this.runId});

  @override
  State<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  Future<Run>? _runDetailFuture;

  @override
  void initState() {
    super.initState();
    _loadRunDetails();
  }

  // 데이터를 다시 불러와 화면을 새로고침하는 함수
  void _loadRunDetails() {
    setState(() {
      _runDetailFuture = ApiService.getRunDetail(widget.runId);
    });
  }

  // 삭제 버튼을 눌렀을 때 실행될 함수
  Future<void> _deleteRun() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: const Text(AppStrings.deleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.runCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ApiService.deleteRun(widget.runId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.runDeleteSuccess)),
        );
        Navigator.of(context).pop(true); // 목록 화면으로 돌아가서 새로고침하도록 true 전달
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.runDeleteFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.runDetailTitle),
        // ----> 4. AppBar 오른쪽에 '더보기' 메뉴를 추가합니다. <----
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final run = await _runDetailFuture;
                if (run != null && mounted) {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => EditRunScreen(run: run),
                    ),
                  );
                  // 수정 화면에서 true를 돌려받으면, 상세 화면을 새로고침합니다.
                  if (result == true) {
                    _loadRunDetails();
                  }
                }
              } else if (value == 'delete') {
                _deleteRun();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text(AppStrings.edit),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text(AppStrings.delete),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Run>(
        future: _runDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('기록을 불러오는 데 실패했습니다.'));
          }

          final run = snapshot.data!;
          // 이제 RunDetailWidget을 사용합니다.
          return RunDetailWidget(run: run);
        },
      ),
    );
  }
}
