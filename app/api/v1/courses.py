from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from app import crud, models, schemas
from app.api.v1 import deps

router = APIRouter()

@router.post("/runs/{run_id}/courses/", response_model=schemas.Course)
async def create_course(
    *,
    db: AsyncSession = Depends(deps.get_db),
    run_id: uuid.UUID,
    course_in: schemas.CourseCreateFromRun,
    current_user: models.User = Depends(deps.get_current_user)
):
    """
    특정 러닝 기록(Run)으로부터 새로운 코스를 생성합니다.
    """
    # 먼저, 해당 run 기록이 현재 사용자의 것인지 확인합니다.
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")

    course = await crud.course.create_course_from_run(
        db=db, course_in=course_in, run=run, user_id=current_user.id
    )
    return course

@router.get("/search/", response_model=List[schemas.Course])
async def search_for_courses(
    query: str,
    db: AsyncSession = Depends(deps.get_db),
):
    """
    쿼리로 코스를 검색합니다.
    """
    courses = await crud.course.search_courses(db=db, query=query)
    return courses

@router.get("/", response_model=List[schemas.Course])
async def read_courses(
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    현재 로그인된 사용자가 생성한 모든 코스 목록을 반환합니다.
    """
    courses = await crud.course.get_courses_by_user(db=db, user_id=current_user.id)
    return courses

@router.get("/{course_id}", response_model=schemas.Course)
async def read_course(
    course_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    ID로 특정 코스를 조회합니다.
    """
    course = await crud.course.get_course(db=db, id=course_id, user_id=current_user.id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course

@router.patch("/{course_id}", response_model=schemas.Course)
async def update_course(
    course_id: uuid.UUID,
    course_in: schemas.CourseUpdate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    ID로 특정 코스를 수정합니다.
    """
    course = await crud.course.get_course(db=db, id=course_id, user_id=current_user.id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    course = await crud.course.update_course(db=db, db_course=course, course_in=course_in)
    return course

@router.delete("/{course_id}", response_model=schemas.Course)
async def delete_course(
    course_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    ID로 특정 코스를 삭제합니다.
    """
    course = await crud.course.get_course(db=db, id=course_id, user_id=current_user.id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    await crud.course.delete_course(db=db, db_course=course)
    return course

@router.get("/{course_id}/ranking", response_model=List[schemas.CourseAttempt])
async def read_course_ranking(
    course_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
):
    """
    특정 코스의 랭킹을 조회합니다.
    """
    ranking = await crud.course_attempt.get_course_ranking(db=db, course_id=course_id)
    return ranking