from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List
import uuid

from app import models, schemas

async def create_post(db: AsyncSession, post: schemas.PostCreate, user_id: uuid.UUID) -> models.Post:
    """
    특정 사용자를 위해 새로운 게시글을 데이터베이스에 생성합니다.
    """
    db_post = models.Post(**post.model_dump(), user_id=user_id)
    db.add(db_post)
    await db.commit()
    await db.refresh(db_post)
    # author 정보를 로드하기 위해 다시 조회합니다.
    result = await db.execute(
        select(models.Post).options(selectinload(models.Post.author)).filter(models.Post.id == db_post.id)
    )
    return result.scalars().first()

async def get_posts(db: AsyncSession, skip: int = 0, limit: int = 100) -> List[models.Post]:
    """
    전체 게시글 목록을 조회합니다 (페이지네이션 적용).
    작성자 정보(author)도 함께 로드합니다.
    """
    result = await db.execute(
        select(models.Post)
        .options(selectinload(models.Post.author))
        .order_by(models.Post.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()