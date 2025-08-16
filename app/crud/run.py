from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import uuid

from app import models, schemas

async def create_run(db: AsyncSession, run: schemas.RunCreate, user_id: uuid.UUID) -> models.Run:
    """
    특정 사용자를 위해 새로운 러닝 기록을 데이터베이스에 생성합니다.
    """
    db_run = models.Run(**run.model_dump(), user_id=user_id)
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
    러닝 기록을 수정합니다.
    """
    # run_in 스키마에서 받은 데이터 중, 값이 설정된(None이 아닌) 필드만 가져옵니다.
    update_data = run_in.model_dump(exclude_unset=True)
    
    # db_run 객체의 필드를 새로운 값으로 업데이트합니다.
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
