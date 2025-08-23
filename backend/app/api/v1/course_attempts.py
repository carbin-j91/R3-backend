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
    """
    course = await crud.course.get_course_by_id_for_attempt(db=db, id=course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")

    existing_attempt = await crud.course_attempt.get_attempt_by_run_id(db=db, run_id=run.id)
    if existing_attempt:
        raise HTTPException(status_code=400, detail="This run has already been submitted.")
        
    score = calculate_similarity_score(original_route=course.route, user_route=run.route)

    attempt = await crud.course_attempt.create_course_attempt(
        db=db, run_id=run.id, course_id=course.id, user_id=current_user.id, score=score
    )
    return attempt