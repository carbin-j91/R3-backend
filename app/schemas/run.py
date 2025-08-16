from pydantic import BaseModel
from datetime import datetime
import uuid
from typing import List, Optional, Any

# Pydantic v2는 from_attributes = True를 사용합니다.
# from pydantic import ConfigDict

class RunBase(BaseModel):
    """
    Run 스키마의 공통 속성을 정의하는 기본 클래스입니다.
    """
    distance: float
    duration: float
    avg_pace: Optional[float] = None
    # route는 어떤 형태의 JSON이든 받을 수 있도록 Any 타입을 사용합니다.
    route: Optional[List[Any]] = None

class RunCreate(RunBase):
    """
    새로운 러닝 기록을 생성할 때 사용할 스키마입니다.
    """
    pass # RunBase와 동일한 필드를 사용합니다.

# ----> 아래 RunUpdate 스키마를 추가합니다. <----
class RunUpdate(BaseModel):
    """
    러닝 기록을 수정할 때 사용할 스키마입니다.
    모든 필드를 선택적으로(Optional) 만듭니다.
    """
    distance: Optional[float] = None
    duration: Optional[float] = None
    avg_pace: Optional[float] = None
    route: Optional[List[Any]] = None
    
class Run(RunBase):
    """
    API 응답으로 러닝 기록을 반환할 때 사용할 스키마입니다.
    """
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True # ORM 객체를 Pydantic 모델로 변환