import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/running_calculator_service.dart';
import 'package:mobile/screens/run_result_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RunningStatsScreen extends StatefulWidget {
  const RunningStatsScreen({super.key});

  @override
  State<RunningStatsScreen> createState() => _RunningStatsScreenState();
}

class _RunningStatsScreenState extends State<RunningStatsScreen> {
  String? _runId;
  bool _isLoading = true;
  bool _isRunning = false;
  bool _isAutoPaused = false;
  DateTime? _lastPositionTimestamp;

  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerStream;

  final List<NLatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  double _totalCalories = 0.0;

  int _stepCount = 0;
  int _currentCadence = 0;
  double _lastMagnitude = 0.0;
  bool _isPeak = false;

  final List<Map<String, dynamic>> _splits = [];
  int _lastSplitDistanceKm = 0;
  int _lastSplitTimeSeconds = 0;
  int _lastSplitStepCount = 0;

  double _totalElevationGain = 0.0;
  Position? _lastPosition;

  final List<Map<String, dynamic>> _chartData = [];
  final FlutterTts _flutterTts = FlutterTts();
  final PageController _pageController = PageController();
  final RunningCalculatorService _calculator = RunningCalculatorService(
    userWeight: 65.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeTtsAndStartRun();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _timer?.cancel();
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTtsAndStartRun() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    _startNewRun();
  }

  Future<void> _startNewRun() async {
    try {
      final Run newRun = await ApiService.createRun();
      if (mounted) {
        setState(() {
          _runId = newRun.id;
          _isLoading = false;
        });
        _resumeRunning();
      }
    } catch (e) {
      print("러닝 시작 실패: $e");
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _manualPauseRunning() async {
    if (!_isRunning) return;
    _speak(AppStrings.ttsRunPaused);
    _stopTracking();
    _stopTimer();
    setState(() {
      _isRunning = false;
      _isAutoPaused = false;
    });
    await _updateRunOnServer(status: "paused");
  }

  void _resumeRunning() {
    if (_isRunning) return;
    if (_elapsedSeconds > 0) {
      _speak(AppStrings.ttsRunResumed);
    } else {
      _speak(AppStrings.ttsRunStarted);
    }
    setState(() {
      _isRunning = true;
      _isAutoPaused = false;
    });
    _startTracking();
    _startTimer();
  }

  void _finishRunning() {
    _speak(AppStrings.ttsRunFinished);
    _stopTracking();
    _stopTimer();
    if (mounted) setState(() => _isRunning = false);
    final runData = _createRunUpdateData();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RunResultScreen(
            runId: _runId!,
            runData: runData,
            onSave: () =>
                _updateRunOnServer(status: "finished", runData: runData),
            onDiscard: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
      );
    }
  }

  Future<void> _updateRunOnServer({
    required String status,
    RunUpdate? runData,
  }) async {
    if (_runId == null) return;
    final dataToUpdate = runData ?? _createRunUpdateData();
    try {
      await ApiService.updateRun(
        _runId!,
        dataToUpdate.copyWith(status: status),
      );
      print("기록 업데이트/저장 성공: status=$status");
      if (status == 'finished' && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print("기록 업데이트 실패: $e");
    }
  }

  RunUpdate _createRunUpdateData() {
    final avgPace = _calculator.calculateAveragePace(
      _totalDistance,
      _elapsedSeconds,
    );
    final avgCadence = _elapsedSeconds > 0
        ? (_stepCount / _elapsedSeconds * 60).round()
        : 0;
    return RunUpdate(
      distance: _totalDistance,
      duration: _elapsedSeconds.toDouble(),
      avgPace: avgPace,
      caloriesBurned: _totalCalories,
      totalElevationGain: _totalElevationGain,
      avgCadence: avgCadence,
      route: _routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      splits: _splits,
      chartData: _chartData,
    );
  }

  void _startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          _lastPositionTimestamp = DateTime.now();
          if (_isAutoPaused) _resumeRunning();

          if (mounted) {
            setState(() {
              final newPoint = NLatLng(position.latitude, position.longitude);
              if (_routePoints.isNotEmpty) {
                final lastPoint = _routePoints.last;
                final distanceDelta = Geolocator.distanceBetween(
                  lastPoint.latitude,
                  lastPoint.longitude,
                  newPoint.latitude,
                  newPoint.longitude,
                );
                _totalDistance += distanceDelta;
                if (_lastPosition != null &&
                    position.altitude > _lastPosition!.altitude) {
                  _totalElevationGain +=
                      position.altitude - _lastPosition!.altitude;
                }
                final currentPace = _elapsedSeconds > 0
                    ? _elapsedSeconds / (_totalDistance / 1000)
                    : 0.0;
                _totalCalories += _calculator.calculateCaloriesForDistance(
                  distanceDelta,
                  currentPace,
                );

                _chartData.add({
                  'time': _elapsedSeconds,
                  'pace': currentPace,
                  'lat': position.latitude,
                  'lng': position.longitude,
                  'distance': _totalDistance,
                });

                final currentKm = (_totalDistance / 1000).floor();
                if (currentKm > _lastSplitDistanceKm) {
                  final splitTime = _elapsedSeconds - _lastSplitTimeSeconds;
                  final splitSteps = _stepCount - _lastSplitStepCount;
                  final splitCadence = splitTime > 0
                      ? (splitSteps / splitTime * 60).round()
                      : 0;
                  final splitElevationGain =
                      _lastPosition != null &&
                          position.altitude > _lastPosition!.altitude
                      ? position.altitude - _lastPosition!.altitude
                      : 0.0;
                  _splits.add({
                    'split': currentKm,
                    'pace': splitTime.toDouble(),
                    'time': splitTime,
                    'cadence': splitCadence,
                    'elevation': splitElevationGain,
                  });
                  _lastSplitDistanceKm = currentKm;
                  _lastSplitTimeSeconds = _elapsedSeconds;
                  _lastSplitStepCount = _stepCount;

                  final totalDuration = Duration(seconds: _elapsedSeconds);
                  final totalTimeFormatted =
                      "${totalDuration.inMinutes}분 ${totalDuration.inSeconds % 60}초";
                  final avgPace = _calculator.calculateAveragePace(
                    _totalDistance,
                    _elapsedSeconds,
                  );
                  final paceMinutes = (avgPace / 60).floor();
                  final paceSeconds = (avgPace % 60).round();
                  final avgPaceFormatted =
                      "$paceMinutes분 ${paceSeconds.toString().padLeft(2, '0')}초";
                  _speak(
                    AppStrings.ttsSplitNotification(
                      currentKm,
                      totalTimeFormatted,
                      avgPaceFormatted,
                    ),
                  );
                }
              }
              _routePoints.add(newPoint);
              _lastPosition = position;
            });
          }
        });

    _accelerometerStream = userAccelerometerEventStream().listen((
      UserAccelerometerEvent event,
    ) {
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      double threshold = 1.5;
      if (_lastMagnitude < threshold && magnitude >= threshold) _isPeak = true;
      if (_isPeak && magnitude < threshold) {
        _isPeak = false;
        if (mounted) setState(() => _stepCount++);
      }
      _lastMagnitude = magnitude;
      if (mounted && _elapsedSeconds > 0) {
        setState(
          () => _currentCadence = (_stepCount / _elapsedSeconds * 60).round(),
        );
      }
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
        _checkForAutoPause();
      }
    });
  }

  void _stopTimer() => _timer?.cancel();

  void _checkForAutoPause() {
    if (_isRunning && _lastPositionTimestamp != null) {
      final secondsSinceLastMove = DateTime.now()
          .difference(_lastPositionTimestamp!)
          .inSeconds;
      if (secondsSinceLastMove >= 10) {
        _speak(AppStrings.ttsRunPaused);
        print("$secondsSinceLastMove초 동안 움직임 감지 안됨: 자동 일시정지");
        setState(() {
          _isRunning = false;
          _isAutoPaused = true;
        });
        _stopTimer();
      }
    }
  }

  Future<bool> _onWillPop() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.runExitConfirmTitle),
        content: const Text(AppStrings.runExitConfirmContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.runExitConfirmNo),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              _finishRunning();
            },
            child: const Text(AppStrings.runExitConfirmYes),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  // --- UI 위젯 함수들 ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // 이미 pop되었으면 아무 것도 하지 않음
        final bool shouldPop = await _onWillPop(); // 기존 확인 로직 유지 (Future<bool>)
        if (shouldPop && mounted) {
          Navigator.of(context).pop(result); // 확인되면 수동 pop (result 유지)
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _isRunning || _isAutoPaused
              ? _buildStatsView()
              : _buildPausedView(),
        ),
      ),
    );
  }

  Widget _buildStatsView() {
    return Column(
      children: [
        if (_isAutoPaused)
          Container(
            width: double.infinity,
            color: Colors.orange.shade800,
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "자동 일시정지됨",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        Expanded(
          child: PageView(
            controller: _pageController,
            children: [
              _OverallStatsPage(
                distance: _totalDistance,
                seconds: _elapsedSeconds,
                calories: _totalCalories,
                elevation: _totalElevationGain,
                cadence: _currentCadence,
              ),
              _SplitsPage(splits: _splits),
            ],
          ),
        ),
        _buildRunningControls(),
      ],
    );
  }

  Widget _buildPausedView() {
    return Stack(
      children: [
        NaverMap(
          options: const NaverMapViewOptions(locationButtonEnable: false),
          onMapReady: (controller) {
            _mapController = controller;
            if (_routePoints.isNotEmpty) {
              controller.updateCamera(
                NCameraUpdate.fitBounds(
                  NLatLngBounds.from(_routePoints),
                  padding: const EdgeInsets.all(50),
                ),
              );
              controller.addOverlay(
                NPolylineOverlay(
                  id: 'path',
                  coords: _routePoints,
                  color: Colors.blueAccent,
                  width: 5,
                ),
              );
            }
          },
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildPausedControls()),
      ],
    );
  }

  Widget _buildRunningControls() {
    // 자동 일시정지 상태인지 여부에 따라 버튼의 기능과 모양이 바뀝니다.
    final bool isPaused = !_isRunning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            // 자동 일시정지 상태일 때만 '길게 눌러 종료' 기능을 활성화합니다.
            onLongPress: isPaused ? _finishRunning : null,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(30),
                backgroundColor: isPaused
                    ? Colors.green.shade400
                    : Colors.orange,
              ),
              onPressed: () {
                if (isPaused) {
                  // 자동 일시정지 상태에서 짧게 누르면 '다시 시작'
                  _resumeRunning();
                } else {
                  // 러닝 중일 때 짧게 누르면 '수동 일시정지'
                  _manualPauseRunning();
                }
              },
              child: Tooltip(
                // 자동 일시정지 상태일 때만 툴팁을 보여줍니다.
                message: isPaused ? AppStrings.longPressToFinish : '',
                child: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause, // 상태에 따라 아이콘 변경
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onLongPress: _finishRunning,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(25),
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('종료하려면 3초간 길게 누르세요.')),
                );
              },
              child: const Text(
                AppStrings.runFinish,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(30),
              backgroundColor: Colors.green.shade400,
            ),
            onPressed: _resumeRunning,
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }
}

class _OverallStatsPage extends StatelessWidget {
  final double distance;
  final int seconds;
  final double calories;
  final double elevation;
  final int cadence;

  const _OverallStatsPage({
    required this.distance,
    required this.seconds,
    required this.calories,
    required this.elevation,
    required this.cadence,
  });

  @override
  Widget build(BuildContext context) {
    final paceInSeconds = distance > 0 ? (seconds / (distance / 1000)) : 0;
    final paceMinutes = (paceInSeconds / 60).floor();
    final paceSeconds = (paceInSeconds % 60).round();

    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn(
              AppStrings.runTime,
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
            ),
            _buildStatColumn(
              AppStrings.runCalories,
              calories.toStringAsFixed(0),
            ),
            _buildStatColumn(AppStrings.runCadence, cadence.toString()),
            _buildStatColumn(AppStrings.runBPM, '--'),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (distance / 1000).toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                AppStrings.runDistance,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn(
              AppStrings.runAvgPace,
              '${paceMinutes.toString().padLeft(2, '0')}\'${paceSeconds.toString().padLeft(2, '0')}"',
            ),
            _buildStatColumn(
              AppStrings.runElevation,
              '${elevation.toStringAsFixed(1)} m',
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ----> 3. _SplitsPage 위젯을 아래 코드로 교체합니다. <----
class _SplitsPage extends StatelessWidget {
  final List<Map<String, dynamic>> splits;
  const _SplitsPage({required this.splits});

  String _formatPace(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return "${minutes.toString()}'${remainingSeconds.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.splitsEmpty,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 헤더
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.splitsHeaderKm,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderPace,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.splitsHeaderElevation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderCadence,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          // 목록
          Expanded(
            child: ListView.builder(
              itemCount: splits.length,
              itemBuilder: (context, index) {
                final split = splits[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${split['split']} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatPace(split['pace']),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '+${(split['elevation'] as double).toStringAsFixed(1)}m',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${split['cadence']} spm',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
