from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import uuid
from sqlalchemy.orm import selectinload

from app import models, schemas

async def create_course_attempt(db: AsyncSession, *, run_id: uuid.UUID, course_id: uuid.UUID, user_id: uuid.UUID, score: float) -> models.CourseAttempt:
    """
    새로운 코스 도전 기록을 데이터베이스에 생성합니다.
    """
    # MVP에서는 80% (0.8) 이상을 성공으로 간주합니다.
    is_successful = score >= 0.8

    db_attempt = models.CourseAttempt(
        run_id=run_id,
        course_id=course_id,
        user_id=user_id,
        similarity_score=score,
        is_successful=is_successful
    )
    db.add(db_attempt)
    await db.commit()
    await db.refresh(db_attempt)
    return db_attempt

async def get_attempt_by_run_id(db: AsyncSession, run_id: uuid.UUID) -> models.CourseAttempt | None:
    """
    Run ID로 기존 도전 기록이 있는지 확인합니다 (중복 제출 방지용).
    """
    result = await db.execute(
        select(models.CourseAttempt).filter(models.CourseAttempt.run_id == run_id)
    )
    return result.scalars().first()

async def get_course_ranking(db: AsyncSession, course_id: uuid.UUID, limit: int = 10) -> List[models.CourseAttempt]:
    """
    특정 코스의 랭킹을 조회합니다 (성공한 도전 기록 중 소요 시간이 가장 짧은 순).
    """
    result = await db.execute(
        select(models.CourseAttempt)
        .options(selectinload(models.CourseAttempt.user)) # 사용자 정보도 함께 로드
        .filter(models.CourseAttempt.course_id == course_id, models.CourseAttempt.is_successful == True)
        .join(models.Run) # Run 모델과 조인하여 duration을 기준으로 정렬
        .order_by(models.Run.duration.asc())
        .limit(limit)
    )
    return result.scalars().all()