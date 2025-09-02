import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class FullScreenMap extends StatelessWidget {
  final List<NLatLng> routePoints;

  const FullScreenMap({super.key, required this.routePoints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: NaverMap(
        options: const NaverMapViewOptions(locationButtonEnable: true),
        // ----> 1. compassEnable을 이곳으로 이동시킵니다. <----
        onMapReady: (controller) {
          if (routePoints.isNotEmpty) {
            controller.updateCamera(
              NCameraUpdate.fitBounds(
                NLatLngBounds.from(routePoints),
                // ----> 2. padding 값을 올바른 형식으로 수정합니다. <----
                padding: const EdgeInsets.all(100),
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
