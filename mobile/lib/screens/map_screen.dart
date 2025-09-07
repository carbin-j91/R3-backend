import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/screens/running_stats_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  Position? _currentPosition;
  String? _errorMessage;

  // ----> 1. 카운트다운을 위한 상태 변수들을 추가합니다. <----
  bool _isCountingDown = false;
  String _countdownText = '';
  Timer? _countdownTimer;

  bool _isCourseCandidate = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // 위젯 사라질 때 타이머를 꼭 종료
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _errorMessage = '위치 서비스가 비활성화되어 있습니다. 기기 설정을 확인해주세요.');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _errorMessage = AppStrings.locationPermissionDenied);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(
          () => _errorMessage =
              '${AppStrings.locationPermissionDenied}\n앱 설정에서 권한을 직접 허용해주세요.',
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '위치를 가져올 수 없습니다. GPS 신호를 확인해주세요.');
      }
    }
  }

  void _startCountdown() {
    if (_isCountingDown || _currentPosition == null) return;

    int count = 3;
    setState(() {
      _isCountingDown = true;
      _countdownText = count.toString();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (count > 1) {
        count--;
        setState(() {
          _countdownText = count.toString();
        });
      } else {
        setState(() {
          _countdownText = AppStrings.countdownGo;
        });
        // 'GO!'를 1초간 보여준 후, 러닝 화면으로 이동
        Future.delayed(const Duration(seconds: 1), () {
          timer.cancel();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    RunningStatsScreen(isCourseCandidate: _isCourseCandidate),
              ),
            );
          }
        });
      }
    });
  }

  // 정북(북쪽 ↑)으로 리셋
  Future<void> _resetNorth() async {
    if (_mapController == null) return;
    final cam = await _mapController!.getCameraPosition();
    _mapController!.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: cam.target, // 위치 유지
          zoom: cam.zoom, // 줌 유지
          bearing: 0, // 방향 초기화 (북쪽)
          tilt: 0, // 기울임 초기화
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapReadyTitle)),
      body: SafeArea(
        child: Stack(
          children: [
            if (_errorMessage != null)
              Center(child: Text(_errorMessage!, textAlign: TextAlign.center))
            else if (_currentPosition == null)
              const Center(child: CircularProgressIndicator())
            else
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: NLatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16,
                  ),
                  locationButtonEnable: true,
                  rotationGesturesEnable: true, // 회전 제스처 허
                ),
                onMapReady: (controller) {
                  _mapController = controller;
                },
              ),
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SwitchListTile(
                    title: const Text(
                      AppStrings.recordAsCourseCandidate,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _isCourseCandidate,
                    onChanged: (bool value) {
                      setState(() {
                        _isCourseCandidate = value;
                      });
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.grey),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.courseCandidateTooltip),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                elevation: 2,
                shape: const CircleBorder(),
                color: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.explore),
                  tooltip: '북쪽으로 맞추기',
                  onPressed: _resetNorth,
                ),
              ),
            ),
            // 하단 '러닝 시작' 버튼 또는 카운트다운
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _startCountdown,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      // 4. 카운트다운 상태에 따라 다른 UI를 보여줍니다.
                      image: !_isCountingDown
                          ? const DecorationImage(
                              image: AssetImage('assets/images/app_icon.png'),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: _isCountingDown
                          ? Colors.black.withValues(alpha: 0.7)
                          : null,
                    ),
                    // 카운트다운 텍스트
                    child: _isCountingDown
                        ? Center(
                            child: Text(
                              _countdownText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
