from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from app import crud, models, schemas
from app.api.v1 import deps
from app.core.similarity import calculate_similarity_score

router = APIRouter()

@router.post("/courses/{course_id}/runs/{run_id}", response_model=schemas.CourseAttempt)
async def create_course_attempt(
    *,
    db: AsyncSession = Depends(deps.get_db),
    course_id: uuid.UUID,
    run_id: uuid.UUID,
    current_user: models.User = Depends(deps.get_current_user)
):
    """
    자신의 러닝 기록(Run)을 특정 코스(Course)에 대한 도전 결과로 제출합니다.
    서버는 두 경로의 유사도를 계산하여 결과를 저장하고 반환합니다.
    """
    # 1. 코스가 존재하는지 확인
    course = await crud.course.get_course(db=db, id=course_id, user_id=current_user.id) # user_id는 임시. 나중엔 다른 사람 코스도 도전 가능해야 함
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    # 2. 러닝 기록이 현재 사용자의 것인지 확인
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")

    # 3. 이미 이 기록으로 도전을 제출했는지 확인 (중복 방지)
    existing_attempt = await crud.course_attempt.get_attempt_by_run_id(db=db, run_id=run.id)
    if existing_attempt:
        raise HTTPException(status_code=400, detail="This run has already been submitted as a course attempt.")
        
    # 4. 유사도 계산
    score = calculate_similarity_score(original_route=course.route, user_route=run.route)

    # 5. 도전 기록 생성
    attempt = await crud.course_attempt.create_course_attempt(
        db=db, run_id=run.id, course_id=course.id, user_id=current_user.id, score=score
    )

    return attempt