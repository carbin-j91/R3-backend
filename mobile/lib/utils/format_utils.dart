import 'package:intl/intl.dart';

class FormatUtils {
  static String formatDistance(double distanceInMeters) {
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }

  static String formatDuration(double totalSeconds) {
    final duration = Duration(seconds: totalSeconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '$hours시간 ${minutes.toString().padLeft(2, '0')}분';
    return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
  }

  static String formatPace(double? paceInSecondsPerKm) {
    if (paceInSecondsPerKm == null || paceInSecondsPerKm <= 0) return "0'00\"";
    final duration = Duration(seconds: paceInSecondsPerKm.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date.toLocal());
  }
}
