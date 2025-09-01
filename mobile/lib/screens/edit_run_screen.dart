import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/services/api_service.dart';

class EditRunScreen extends StatefulWidget {
  final Run run;
  const EditRunScreen({super.key, required this.run});

  @override
  State<EditRunScreen> createState() => _EditRunScreenState();
}

class _EditRunScreenState extends State<EditRunScreen> {
  late final TextEditingController _distanceController;
  late final TextEditingController _durationController;
  // TODO: 시작/종료 시간 편집 기능 추가
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(
      text: (widget.run.distance / 1000).toStringAsFixed(2),
    );
    _durationController = TextEditingController(
      text: widget.run.duration.toString(),
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveRun() async {
    setState(() => _isLoading = true);
    try {
      final runDataToUpdate = RunUpdate(
        distance: (double.tryParse(_distanceController.text) ?? 0.0) * 1000,
        duration: double.tryParse(_durationController.text) ?? 0.0,
      );
      await ApiService.updateRun(widget.run.id, runDataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.runUpdateSuccess)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.runUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editRunTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _distanceController,
              decoration: const InputDecoration(
                labelText: AppStrings.editRunDistance,
                border: OutlineInputBorder(),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: AppStrings.editRunDuration,
                border: OutlineInputBorder(),
                suffixText: '초',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveRun,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(AppStrings.saveChanges),
                  ),
          ],
        ),
      ),
    );
  }
}
