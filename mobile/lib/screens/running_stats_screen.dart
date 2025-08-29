import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/schemas/run_schema.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/running_calculator_service.dart';

class RunningStatsScreen extends StatefulWidget {
  const RunningStatsScreen({super.key});

  @override
  State<RunningStatsScreen> createState() => _RunningStatsScreenState();
}

class _RunningStatsScreenState extends State<RunningStatsScreen> {
  // --- 상태 변수 선언 ---
  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  bool _isRunning = false;
  final List<NLatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  double _totalCalories = 0.0;

  // ----> 1. 구간 기록을 위한 변수들을 추가합니다. <----
  final List<Map<String, dynamic>> _splits = [];
  int _lastSplitDistanceKm = 0;
  int _lastSplitTimeSeconds = 0;

  // ----> 1. 고도 관련 변수를 추가합니다. <----
  double _totalElevationGain = 0.0;
  Position? _lastPosition; // 이전 위치 정보를 저장하기 위함

  final PageController _pageController = PageController();
  final RunningCalculatorService _calculator = RunningCalculatorService(
    userWeight: 65.0,
  );

  @override
  void initState() {
    super.initState();
    _toggleRunningState();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- 로직 함수들 ---

  void _toggleRunningState() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startTracking();
        _startTimer();
      } else {
        _stopTracking();
        _stopTimer();
      }
    });
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
          if (_routePoints.isEmpty) {
            if (mounted)
              setState(
                () => _routePoints.add(
                  NLatLng(position.latitude, position.longitude),
                ),
              );
            return;
          }

          final newPoint = NLatLng(position.latitude, position.longitude);
          final lastPoint = _routePoints.last;
          final distanceDelta = Geolocator.distanceBetween(
            lastPoint.latitude,
            lastPoint.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );

          if (_lastPosition != null &&
              position.altitude > _lastPosition!.altitude) {
            _totalElevationGain += position.altitude - _lastPosition!.altitude;
          }

          if (mounted) {
            setState(() {
              _totalDistance += distanceDelta;
              _routePoints.add(newPoint);

              final currentPace = _elapsedSeconds > 0
                  ? _elapsedSeconds / (_totalDistance / 1000)
                  : 0.0;
              _totalCalories += _calculator.calculateCaloriesForDistance(
                distanceDelta,
                currentPace,
              );

              // ----> 2. 1km를 지날 때마다 구간 기록을 저장하는 로직 <----
              final currentKm = (_totalDistance / 1000).floor();
              if (currentKm > _lastSplitDistanceKm) {
                final splitTime = _elapsedSeconds - _lastSplitTimeSeconds;
                final splitPace = splitTime
                    .toDouble(); // 1km 구간이므로 시간 자체가 페이스(초/km)

                _splits.add({
                  'split': currentKm,
                  'pace': splitPace,
                  'time': splitTime,
                });

                _lastSplitDistanceKm = currentKm;
                _lastSplitTimeSeconds = _elapsedSeconds;
              }
            });
          }
        });
  }

  void _stopTracking() => _positionStream?.cancel();

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() => _timer?.cancel();
  Future<void> _finishRunning() async {
    _stopTracking();
    _stopTimer();
    if (mounted) setState(() => _isRunning = false);

    final avgPace = _calculator.calculateAveragePace(
      _totalDistance,
      _elapsedSeconds,
    );

    final runToSave = RunCreate(
      distance: _totalDistance,
      duration: _elapsedSeconds.toDouble(),
      avgPace: avgPace,
      caloriesBurned: _totalCalories,
      totalElevationGain: _totalElevationGain,
      route: _routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      splits: _splits,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFinishSheet(runToSave),
    );
  }
  // --- UI 위젯 함수들 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  _OverallStatsPage(
                    distance: _totalDistance,
                    seconds: _elapsedSeconds,
                    calories: _totalCalories,
                    elevation: _totalElevationGain,
                  ),
                  // 4. _SplitsPage에 실시간 구간 기록 데이터를 전달합니다.
                  _SplitsPage(splits: _splits),
                ],
              ),
            ),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.grey.shade800,
            ),
            onPressed: _isRunning ? _finishRunning : null,
            child: const Text(
              AppStrings.runFinish,
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(30),
              backgroundColor: _isRunning
                  ? Colors.orange
                  : Colors.green.shade400,
            ),
            onPressed: _toggleRunningState,
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.grey.shade800,
            ),
            onPressed: () {},
            child: const Icon(Icons.lock_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishSheet(RunCreate runToSave) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: NaverMap(
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
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.runCancel),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await ApiService.createRun(runToSave);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        print('기록 저장 실패: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('기록 저장에 실패했습니다. 다시 시도해주세요.'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(AppStrings.runSave),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 종합 기록 페이지 위젯
class _OverallStatsPage extends StatelessWidget {
  final double distance;
  final int seconds;
  final double calories;
  final double elevation; // <-- 5. 고도 데이터를 받습니다.

  const _OverallStatsPage({
    required this.distance,
    required this.seconds,
    required this.calories,
    required this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final paceInSeconds = distance > 0 ? (seconds / (distance / 1000)) : 0;
    final paceMinutes = (paceInSeconds / 60).floor();
    final paceSeconds = (paceInSeconds % 60).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
            _buildStatColumn(
              AppStrings.runElevation,
              '${elevation.toStringAsFixed(1)} m',
            ),
          ],
        ),
        const SizedBox(height: 30),
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
        const SizedBox(height: 30),
        _buildStatColumn(
          AppStrings.runAvgPace,
          '${paceMinutes.toString().padLeft(2, '0')}\'${paceSeconds.toString().padLeft(2, '0')}"',
        ),
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

// 구간 기록 페이지 위젯
class _SplitsPage extends StatelessWidget {
  final List<Map<String, dynamic>> splits;
  const _SplitsPage({required this.splits});

  // 초 단위를 'X'XX"' 형식으로 변환하는 함수
  String _formatPace(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}'${remainingSeconds.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return const Center(
        child: Text(
          '1km 이상 달려 구간 기록을 확인해보세요.',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.splitsHeaderKm,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
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
                child: Text(
                  AppStrings.splitsHeaderTime,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${split['split']} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
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
                        child: Text(
                          Duration(
                            seconds: split['time'],
                          ).toString().split('.').first.padLeft(8, "0"),
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
