from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_
from typing import List
import uuid

from app import models, schemas

async def create_course_from_run(db: AsyncSession, course_in: schemas.CourseCreate, run: models.Run, user_id: uuid.UUID) -> models.Course:
    """
    기존 러닝 기록(Run)을 바탕으로 새로운 코스(Course)를 생성합니다.
    """
    db_course = models.Course(
        name=course_in.name,
        description=course_in.description,
        distance=run.distance,
        duration=run.duration,
        route=run.route,
        original_run_id=run.id,
        user_id=user_id
    )
    db.add(db_course)
    await db.commit()
    await db.refresh(db_course)
    return db_course

async def get_courses_by_user(db: AsyncSession, user_id: uuid.UUID) -> List[models.Course]:
    """
    특정 사용자가 생성한 모든 코스 목록을 조회합니다.
    """
    result = await db.execute(
        select(models.Course)
        .filter(models.Course.user_id == user_id)
        .order_by(models.Course.created_at.desc())
    )
    return result.scalars().all()


async def get_course(db: AsyncSession, id: uuid.UUID, user_id: uuid.UUID) -> models.Course | None:
    """
    특정 ID의 코스를 조회합니다.
    다른 사용자의 코스를 볼 수 없도록 user_id도 함께 검사합니다.
    """
    result = await db.execute(
        select(models.Course)
        .filter(models.Course.id == id, models.Course.user_id == user_id)
    )
    return result.scalars().first()

async def update_course(db: AsyncSession, db_course: models.Course, course_in: schemas.CourseUpdate) -> models.Course:
    """
    코스를 수정합니다.
    """
    data = course_in.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(db_course, k, v)
    await db.commit()
    await db.refresh(db_course)
    return db_course

async def delete_course(db: AsyncSession, db_course: models.Course):
    """
    코스를 삭제합니다.
    """
    await db.delete(db_course)
    await db.commit()
    return db_course

async def search_courses(db: AsyncSession, query: str) -> List[models.Course]:
    """
    쿼리 문자열로 코스 이름 또는 설명을 검색합니다 (대소문자 무시).
    """
    # ilike는 대소문자를 구분하지 않는 'like' 검색을 지원합니다.
    search_query = f"%{query}%"
    result = await db.execute(
        select(models.Course)
        .filter(
            or_(
                models.Course.name.ilike(search_query),
                models.Course.description.ilike(search_query)
            )
        )
        .order_by(models.Course.created_at.desc())
    )
    return result.scalars().all()

# ----> 아래 함수를 추가합니다. <----
async def get_course_by_id_for_attempt(db: AsyncSession, id: uuid.UUID) -> models.Course | None:
    """
    ID로 코스를 조회합니다 (사용자 검증 없음).
    """
    result = await db.execute(
        select(models.Course).filter(models.Course.id == id)
    )
    return result.scalars().first()

async def get_course(db: AsyncSession, id: uuid.UUID, user_id: uuid.UUID) -> models.Course | None:
    """
    특정 ID의 코스를 조회합니다.
    다른 사용자의 코스를 볼 수 없도록 user_id도 함께 검사합니다.
    """
    result = await db.execute(
        select(models.Course)
        .filter(models.Course.id == id, models.Course.user_id == user_id)
    )
    return result.scalars().first()

async def update_course(db: AsyncSession, db_course: models.Course, course_in: schemas.CourseUpdate) -> models.Course:
    """
    코스를 수정합니다.
    """
    update_data = course_in.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        setattr(db_course, key, value)
        
    db.add(db_course)
    await db.commit()
    await db.refresh(db_course)
    return db_course

async def delete_course(db: AsyncSession, db_course: models.Course):
    """
    코스를 삭제합니다.
    """
    await db.delete(db_course)
    await db.commit()
    return db_course