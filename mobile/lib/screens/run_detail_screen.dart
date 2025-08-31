import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/screens/edit_run_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/run_detail_widget.dart'; // <-- 1. 이 줄이 가장 중요합니다!

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

  void _loadRunDetails() {
    setState(() {
      _runDetailFuture = ApiService.getRunDetail(widget.runId);
    });
  }

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
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
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
          return RunDetailWidget(run: run);
        },
      ),
    );
  }
}
