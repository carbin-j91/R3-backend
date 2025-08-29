class RunningCalculatorService {
  // 사용자의 체중 (kg) - 지금은 65kg으로 가정, 나중에는 사용자 프로필에서 가져와야 함
  final double userWeight;

  RunningCalculatorService({this.userWeight = 65.0});

  // MET(Metabolic Equivalent of Task) 값을 기반으로 칼로리를 계산합니다.
  double _getMET(double paceInSecPerKm) {
    // ----> 여기서 오타를 수정했습니다. <----
    if (paceInSecPerKm <= 0) return 0;

    // 1km를 달리는 데 걸리는 분
    final double minutesPerKm = paceInSecPerKm / 60.0;

    // 페이스에 따른 MET 값 (일반적인 추정치)
    if (minutesPerKm <= 4.5) return 14.0; // 4분 30초 페이스 (매우 빠름)
    if (minutesPerKm <= 5.0) return 12.5; // 5분 페이스
    if (minutesPerKm <= 5.5) return 11.5; // 5분 30초 페이스
    if (minutesPerKm <= 6.0) return 10.5; // 6분 페이스
    if (minutesPerKm <= 7.0) return 9.0; // 7분 페이스 (조깅)
    return 7.0; // 7분 이상 (가벼운 조깅)
  }

  // 실시간 칼로리 계산
  double calculateCaloriesForDistance(
    double distanceDeltaInMeters,
    double currentPaceInSecPerKm,
  ) {
    if (userWeight <= 0 || distanceDeltaInMeters <= 0) return 0;

    final met = _getMET(currentPaceInSecPerKm);
    // 칼로리 소모 공식: MET * 체중(kg) * 시간(hour)
    // 여기서는 거리를 시간으로 변환하여 계산합니다.
    final hours =
        (distanceDeltaInMeters / 1000) / (3600 / currentPaceInSecPerKm);
    final calories = met * userWeight * hours;

    return calories;
  }

  // 최종 평균 페이스 계산 (초/km)
  double calculateAveragePace(double totalDistanceInMeters, int totalSeconds) {
    if (totalDistanceInMeters <= 0 || totalSeconds <= 0) return 0.0;
    return totalSeconds / (totalDistanceInMeters / 1000);
  }
}
