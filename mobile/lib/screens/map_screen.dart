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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
                ),
                onMapReady: (controller) {
                  _mapController = controller;
                },
              ),

            // ---- 여기에 원형 이미지 버튼 추가 ----
            Positioned(
              bottom: 20, // SafeArea 안쪽을 기준으로 여백 설정
              left: 0,
              right: 0,
              child: Center(
                // 버튼을 중앙에 배치
                child: GestureDetector(
                  onTap: _currentPosition == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RunningStatsScreen(),
                            ),
                          );
                        },
                  child: Container(
                    width: 120, // 버튼의 크기
                    height: 120, // 버튼의 크기
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, // 원형으로 만듭니다.
                      boxShadow: [
                        // 그림자 효과
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/app_icon.png',
                        ), // 여기에 앱 아이콘 이미지 경로를 사용합니다.
                        fit: BoxFit.cover,
                      ),
                    ),
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
