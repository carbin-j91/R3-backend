from pydantic import BaseModel
from typing import List

# 막대 차트의 각 막대를 표현하는 스키마
class BarChartData(BaseModel):
    label: str  # x축 라벨 (예: '월', '01일')
    value: float # y축 값 (예: 총 거리)

# 최종 통계 응답 스키마
class StatsResponse(BaseModel):
    total_distance_km: float
    total_runs: int
    avg_pace_per_km: float # 초/km 단위
    total_duration_seconds: float
    chart_data: List[BarChartData]