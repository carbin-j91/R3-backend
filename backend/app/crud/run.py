# app/crud/run.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import uuid

from app import models, schemas

async def create_run(db: AsyncSession, user_id: uuid.UUID) -> models.Run:
    """
    'running' 상태의 비어있는 임시 러닝 기록을 생성합니다.
    (기존 사용처가 있으면 계속 사용 가능)
    """
    db_run = models.Run(
        user_id=user_id,
        status="running",
        distance=0,
        duration=0,
        # 기본값 유지
        is_course_candidate=False,
    )
    db.add(db_run)
    await db.commit()
    await db.refresh(db_run)
    return db_run


# ✅ 신규 함수: 요청 본문(run_in)에서 is_course_candidate를 받아 반영
async def create_run_with_owner(
    db: AsyncSession,
    *,
    run_in: schemas.RunCreate,
    user_id: uuid.UUID,
) -> models.Run:
    """
    'running' 상태의 임시 러닝 기록을 생성합니다.
    클라이언트에서 보낸 is_course_candidate 값을 반영합니다.
    """
    db_run = models.Run(
        user_id=user_id,
        status="running",
        distance=0,
        duration=0,
        is_course_candidate=bool(run_in.is_course_candidate),
    )
    db.add(db_run)
    await db.commit()
    await db.refresh(db_run)
    return db_run


async def get_runs_by_user(db: AsyncSession, user_id: uuid.UUID) -> List[models.Run]:
    result = await db.execute(
        select(models.Run)
        .filter(models.Run.user_id == user_id)
        .order_by(models.Run.created_at.desc())
    )
    return result.scalars().all()


async def get_run(db: AsyncSession, id: uuid.UUID, user_id: uuid.UUID) -> models.Run | None:
    result = await db.execute(
        select(models.Run)
        .filter(models.Run.id == id, models.Run.user_id == user_id)
    )
    return result.scalars().first()


async def update_run(db: AsyncSession, db_run: models.Run, run_in: schemas.RunUpdate) -> models.Run:
    update_data = run_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_run, key, value)
    db.add(db_run)
    await db.commit()
    await db.refresh(db_run)
    return db_run


async def delete_run(db: AsyncSession, db_run: models.Run):
    await db.delete(db_run)
    await db.commit()
    return db_run
