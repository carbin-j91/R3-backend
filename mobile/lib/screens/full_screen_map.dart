import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class FullScreenMap extends StatelessWidget {
  final List<NLatLng> routePoints;

  const FullScreenMap({super.key, required this.routePoints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // AppBar 뒤로 지도가 보이도록 합니다.
      extendBodyBehindAppBar: true,
      body: NaverMap(
        options: const NaverMapViewOptions(locationButtonEnable: true),
        onMapReady: (controller) {
          if (routePoints.isNotEmpty) {
            controller.updateCamera(
              NCameraUpdate.fitBounds(
                NLatLngBounds.from(routePoints),
                padding: const EdgeInsets.all(100), // 전체 화면이므로 여백을 더 줍니다.
              ),
            );
            controller.addOverlay(
              NPolylineOverlay(
                id: 'full_path',
                coords: routePoints,
                color: Colors.blueAccent,
                width: 5,
              ),
            );
          }
        },
      ),
    );
  }
}
