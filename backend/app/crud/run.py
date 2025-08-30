from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import uuid

from app import models, schemas

async def create_run(db: AsyncSession, user_id: uuid.UUID) -> models.Run:
    """
    'running' 상태의 비어있는 임시 러닝 기록을 생성합니다.
    """
    db_run = models.Run(user_id=user_id, status="running", distance=0, duration=0)
    db.add(db_run)
    await db.commit()
    await db.refresh(db_run)
    return db_run

async def get_runs_by_user(db: AsyncSession, user_id: uuid.UUID) -> List[models.Run]:
    """
    특정 사용자의 모든 러닝 기록을 조회합니다.
    """
    result = await db.execute(
        select(models.Run)
        .filter(models.Run.user_id == user_id)
        .order_by(models.Run.created_at.desc())
    )
    return result.scalars().all()


async def get_run(db: AsyncSession, id: uuid.UUID, user_id: uuid.UUID) -> models.Run | None:
    """
    특정 ID의 러닝 기록을 조회합니다.
    다른 사용자의 기록을 볼 수 없도록 user_id도 함께 검사합니다.
    """
    result = await db.execute(
        select(models.Run)
        .filter(models.Run.id == id, models.Run.user_id == user_id)
    )
    return result.scalars().first()

async def update_run(db: AsyncSession, db_run: models.Run, run_in: schemas.RunUpdate) -> models.Run:
    """
    기존 러닝 기록을 업데이트합니다. (중간 저장 및 최종 저장에 사용)
    """
    update_data = run_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_run, key, value)
    db.add(db_run)
    await db.commit()
    await db.refresh(db_run)
    return db_run

async def delete_run(db: AsyncSession, db_run: models.Run):
    """
    러닝 기록을 삭제합니다.
    """
    await db.delete(db_run)
    await db.commit()
    return db_run
