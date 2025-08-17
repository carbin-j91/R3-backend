from pydantic import BaseModel
from datetime import datetime
import uuid
from typing import List, Optional, Any

class CourseBase(BaseModel):
    name: str
    description: Optional[str] = None
    distance: float
    duration: float
    route: Optional[List[Any]] = None

class CourseCreate(CourseBase):
    # 이 스키마는 러닝 기록(Run)에서 코스를 생성할 때 사용됩니다.
    # original_run_id는 API 경로에서 직접 받으므로 여기에는 포함하지 않습니다.
    pass

class CourseUpdate(BaseModel):
    """
    코스를 수정할 때 사용할 스키마입니다.
    이름과 설명만 수정 가능하도록 허용합니다.
    """
    name: Optional[str] = None
    description: Optional[str] = None

class Course(CourseBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True

class CourseCreateFromRun(BaseModel):
    """
    Run 기록으로 코스를 생성할 때 사용할 스키마입니다.
    이름과 설명만 받습니다.
    """
    name: str
    description: Optional[str] = None