from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
# ----> 1. options와 selectinload를 가져옵니다. <----
from sqlalchemy.orm import selectinload 
from typing import List, Optional # Optional도 추가합니다.
import uuid

from app import models, schemas
from app.core.security import get_password_hash

async def get_user_by_email(db: AsyncSession, email: str) -> Optional[models.User]:
    """
    이메일 주소로 사용자를 조회합니다. (runs 관계를 즉시 로딩)
    """
    # ----> 2. options(selectinload(...))를 추가하여 즉시 로딩을 적용합니다. <----
    query = select(models.User).options(selectinload(models.User.runs)).filter(models.User.email == email)
    result = await db.execute(query)
    return result.scalars().first()

async def create_user(db: AsyncSession, user: schemas.UserCreate) -> models.User:
    """
    해싱된 비밀번호로 데이터베이스에 새로운 사용자를 생성합니다.
    """
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        hashed_password=hashed_password
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    # 생성된 사용자를 다시 조회하여 'runs' 관계를 로드합니다.
    # 새로 생성된 사용자는 runs가 비어있지만, 이 과정을 통해 lazy loading 문제를 방지합니다.
    created_user = await get_user_by_email(db, email=db_user.email)
    return created_user

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