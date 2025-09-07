# app/schemas/course.py
from pydantic import BaseModel, Field
from typing import Optional, List, Any
import uuid
from datetime import datetime

# ── Course ───────────────────────────────────────────────────────────
class CourseBase(BaseModel):
    name: str
    description: Optional[str] = None

class CourseCreate(CourseBase):
    # 생성에 필요한 필수값 명시(거리/경로; user_id는 서버에서 현재 유저로 세팅)
    distance: float
    route: Optional[List[Any]] = None
    rally_points: Optional[List[Any]] = None
    visibility: Optional[str] = "private"

class CourseUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    distance: Optional[float] = None
    route: Optional[List[Any]] = None
    rally_points: Optional[List[Any]] = None
    status: Optional[str] = None        # draft/published/archived
    visibility: Optional[str] = None    # private/public/unlisted
    
class Course(CourseBase):
    id: uuid.UUID
    user_id: uuid.UUID
    distance: float
    route: Optional[List[Any]] = None
    rally_points: Optional[List[Any]] = None
    status: str
    visibility: str
    created_at: datetime

    class Config:
        from_attributes = True

# ── CourseAttempt ───────────────────────────────────────────────────
class CourseAttemptBase(BaseModel):
    # 생성 시에는 서버가 계산하므로 선택/생략 가능으로 둡니다.
    similarity_score: Optional[float] = None
    is_successful: Optional[bool] = None

class CourseAttemptCreate(BaseModel):
    # 경로: POST /courses/{course_id}/attempts  → body엔 run_id만 오면 충분
    run_id: uuid.UUID

class CourseAttempt(CourseAttemptBase):
    id: uuid.UUID
    user_id: uuid.UUID
    course_id: uuid.UUID
    attempted_at: datetime

    class Config:
        from_attributes = True

# ✅ 추가: 러닝 기록으로부터 코스를 만드는 전용 입력 폼
# - distance/route는 서버가 run_id로부터 계산하므로 여기엔 없음
# - 이름/설명/공개범위 + 정규화 옵션 정도만 받으면 충분
class CourseCreateFromRun(BaseModel):
    name: str = Field(..., description="코스 이름")
    description: Optional[str] = Field(None, description="코스 설명")
    visibility: Optional[str] = Field("private", description="private/public/unlisted")
    # 선택적 파이프라인 옵션(서비스 코드에서 사용 안 하면 무시해도 됨)
    simplify: Optional[bool] = Field(True, description="경로 단순화(RDP) 적용 여부")
    simplify_tolerance_m: Optional[float] = Field(5.0, description="RDP 허용 오차(m)")
    generate_rally_points: Optional[bool] = Field(False, description="랠리 포인트 자동 생성 여부")