import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/running_calculator_service.dart';

class EditRunScreen extends StatefulWidget {
  final Run run;
  const EditRunScreen({super.key, required this.run});

  @override
  State<EditRunScreen> createState() => _EditRunScreenState();
}

class _EditRunScreenState extends State<EditRunScreen> {
  late final TextEditingController _distanceController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(
      text: (widget.run.distance / 1000).toStringAsFixed(2),
    );
    final duration = Duration(seconds: widget.run.duration.toInt());
    _hoursController = TextEditingController(text: duration.inHours.toString());
    _minutesController = TextEditingController(
      text: (duration.inMinutes % 60).toString(),
    );
    _secondsController = TextEditingController(
      text: (duration.inSeconds % 60).toString(),
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  Future<void> _saveRun() async {
    setState(() => _isLoading = true);
    try {
      final distance =
          (double.tryParse(_distanceController.text) ?? 0.0) * 1000;
      final hours = int.tryParse(_hoursController.text) ?? 0;
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final seconds = int.tryParse(_secondsController.text) ?? 0;
      final totalDuration = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      ).inSeconds.toDouble();

      final avgPace = RunningCalculatorService().calculateAveragePace(
        distance,
        totalDuration.toInt(),
      );

      final runDataToUpdate = RunUpdate(
        distance: distance,
        duration: totalDuration,
        avgPace: avgPace,
        isEdited: true, // 수정된 기록임을 명시
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Text(
              AppStrings.editRunDuration,
              style: TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    decoration: const InputDecoration(labelText: '시간'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Text(' : '),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    decoration: const InputDecoration(labelText: '분'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Text(' : '),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    decoration: const InputDecoration(labelText: '초'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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
