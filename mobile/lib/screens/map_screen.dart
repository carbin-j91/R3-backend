import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/screens/running_stats_screen.dart'; // 실제 러닝 기록 화면

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  Position? _currentPosition;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // ▼▼▼▼▼▼▼▼▼▼ 생략되었던 전체 코드입니다 ▼▼▼▼▼▼▼▼▼▼
  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 위치 서비스가 켜져 있는지 확인합니다.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _errorMessage = '위치 서비스가 비활성화되어 있습니다. 기기 설정을 확인해주세요.');
      }
      return;
    }

    // 2. 위치 권한 상태를 확인합니다.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 없다면 사용자에게 요청합니다.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _errorMessage = AppStrings.locationPermissionDenied);
        }
        return;
      }
    }

    // 사용자가 권한을 영구적으로 거부했다면, 더 이상 요청하지 않습니다.
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(
          () => _errorMessage =
              '${AppStrings.locationPermissionDenied}\n앱 설정에서 권한을 직접 허용해주세요.',
        );
      }
      return;
    }

    // 3. 모든 권한이 허용되었다면, 현재 위치를 가져옵니다.
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
  // ▲▲▲▲▲▲▲▲▲▲ 여기까지가 생략된 전체 코드입니다 ▲▲▲▲▲▲▲▲▲▲

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapReadyTitle)),
      body: Stack(
        children: [
          // 지도 표시 영역
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
              ),
              onMapReady: (controller) {
                _mapController = controller;
              },
            ),

          // 하단 '러닝 시작' 버튼
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _currentPosition == null
                  ? null
                  : () {
                      // 위치를 받아오기 전에는 버튼 비활성화
                      // '기록' 화면으로 이동
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RunningStatsScreen(),
                        ),
                      );
                    },
              child: const Text(
                AppStrings.startRunningFromMap,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
