import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class FullScreenMap extends StatefulWidget {
  final List<NLatLng> routePoints;

  const FullScreenMap({super.key, required this.routePoints});

  @override
  State<FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  NaverMapController? _mapController;

  void _resetNorth() {
    // 북쪽 정렬: 경로가 있으면 다시 fitBounds로 정렬합니다(사실상 bearing 0 상태로 복귀).
    if (_mapController == null || widget.routePoints.isEmpty) return;

    _mapController!.updateCamera(
      NCameraUpdate.fitBounds(
        NLatLngBounds.from(widget.routePoints),
        // 최신 버전에선 padding이 EdgeInsets여야 합니다.
        padding: const EdgeInsets.all(100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

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
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(locationButtonEnable: true),
            onMapReady: (controller) {
              _mapController = controller;

              if (widget.routePoints.isNotEmpty) {
                controller.updateCamera(
                  NCameraUpdate.fitBounds(
                    NLatLngBounds.from(widget.routePoints),
                    padding: const EdgeInsets.all(100),
                  ),
                );
                controller.addOverlay(
                  NPolylineOverlay(
                    id: 'full_path',
                    coords: widget.routePoints,
                    color: Colors.blueAccent,
                    width: 5,
                  ),
                );
              }
            },
          ),

          // ── 커스텀 나침반(북쪽 정렬) 버튼 ───────────────────────────────
          Positioned(
            right: 16,
            // AppBar를 넘겨서 보이도록 안전하게 여백을 줍니다.
            top: topInset + kToolbarHeight + 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _resetNorth,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.explore, // 나침반 느낌의 아이콘
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
