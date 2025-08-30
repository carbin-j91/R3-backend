from pydantic import BaseModel
from datetime import datetime
import uuid
from typing import List, Optional, Any

class RunBase(BaseModel):
    """
    Run 스키마의 공통 속성을 정의하는 기본 클래스입니다.
    """
    title: Optional[str] = None
    notes: Optional[str] = None
    distance: float
    duration: float
    route: Optional[List[Any]] = None
    
    # ----> 새로운 필드들을 추가합니다. <----
    calories_burned: Optional[float] = None
    avg_pace: Optional[float] = None
    avg_heart_rate: Optional[int] = None
    avg_cadence: Optional[int] = None
    total_elevation_gain: Optional[float] = None
    splits: Optional[List[Any]] = None


class RunCreate(BaseModel):
    """
    새로운 러닝 기록을 생성할 때 사용할 스키마입니다.
    """
    pass

class RunUpdate(BaseModel):
    # ----> RunUpdate 스키마를 수정합니다. <----
    # 이제 제목과 메모만 수정할 수 있도록 허용합니다.
    title: Optional[str] = None
    notes: Optional[str] = None

class Run(RunBase):
    """
    API 응답으로 러닝 기록을 반환할 때 사용할 스키마입니다.
    """
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True