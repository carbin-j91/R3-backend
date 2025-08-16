import math
from typing import List, Dict, Any

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    두 GPS 좌표 사이의 거리를 미터(m) 단위로 계산합니다 (Haversine 공식).
    """
    R = 6371e3  # 지구의 반지름 (미터)
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2) * math.sin(delta_phi / 2) + \
        math.cos(phi1) * math.cos(phi2) * \
        math.sin(delta_lambda / 2) * math.sin(delta_lambda / 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c

def calculate_similarity_score(original_route: List[Dict[str, Any]], user_route: List[Dict[str, Any]]) -> float:
    """
    V1: 간단한 경로 유사도 계산 알고리즘
    - 각 사용자 경로 점이 원본 경로에서 얼마나 벗어났는지 평균 거리를 계산합니다.
    - 평균 이탈 거리가 적을수록 높은 점수를 부여합니다.
    """
    if not original_route or not user_route:
        return 0.0

    total_deviation = 0.0
    for user_point in user_route:
        # 사용자의 각 지점에서 원본 경로까지의 가장 짧은 거리를 찾습니다.
        min_dist_to_original = min(
            haversine_distance(
                user_point['lat'], user_point['lng'],
                orig_point['lat'], orig_point['lng']
            ) for orig_point in original_route
        )
        total_deviation += min_dist_to_original
    
    # 사용자 경로의 모든 점들에 대한 평균 이탈 거리
    average_deviation = total_deviation / len(user_route)

    # 점수화: 평균 이탈 거리가 50m 이상이면 0점, 0m이면 1.0점으로 계산합니다.
    # (이 로직은 나중에 더 정교하게 개선될 수 있습니다.)
    score = max(0.0, 1.0 - (average_deviation / 50.0))
    
    return score