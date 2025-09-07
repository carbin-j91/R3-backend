import 'dart:math';
import 'package:flutter/material.dart';

class RouteThumbnail extends StatelessWidget {
  final List<Map<String, dynamic>> route; // [{lat, lng}, ...]
  final double borderRadius;
  const RouteThumbnail({super.key, required this.route, this.borderRadius = 8});

  // @override
  // Widget build(BuildContext context) {
  //   return AspectRatio(
  //     aspectRatio: 16 / 9,
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(borderRadius),
  //       child: CustomPaint(
  //         painter: _RoutePainter(route),
  //         child: const SizedBox.expand(),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        painter: _RoutePainter(route),
        child:
            const SizedBox.expand(), // 부모(예: SizedBox(width:110,height:70))에 맞춰 확장
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<Map<String, dynamic>> route;
  _RoutePainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {
    // 항상 배경은 먼저 깔기
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F7F9),
    );

    if (route.isEmpty) return;
    if (route.length == 1) {
      // 한 점만 있을 때도 표시
      const padding = 6.0;
      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.drawCircle(
        Offset(cx, cy),
        3.5,
        Paint()..color = Colors.blueAccent,
      );
      return;
    }

    // 1) bounds 계산 (문자형도 대비)
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    double toDouble(v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    for (final p in route) {
      final lat = toDouble(p['lat']);
      final lng = toDouble(p['lng']);
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    // 2) 여백 & 스케일(가로/세로 비율 유지)
    const padding = 6.0;
    final w = max(1.0, size.width - padding * 2);
    final h = max(1.0, size.height - padding * 2);

    // min==max 방어 (모두 같은 위도/경도이거나 가늘게 일직선)
    const eps = 1e-6;
    double dx = maxLng - minLng;
    double dy = maxLat - minLat;
    if (dx.abs() < eps) {
      minLng -= 0.0005;
      maxLng += 0.0005;
      dx = maxLng - minLng;
    }
    if (dy.abs() < eps) {
      minLat -= 0.0005;
      maxLat += 0.0005;
      dy = maxLat - minLat;
    }

    final scaleX = w / dx;
    final scaleY = h / dy;
    final scale = min(scaleX, scaleY);

    // 중앙정렬 오프셋
    final contentW = dx * scale;
    final contentH = dy * scale;
    final offsetX = padding + (w - contentW) / 2;
    final offsetY = padding + (h - contentH) / 2;

    Offset toPx(num lat, num lng) {
      final x = (lng.toDouble() - minLng) * scale + offsetX;
      // y축 반전(북쪽 위)
      final y = (maxLat - lat.toDouble()) * scale + offsetY;
      return Offset(x, y);
    }

    // 3) Path
    final path = Path()
      ..moveTo(
        toPx(toDouble(route.first['lat']), toDouble(route.first['lng'])).dx,
        toPx(toDouble(route.first['lat']), toDouble(route.first['lng'])).dy,
      );
    for (int i = 1; i < route.length; i++) {
      final p = route[i];
      final lat = toDouble(p['lat']);
      final lng = toDouble(p['lng']);
      final pt = toPx(lat, lng);
      path.lineTo(pt.dx, pt.dy);
    }

    // 4) 경로
    final stroke = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    // 5) 시작/끝 점
    final start = toPx(
      toDouble(route.first['lat']),
      toDouble(route.first['lng']),
    );
    final end = toPx(toDouble(route.last['lat']), toDouble(route.last['lng']));
    canvas.drawCircle(
      start,
      2.5,
      Paint()..color = const Color.fromARGB(255, 55, 0, 255),
    ); // green
    canvas.drawCircle(
      end,
      2.5,
      Paint()..color = const Color(0xFFC62828),
    ); // red
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.route != route;
}
