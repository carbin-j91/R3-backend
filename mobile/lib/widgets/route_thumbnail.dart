import 'dart:math';
import 'package:flutter/material.dart';

class RouteThumbnail extends StatelessWidget {
  final List<Map<String, dynamic>> route; // [{lat, lng}, ...]
  final double borderRadius;
  const RouteThumbnail({super.key, required this.route, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _RoutePainter(route),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<Map<String, dynamic>> route;
  _RoutePainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;

    // 1) bounds 계산
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    for (final p in route) {
      final lat = (p['lat'] as num).toDouble();
      final lng = (p['lng'] as num).toDouble();
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    // 2) 여백 & 스케일(가로/세로 비율 유지)
    const padding = 6.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    final dx = maxLng - minLng;
    final dy = maxLat - minLat;
    final scaleX = dx == 0 ? 1.0 : w / dx;
    final scaleY = dy == 0 ? 1.0 : h / dy;
    final scale = min(scaleX, scaleY);

    // 중앙정렬 오프셋
    final offsetX = padding + (w - dx * scale) / 2;
    final offsetY = padding + (h - dy * scale) / 2;

    Offset toPx(num lat, num lng) {
      final x = (lng.toDouble() - minLng) * scale + offsetX;
      // y축 반전(북쪽 위)
      final y = h - (lat.toDouble() - minLat) * scale + offsetY;
      return Offset(x, y);
    }

    // 3) 경로 Path
    final path = Path()
      ..moveTo(
        toPx(route.first['lat'], route.first['lng']).dx,
        toPx(route.first['lat'], route.first['lng']).dy,
      );
    for (int i = 1; i < route.length; i++) {
      final p = route[i];
      path.lineTo(toPx(p['lat'], p['lng']).dx, toPx(p['lat'], p['lng']).dy);
    }

    // 배경(살짝 회색 그리드 느낌)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F7F9),
    );

    // 경로
    final stroke = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawPath(path, stroke);

    // 시작/끝 점
    final start = toPx(route.first['lat'], route.first['lng']);
    final end = toPx(route.last['lat'], route.last['lng']);
    canvas.drawCircle(start, 3.5, Paint()..color = Colors.green);
    canvas.drawCircle(end, 3.5, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.route != route;
}
