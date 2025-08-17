from pydantic import BaseModel, EmailStr
from datetime import datetime
import uuid
from typing import List, Optional
from .run import Run 

class UserBase(BaseModel):
    """
    사용자 스키마의 공통 속성을 정의하는 기본 클래스입니다.
    """
    email: EmailStr
    nickname: Optional[str] = None

class UserCreate(UserBase):
    """
    새로운 사용자를 생성할 때 사용할 스키마입니다.
    비밀번호 필드를 포함합니다.
    """
    password: str
    nickname: Optional[str] = None

class User(UserBase):
    """
    API 응답으로 사용자 정보를 반환할 때 사용할 스키마입니다.
    """
    id: uuid.UUID
    is_active: bool
    created_at: datetime
    runs: List[Run] = []

    class Config:
        from_attributes = True
        
class UserSocialLogin(BaseModel):
    social_id: str
    nickname: Optional[str] = None
    email: Optional[EmailStr] = None # 이메일은 선택적으로 받습니다.