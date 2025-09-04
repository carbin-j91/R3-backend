from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timedelta
from typing import List, Dict
import uuid
import calendar

from app import models, schemas

# 1. 요일 순서를 정렬하기 위한 헬퍼 딕셔너리
DAY_ORDER = {"월": 0, "화": 1, "수": 2, "목": 3, "금": 4, "토": 5, "일": 6}

async def get_user_stats(db: AsyncSession, user_id: uuid.UUID, period: str) -> schemas.StatsResponse:
    end_date = datetime.utcnow()
    chart_labels: List[str] = []
    
    # 2. 기간별로 완전한 X축 라벨 목록을 미리 생성합니다.
    if period == "weekly":
        # 이번 주의 월요일을 시작일로 설정
        start_date = end_date - timedelta(days=end_date.weekday())
        start_date = start_date.replace(hour=0, minute=0, second=0, microsecond=0)
        chart_labels = ["월", "화", "수", "목", "금", "토", "일"]
        # PostgreSQL의 요일 형식 ('Mon', 'Tue'...)
        group_by_format = func.to_char(models.Run.created_at, 'Dy')
    elif period == "monthly":
        first_day_of_month = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        start_date = first_day_of_month
        _, num_days = calendar.monthrange(end_date.year, end_date.month)
        chart_labels = [f"{i:02d}" for i in range(1, num_days + 1)] # '01', '02', ...
        group_by_format = func.to_char(models.Run.created_at, 'DD')
    elif period == "yearly":
        first_day_of_year = end_date.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        start_date = first_day_of_year
        chart_labels = [f"{i:02d}월" for i in range(1, 13)] # '01월', '02월', ...
        group_by_format = func.to_char(models.Run.created_at, 'MM"월"')
    else: # all
        start_date = datetime.min
        # '전체' 기간은 연도별로 그룹화합니다.
        group_by_format = func.to_char(models.Run.created_at, 'YYYY')

    # 기본 통계 쿼리
    base_query = select(
        func.coalesce(func.sum(models.Run.distance), 0.0),
        func.count(models.Run.id),
        func.coalesce(func.sum(models.Run.duration), 0.0)
    ).where(
        models.Run.user_id == user_id,
        models.Run.status == 'finished', # 완료된 러닝만 통계에 포함
        models.Run.created_at >= start_date if period != "all" else True
    )
    total_distance, total_runs, total_duration = (await db.execute(base_query)).first()
    avg_pace = (total_duration / (total_distance / 1000)) if total_distance > 0 else 0.0

    # 차트 데이터 쿼리
    chart_query = select(
        group_by_format.label('label'),
        func.sum(models.Run.distance / 1000).label('value')
    ).where(
        models.Run.user_id == user_id,
        models.Run.status == 'finished',
        models.Run.created_at >= start_date if period != "all" else True
    ).group_by('label').order_by('label')
    
    db_results = (await db.execute(chart_query)).all()
    
    # 3. DB 결과를 딕셔너리로 변환하여 쉽게 찾을 수 있도록 합니다.
    day_map = {"Mon": "월", "Tue": "화", "Wed": "수", "Thu": "목", "Fri": "금", "Sat": "토", "Sun": "일"}
    results_map: Dict[str, float] = {}
    for row in db_results:
        label = row.label.strip()
        if period == "weekly" and label in day_map:
            label = day_map[label]
        results_map[label] = float(row.value)

    # 4. 미리 생성된 라벨 목록을 기준으로 최종 차트 데이터를 만듭니다.
    if period != "all":
        chart_data_list = [
            schemas.BarChartData(label=label, value=results_map.get(label, 0.0))
            for label in chart_labels
        ]
        if period == "weekly":
            chart_data_list.sort(key=lambda x: DAY_ORDER[x.label])
    else: # '전체'는 DB 결과 그대로 사용
        chart_data_list = [schemas.BarChartData(label=label, value=value) for label, value in sorted(results_map.items())]

    return schemas.StatsResponse(
        total_distance_km=total_distance / 1000,
        total_runs=total_runs,
        total_duration_seconds=total_duration,
        avg_pace_per_km=avg_pace,
        chart_data=chart_data_list
    )