import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/utils/format_utils.dart';
import 'package:mobile/screens/interactive_map_screen.dart';
import 'package:mobile/screens/full_screen_map.dart';

class RunDetailWidget extends StatefulWidget {
  final Run run;
  const RunDetailWidget({super.key, required this.run});

  @override
  State<RunDetailWidget> createState() => _RunDetailWidgetState();
}

class _RunDetailWidgetState extends State<RunDetailWidget> {
  bool _showSplits = false;
  NaverMapController? _mapController;
  final String _touchMarkerId = 'touch_marker';

  List<NLatLng> _routePoints = [];
  late final List<_KmPoint> _kmPoints;

  // 커스텀 마커 아이콘(비동기로 준비)
  NOverlayImage? _startMarkerIcon; // 출발(그대로 유지)
  NOverlayImage? _finishMarkerIcon; // 도착(신규)

  @override
  void initState() {
    super.initState();
    _routePoints = (widget.run.route ?? [])
        .map((p) => NLatLng(p['lat'], p['lng']))
        .toList();
    _kmPoints = _computeKmPoints(_routePoints, widget.run.distance);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initOverlayImages(); // context 필요
  }

  Future<void> _initOverlayImages() async {
    try {
      // ===== 출발 마커 아이콘 (현재 유지) =====
      // ▶ 색/크기 변경은 size / color 수정
      _startMarkerIcon ??= await NOverlayImage.fromWidget(
        context: context,
        size: const Size(26, 26), // ★ 출발 마커 크기
        widget: Container(
          decoration: BoxDecoration(
            color: Colors.green, // ★ 출발 마커 색
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      );

      // ===== 도착 마커 아이콘 (신규) =====
      // ▶ 색/크기 변경은 size / color 수정
      _finishMarkerIcon ??= await NOverlayImage.fromWidget(
        context: context,
        size: const Size(26, 26), // ★ 도착 마커 크기
        widget: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent, // ★ 도착 마커 색
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {
      // 실패 시 기본 마커 사용
    }

    // (선택) PNG 에셋을 쓰고 싶다면 예:
    // _startMarkerIcon = await NOverlayImage.fromAssetImage(
    //   'assets/images/start_pin.png', width: 30, height: 30);
    // _finishMarkerIcon = await NOverlayImage.fromAssetImage(
    //   'assets/images/finish_pin.png', width: 30, height: 30);
  }

  @override
  Widget build(BuildContext context) {
    final splits = (widget.run.splits ?? []).cast<Map<String, dynamic>>();
    final chartData = (widget.run.chartData ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),

        ExpansionTile(
          title: const Text("구간별 기록 보기"),
          onExpansionChanged: (isExpanded) =>
              setState(() => _showSplits = isExpanded),
          initiallyExpanded: _showSplits,
          children: [_SplitsPage(splits: splits)],
        ),
        const SizedBox(height: 16),

        // 지도 + 우상단 컨트롤(확대/축소/출발/도착)
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              NaverMap(
                options: const NaverMapViewOptions(
                  scrollGesturesEnable: true,
                  zoomGesturesEnable: true,
                  locationButtonEnable: false, // 내 위치 버튼 제거
                ),
                onMapReady: (controller) async {
                  _mapController = controller;
                  if (_routePoints.isNotEmpty) {
                    await controller.updateCamera(
                      NCameraUpdate.fitBounds(
                        NLatLngBounds.from(_routePoints),
                        padding: const EdgeInsets.all(50),
                      ),
                    );
                    await controller.addOverlay(
                      NPolylineOverlay(
                        id: 'path',
                        coords: _routePoints,
                        color: Colors.blueAccent, // 경로 색 변경 가능
                        width: 4,
                      ),
                    );

                    // 출발(0km) 마커
                    try {
                      await controller.deleteOverlay(
                        NOverlayInfo(
                          type: NOverlayType.marker,
                          id: 'start_marker',
                        ),
                      );
                    } catch (_) {}
                    await controller.addOverlay(
                      (_startMarkerIcon == null)
                          ? NMarker(
                              id: 'start_marker',
                              position: _routePoints.first,
                            )
                          : NMarker(
                              id: 'start_marker',
                              position: _routePoints.first,
                              icon: _startMarkerIcon,
                              anchor: const NPoint(0.5, 1.0),
                            ),
                    );

                    // 도착 마커
                    try {
                      await controller.deleteOverlay(
                        NOverlayInfo(
                          type: NOverlayType.marker,
                          id: 'finish_marker',
                        ),
                      );
                    } catch (_) {}
                    await controller.addOverlay(
                      (_finishMarkerIcon == null)
                          ? NMarker(
                              id: 'finish_marker',
                              position: _routePoints.last,
                            )
                          : NMarker(
                              id: 'finish_marker',
                              position: _routePoints.last,
                              icon: _finishMarkerIcon,
                              anchor: const NPoint(0.5, 1.0),
                            ),
                    );
                  }
                },
              ),

              // 우상단 컨트롤(줌 +/-, 출발, 도착)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Material(
                      elevation: 2,
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: '확대',
                        onPressed: () => _zoomBy(1.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      elevation: 2,
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.remove),
                        tooltip: '축소',
                        onPressed: () => _zoomBy(-1.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      elevation: 2,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _goToStart,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            '출발',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      elevation: 2,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _goToFinish,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            '도착',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 0km '출발' + (1km..nkm) + '도착' 버튼 바
        if (_routePoints.isNotEmpty || _kmPoints.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _goToStart,
                    child: const Text('출발'),
                  );
                } else if (i == _kmPoints.length + 1) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _goToFinish,
                    child: const Text('도착'),
                  );
                }
                final kp = _kmPoints[i - 1];
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _goToKmPoint(kp),
                  child: Text('${kp.km} km'),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: 2 + _kmPoints.length, // 출발 + km들 + 도착
            ),
          ),
        ],

        // 상세히 보기
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('경로 데이터 상세히 보기'),
            onPressed: () {
              if (chartData.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InteractiveMapScreen(run: widget.run),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenMap(routePoints: _routePoints),
                  ),
                );
              }
            },
          ),
        ),

        // 차트(페이스/고도)
        if (chartData.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _ChartsSection(chartData: chartData),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ------- 지도 컨트롤 -------

  Future<void> _zoomBy(double delta) async {
    final c = _mapController;
    if (c == null) return;
    final cam = await c.getCameraPosition();
    final newZoom = (cam.zoom + delta).clamp(3.0, 20.0);
    await c.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: cam.target,
          zoom: newZoom,
          bearing: cam.bearing,
          tilt: cam.tilt,
        ),
      ),
    );
  }

  Future<void> _goToStart() async {
    final c = _mapController;
    if (c == null || _routePoints.isEmpty) return;
    final start = _routePoints.first;

    try {
      await c.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: 'start_marker'),
      );
    } catch (_) {}

    // 출발 마커(커스텀 유지)
    final startMarker = (_startMarkerIcon == null)
        ? NMarker(id: 'start_marker', position: start)
        : NMarker(
            id: 'start_marker',
            position: start,
            icon: _startMarkerIcon,
            anchor: const NPoint(0.5, 1.0),
          );

    await c.addOverlay(startMarker);

    await c.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(target: start, zoom: 14),
      ),
    );
  }

  Future<void> _goToFinish() async {
    final c = _mapController;
    if (c == null || _routePoints.isEmpty) return;
    final finish = _routePoints.last;

    try {
      await c.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: 'finish_marker'),
      );
    } catch (_) {}

    // 도착 마커(커스텀 빨강)
    final finishMarker = (_finishMarkerIcon == null)
        ? NMarker(id: 'finish_marker', position: finish)
        : NMarker(
            id: 'finish_marker',
            position: finish,
            icon: _finishMarkerIcon,
            anchor: const NPoint(0.5, 1.0),
          );

    await c.addOverlay(finishMarker);

    await c.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(target: finish, zoom: 14),
      ),
    );
  }

  Future<void> _goToKmPoint(_KmPoint kp) async {
    final c = _mapController;
    if (c == null) return;
    try {
      await c.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: _touchMarkerId),
      );
    } catch (_) {}

    // ★ km별 이동 마커는 "이전 마커(기본 마커)"로 사용합니다. (아이콘 지정 안 함)
    final kmMarker = NMarker(id: _touchMarkerId, position: kp.latLng);
    await c.addOverlay(kmMarker);

    await c.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(target: kp.latLng, zoom: 14),
      ),
    );
  }

  // ------- 1km 포인트 계산 -------

  List<_KmPoint> _computeKmPoints(List<NLatLng> pts, double totalMeters) {
    if (pts.length < 2 || totalMeters < 1000) return [];
    final kmMax = totalMeters.floor() ~/ 1000;
    final targets = [for (var k = 1; k <= kmMax; k++) k * 1000.0];

    final res = <_KmPoint>[];
    double acc = 0;
    int seg = 0;
    for (final target in targets) {
      while (seg < pts.length - 1) {
        final a = pts[seg];
        final b = pts[seg + 1];
        final segLen = _haversine(a, b);
        if (acc + segLen >= target) {
          final remain = target - acc;
          final t = (segLen == 0) ? 0.0 : remain / segLen;
          final lat = a.latitude + (b.latitude - a.latitude) * t;
          final lng = a.longitude + (b.longitude - a.longitude) * t;
          res.add(
            _KmPoint(km: (target / 1000).round(), latLng: NLatLng(lat, lng)),
          );
          break;
        } else {
          acc += segLen;
          seg += 1;
        }
      }
    }
    return res;
  }

  double _haversine(NLatLng a, NLatLng b) {
    const R = 6371000.0; // meters
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);
    final h =
        pow(sin(dLat / 2), 2) + cos(la1) * cos(la2) * pow(sin(dLng / 2), 2);
    return 2 * R * asin(sqrt(h));
  }

  double _deg2rad(double d) => d * (pi / 180.0);

  // ------- 요약 카드 -------

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.run.title ??
                      FormatUtils.formatDate(widget.run.createdAt),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.run.isEdited) ...[
                  const SizedBox(width: 8),
                  const Text(
                    AppStrings.runIsEdited,
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    '거리',
                    FormatUtils.formatDistance(widget.run.distance),
                    isMain: true,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    '시간',
                    FormatUtils.formatDuration(widget.run.duration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    '평균 페이스',
                    FormatUtils.formatPace(widget.run.avgPace),
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runCadence,
                    '${widget.run.avgCadence?.toString() ?? '--'} spm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runCalories,
                    '${widget.run.caloriesBurned?.toStringAsFixed(0) ?? '--'} kcal',
                  ),
                ),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: _buildStatColumn(
                    AppStrings.runElevation,
                    '${widget.run.totalElevationGain?.toStringAsFixed(1) ?? '--'} m',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String title,
    String value, {
    bool isSub = false,
    bool isMain = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMain ? 28 : (isSub ? 18 : 22),
          ),
        ),
      ],
    );
  }
}

// ===== 차트 섹션 =====

class _ChartsSection extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  const _ChartsSection({required this.chartData});

  double? _pickNum(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final xsKm = <double>[];
    final paceY = <double>[];
    final elevY = <double>[];

    double accDist = 0;
    double accTime = 0;

    for (final m in chartData) {
      final dM = _pickNum(m, const ['distance_m', 'distance', 'd']);
      final tS = _pickNum(m, const ['t', 'time_s', 'time']);
      final paceSecPerKm = _pickNum(m, const ['pace', 'pace_s_per_km', 'spk']);
      final elev = _pickNum(m, const ['elev', 'elevation', 'alt']);

      if (dM != null) accDist = dM;
      if (tS != null) accTime = tS;

      final xKm = (accDist > 0
          ? accDist / 1000.0
          : (accTime > 0 ? (accTime / 60.0) : xsKm.length.toDouble()));
      xsKm.add(xKm);
      paceY.add(paceSecPerKm ?? 0);
      elevY.add(elev ?? 0);
    }

    List<FlSpot> toSpots(List<double> ys) {
      final n = min(xsKm.length, ys.length);
      final maxPts = 600;
      final step = n > maxPts ? (n / maxPts).ceil() : 1;
      final spots = <FlSpot>[];
      for (int i = 0; i < n; i += step) {
        spots.add(FlSpot(xsKm[i], ys[i]));
      }
      return spots;
    }

    final paceSpots = toSpots(paceY);
    final elevSpots = toSpots(elevY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('페이스(분/㎞)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 18),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: paceSpots
                      .map((s) => FlSpot(s.x, s.y > 0 ? s.y / 60.0 : 0))
                      .toList(),
                  isCurved: true,
                  dotData: const FlDotData(show: false),
                  barWidth: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('고도(m)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 18),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: elevSpots,
                  isCurved: true,
                  dotData: const FlDotData(show: false),
                  barWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 1km 포인트
class _KmPoint {
  final int km;
  final NLatLng latLng;
  _KmPoint({required this.km, required this.latLng});
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
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            AppStrings.splitsEmpty,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.splitsHeaderKm,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderPace,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderCumulativeTime,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.splitsHeaderElevation,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.splitsHeaderCadence,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: splits.length,
            itemBuilder: (context, index) {
              final split = splits[index];
              final cumulativeTime = Duration(
                seconds: (split['cumulative_time'] ?? 0) as int,
              );
              final paceSec = (split['pace'] as num?)?.toDouble() ?? 0.0;
              final elev = (split['elevation'] as num?)?.toDouble() ?? 0.0;
              final cadence = (split['cadence'] as num?)?.toInt();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('${split['split']} km')),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatPace(paceSec),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        FormatUtils.formatDuration(
                          cumulativeTime.inSeconds.toDouble(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '+${elev.toStringAsFixed(1)}m',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${cadence ?? '--'} spm',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
