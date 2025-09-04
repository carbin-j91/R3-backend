import 'package:intl/intl.dart';

class FormatUtils {
  static String formatDistance(double distanceInMeters) {
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }

  static String formatDuration(double totalSeconds) {
    final duration = Duration(seconds: totalSeconds.toInt());
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hoursStr:$minutesStr:$secondsStr';
    } else {
      return '$minutesStr:$secondsStr';
    }
  }

  // ----> 1. 이 함수를 수정합니다. <----
  static String formatPace(double? paceInSecondsPerKm) {
    if (paceInSecondsPerKm == null || paceInSecondsPerKm <= 0) return "0'00\"";

    // Duration 객체를 사용하여 정확한 분과 초를 계산합니다.
    final duration = Duration(seconds: paceInSecondsPerKm.round());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date.toLocal());
  }
}
