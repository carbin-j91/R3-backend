import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  // ✅ 추가: 코스 후보 여부
  final bool isCourseCandidate;

  const RunningStatsScreen({
    super.key,
    this.isCourseCandidate = false, // 기본값
  });

  @override
  State<RunningStatsScreen> createState() => _RunningStatsScreenState();
}

class _RunningStatsScreenState extends State<RunningStatsScreen> {
  // --- 상태 변수 선언 ---
  String? _runId;
  bool _isLoading = true;
  bool _isRunning = false;
  bool _isAutoPaused = false;

  DateTime? _lastPositionTimestamp; // 최근 GPS 수신 시각
  DateTime? _lastStepAt; // 최근 스텝 시각

  // 케이던스 계산용 버퍼(최근 10초)
  final List<DateTime> _recentSteps = [];
  // 저역통과(지수이동평균) + 간단 피크 검출
  double _emaMag = 0.0;
  bool _peakUp = false;

  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerStream;

  final List<NLatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  double _totalCalories = 0.0;

  // 스텝/케이던스
  int _stepCount = 0;
  int _currentCadence = 0;

  // 스플릿
  final List<Map<String, dynamic>> _splits = [];
  int _lastSplitDistanceKm = 0;
  int _lastSplitTimeSeconds = 0;
  int _lastSplitStepCount = 0;

  // 고도
  double _totalElevationGain = 0.0;
  Position? _lastPosition;

  // 차트
  final List<Map<String, dynamic>> _chartData = [];

  // 기타
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

  // --- 핵심 로직 함수들 ---

  Future<void> _initializeTtsAndStartRun() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _startNewRun();
  }

  Future<void> _ensureLocationReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      await Geolocator.openLocationSettings();
      throw Exception('위치 서비스가 꺼져 있어요.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('위치 권한이 없어요.');
    }
  }

  Future<void> _startNewRun() async {
    try {
      await _ensureLocationReady();

      // ✅ 토글 값 전달
      final Run newRun = await ApiService.createRun(
        isCourseCandidate: widget.isCourseCandidate,
      );

      // 시작할 때 현재 위치를 한 번 읽어 시드(연속 거리 계산 시작점)
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _routePoints
        ..clear()
        ..add(NLatLng(pos.latitude, pos.longitude));
      _lastPosition = pos;
      _lastPositionTimestamp = DateTime.now();

      if (mounted) {
        setState(() {
          _runId = newRun.id;
          _isLoading = false;
        });
        _resumeRunning();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('러닝 시작 실패: $e')));
      Navigator.of(context).pop();
    }
  }

  void _manualPauseRunning() {
    if (!_isRunning) return;
    _speak(AppStrings.ttsRunPaused);
    _stopTracking();
    _stopTimer();
    setState(() {
      _isRunning = false;
      _isAutoPaused = false;
    });
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
          builder: (context) =>
              RunResultScreen(runId: _runId!, initialRunData: runData),
        ),
      );
    }
  }

  Future<bool> _saveRunToServer(RunUpdate runData) async {
    if (_runId == null) return false;
    try {
      await ApiService.updateRun(_runId!, runData.copyWith(status: 'finished'));
      debugPrint("기록 최종 저장 성공!");
      return true;
    } catch (e) {
      debugPrint("기록 최종 저장 실패: $e");
      return false;
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

  // ---------------- 위치/센서 트래킹 ----------------

  void _startTracking() {
    _startPositionStream();
    _startAccelerometer(); // ⚠️ 여기서 setState 하지 않도록 구현
  }

  void _startPositionStream() {
    _positionStream?.cancel();

    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // 가능한 자주
        intervalDuration: const Duration(seconds: 1),
        // ★ WAKE_LOCK 권한 없이도 스트림이 열리도록 false (권한 추가 후 true로 전환 가능)
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: AppStrings.foregroundNotificationTitle,
          notificationText: AppStrings.foregroundNotificationContent,
          enableWakeLock: false, // ← 중요 수정점
          notificationIcon: AndroidResource(
            name: 'launcher_icon',
            defType: 'mipmap',
          ),
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!mounted) return;

            _lastPositionTimestamp = DateTime.now();

            final newPoint = NLatLng(position.latitude, position.longitude);

            double distanceDelta = 0;
            if (_routePoints.isNotEmpty) {
              final lastPoint = _routePoints.last;
              distanceDelta = Geolocator.distanceBetween(
                lastPoint.latitude,
                lastPoint.longitude,
                newPoint.latitude,
                newPoint.longitude,
              );

              // 비현실 점프 제거(1초에 100m↑)
              if (distanceDelta < 100) {
                _totalDistance += distanceDelta;
              } else {
                distanceDelta = 0;
              }
            }

            if (_lastPosition != null &&
                position.altitude > _lastPosition!.altitude) {
              _totalElevationGain +=
                  position.altitude - _lastPosition!.altitude;
            }

            final currentPace = _elapsedSeconds > 0
                ? _elapsedSeconds / ((_totalDistance / 1000).clamp(0.001, 1e9))
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
            if (currentKm > 0 && currentKm > _lastSplitDistanceKm) {
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
                'cumulative_time': _elapsedSeconds,
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

            setState(() {
              _routePoints.add(newPoint);
              _lastPosition = position;
            });

            if (_isAutoPaused) _resumeRunning();
          },
          onError: (e) {
            debugPrint('Position stream error: $e');
          },
        );
  }

  void _startAccelerometer() {
    _accelerometerStream?.cancel();

    _accelerometerStream = userAccelerometerEventStream().listen((
      UserAccelerometerEvent event,
    ) {
      if (!_isRunning) return; // 일시정지 중엔 무시

      // 1) 크기
      final double mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // 2) 지수 이동 평균으로 baseline
      const double alpha = 0.2; // 0.1~0.3 사이 튜닝
      _emaMag = alpha * mag + (1 - alpha) * _emaMag;

      // 3) band-pass 느낌: 현재-평균
      final double signal = mag - _emaMag;

      // 4) 임계치 + 디바운스
      const double threshold = 0.8;
      const int minStepMs = 300; // 최대 200 spm
      const int maxStepMs = 2000; // 30 spm

      final now = DateTime.now();

      // 상승 교차
      if (!_peakUp && signal >= threshold) {
        _peakUp = true;
      }

      // 하강 교차에서 스텝 확정
      if (_peakUp && signal < 0) {
        _peakUp = false;

        final int sinceLast = _lastStepAt == null
            ? 99999
            : now.difference(_lastStepAt!).inMilliseconds;

        if (sinceLast >= minStepMs && sinceLast <= maxStepMs) {
          _stepCount++;
          _lastStepAt = now;

          _recentSteps.add(now);
          final cutoff = now.subtract(const Duration(seconds: 10));
          while (_recentSteps.isNotEmpty &&
              _recentSteps.first.isBefore(cutoff)) {
            _recentSteps.removeAt(0);
          }
        } else if (_lastStepAt == null) {
          // 첫 스텝은 관대하게
          _stepCount++;
          _lastStepAt = now;
          _recentSteps.add(now);
        }
      }
      // ⚠️ 여기서는 setState 하지 않음!
    }, onError: (e) => debugPrint('Accelerometer error: $e'));
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _accelerometerStream?.cancel();
    _accelerometerStream = null;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      // 1초에 한 번만 UI 갱신 (케이던스/시간/자동정지 체크)
      setState(() {
        _elapsedSeconds++;

        // 10초 윈도우 즉시 케이던스 계산
        if (_recentSteps.isNotEmpty) {
          final now = DateTime.now();
          final cutoff = now.subtract(const Duration(seconds: 10));
          while (_recentSteps.isNotEmpty &&
              _recentSteps.first.isBefore(cutoff)) {
            _recentSteps.removeAt(0);
          }
          final int windowSec = _recentSteps.length > 1
              ? now.difference(_recentSteps.first).inSeconds.clamp(1, 10)
              : 1;
          _currentCadence = ((_recentSteps.length / windowSec) * 60).round();
        } else {
          _currentCadence = 0;
        }
      });

      _checkForAutoPause();
    });
  }

  void _stopTimer() => _timer?.cancel();

  void _checkForAutoPause() {
    if (!_isRunning) return;

    final now = DateTime.now();
    final gpsAgo = _lastPositionTimestamp == null
        ? 9999
        : now.difference(_lastPositionTimestamp!).inSeconds;
    final stepAgo = _lastStepAt == null
        ? 9999
        : now.difference(_lastStepAt!).inSeconds;

    // GPS도 안 오고 스텝도 없으면 자동 일시정지
    if (gpsAgo >= 15 && stepAgo >= 10) {
      _speak(AppStrings.ttsRunPaused);
      debugPrint("$gpsAgo초(GPS)/$stepAgo초(step) 무움직임: 자동 일시정지");
      setState(() {
        _isRunning = false;
        _isAutoPaused = true;
      });
      _stopTimer();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
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

            // 좌표가 2개 이상일 때만 폴리라인/fitBounds 적용 (예외 방지)
            if (_routePoints.length >= 2) {
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
    final bool isPaused = !_isRunning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
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
                  _resumeRunning();
                } else {
                  _manualPauseRunning();
                }
              },
              child: Tooltip(
                message: isPaused ? AppStrings.longPressToFinish : '',
                child: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
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
