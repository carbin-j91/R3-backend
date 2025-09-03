from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timedelta, date
from typing import List
import uuid

from app import models, schemas

async def get_user_stats(db: AsyncSession, user_id: uuid.UUID, period: str) -> schemas.StatsResponse:
    # 기간 설정
    end_date = datetime.utcnow()
    if period == "weekly":
        start_date = end_date - timedelta(days=7)
        group_by_format = func.to_char(models.Run.created_at, 'Dy') # 요일 (Mon, Tue)
    elif period == "monthly":
        start_date = end_date - timedelta(days=30)
        group_by_format = func.to_char(models.Run.created_at, 'MM-DD') # 날짜 (09-03)
    elif period == "yearly":
        start_date = end_date - timedelta(days=365)
        group_by_format = func.to_char(models.Run.created_at, 'YYYY-MM') # 연-월 (2025-09)
    else: # all
        start_date = datetime.min

    # 기본 통계 쿼리
    query = select(
        func.coalesce(func.sum(models.Run.distance), 0.0),
        func.count(models.Run.id),
        func.coalesce(func.sum(models.Run.duration), 0.0)
    ).where(
        models.Run.user_id == user_id,
        models.Run.created_at >= start_date if period != "all" else True
    )
    total_distance, total_runs, total_duration = (await db.execute(query)).first()

    # 평균 페이스 계산
    avg_pace = (total_duration / (total_distance / 1000)) if total_distance > 0 else 0.0

    # 차트 데이터 쿼리
    chart_query = select(
        group_by_format.label('label'),
        func.sum(models.Run.distance / 1000).label('value')
    ).where(
        models.Run.user_id == user_id,
        models.Run.created_at >= start_date if period != "all" else True
    ).group_by('label').order_by('label')
    
    chart_results = (await db.execute(chart_query)).all()
    chart_data = [schemas.BarChartData(label=row.label, value=row.value) for row in chart_results]

    return schemas.StatsResponse(
        total_distance_km=total_distance / 1000,
        total_runs=total_runs,
        total_duration_seconds=total_duration,
        avg_pace_per_km=avg_pace,
        chart_data=chart_data
    )