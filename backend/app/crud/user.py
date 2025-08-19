from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List, Optional
import uuid

from app import models, schemas
from app.core.security import get_password_hash

# ----> social_id로 사용자를 찾는 함수 추가 <----
async def get_user_by_social_id(db: AsyncSession, social_id: str) -> Optional[models.User]:
    query = select(models.User).options(selectinload(models.User.runs)).filter(models.User.social_id == social_id)
    result = await db.execute(query)
    return result.scalars().first()

# ----> 이메일로 사용자를 찾는 함수는 그대로 둡니다 <----
async def get_user_by_email(db: AsyncSession, email: str) -> Optional[models.User]:
    query = select(models.User).options(selectinload(models.User.runs)).filter(models.User.email == email)
    result = await db.execute(query)
    return result.scalars().first()

# ----> 소셜 유저를 찾거나, 없으면 새로 만드는 핵심 함수! <----
async def get_or_create_social_user(db: AsyncSession, user_in: schemas.UserSocialLogin) -> models.User:
    """
    소셜 ID로 사용자를 조회하고, 없으면 새로 생성합니다.
    """
    # 1. 소셜 ID로 기존 사용자가 있는지 확인
    user = await get_user_by_social_id(db, social_id=user_in.social_id)
    if user:
        return user

    # 2. 없으면 새로운 사용자 생성
    # 이메일은 필수가 아니므로, 카카오 회원번호를 기반으로 고유한 가상 이메일을 생성합니다.
    # 비밀번호는 소셜 로그인이므로, 강력한 임의의 값으로 채웁니다.
    random_password = uuid.uuid4().hex
    new_user_data = models.User(
        social_id=user_in.social_id,
        email=f"kakao_{user_in.social_id}@r3.app",
        nickname=user_in.nickname,
        hashed_password=get_password_hash(random_password)
    )
    db.add(new_user_data)
    await db.commit()
    await db.refresh(new_user_data)
    return new_user_data

# ----> 기존 create_user 함수는 혹시 모르니 그대로 둡니다 <----
async def create_user(db: AsyncSession, user: schemas.UserCreate) -> models.User:
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        nickname=user.nickname,
        hashed_password=hashed_password
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    created_user = await get_user_by_email(db, email=db_user.email)
    return created_user

async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> Optional[models.User]:
    """
    사용자 ID로 사용자를 조회합니다. (runs 관계를 즉시 로딩)
    """
    query = select(models.User).options(selectinload(models.User.runs)).filter(models.User.id == user_id)
    result = await db.execute(query)
    return result.scalars().first()