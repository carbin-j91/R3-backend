from pydantic import BaseModel
from datetime import datetime
import uuid

class CourseAttemptBase(BaseModel):
    similarity_score: float
    is_successful: bool

class CourseAttemptCreate(CourseAttemptBase):
    # 생성 시에는 점수와 성공 여부만 필요합니다.
    pass

class CourseAttempt(CourseAttemptBase):
    id: uuid.UUID
    user_id: uuid.UUID
    course_id: uuid.UUID
    run_id: uuid.UUID
    attempted_at: datetime

    class Config:
        from_attributes = True