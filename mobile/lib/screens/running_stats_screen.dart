import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/schemas/run_schema.dart';
import 'package:mobile/services/api_service.dart';
import 'package:intl/intl.dart';

class RunningStatsScreen extends StatefulWidget {
  const RunningStatsScreen({super.key});

  @override
  State<RunningStatsScreen> createState() => _RunningStatsScreenState();
}

class _RunningStatsScreenState extends State<RunningStatsScreen> {
  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  bool _isRunning = false;
  final List<NLatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // 화면이 시작되자마자 러닝을 시작합니다.
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
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final newPoint = NLatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(() {
                if (_routePoints.isNotEmpty) {
                  final lastPoint = _routePoints.last;
                  _totalDistance += Geolocator.distanceBetween(
                    lastPoint.latitude,
                    lastPoint.longitude,
                    newPoint.latitude,
                    newPoint.longitude,
                  );
                }
                _routePoints.add(newPoint);
              });
            }
          },
        );
  }

  void _stopTracking() {
    _positionStream?.cancel();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _finishRunning() async {
    _stopTracking();
    _stopTimer();
    if (mounted) setState(() => _isRunning = false);

    final avgPace = _totalDistance > 0
        ? (_elapsedSeconds / (_totalDistance / 1000))
        : 0.0;

    final runToSave = RunCreate(
      distance: _totalDistance,
      duration: _elapsedSeconds.toDouble(),
      avgPace: avgPace,
      route: _routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
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
                  ),
                  const _SplitsPage(),
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
  const _OverallStatsPage({required this.distance, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final paceInSeconds = distance > 0 ? (seconds / (distance / 1000)) : 0;
    final paceMinutes = (paceInSeconds / 60).floor();
    final paceSeconds = (paceInSeconds % 60).round();

    return Column(
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
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn(
              AppStrings.runTime,
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
            ),
            _buildStatColumn(
              AppStrings.runAvgPace,
              '${paceMinutes.toString().padLeft(2, '0')}\'${paceSeconds.toString().padLeft(2, '0')}"',
            ),
          ],
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
  const _SplitsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '구간별 기록 UI가 표시될 공간입니다.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
