import 'package:intl/intl.dart';

class FormatUtils {
  static String formatDistance(double distanceInMeters) {
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }

  // ----> 이 함수를 수정합니다. <----
  static String formatDuration(double totalSeconds) {
    final duration = Duration(seconds: totalSeconds.toInt());
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    // 항상 시:분:초 형식으로 표시하여 일관성을 유지합니다.
    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');

    // 1시간 미만일 경우 분:초 만 표시 (선택사항)
    if (hours > 0) {
      return '$hoursStr:$minutesStr:$secondsStr';
    } else {
      return '$minutesStr:$secondsStr';
    }
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
