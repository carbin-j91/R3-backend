from pydantic import BaseModel, EmailStr
from datetime import datetime
import uuid

# Pydantic V2부터는 orm_mode=True 대신 from_attributes=True를 사용합니다.
# from pydantic import ConfigDict

class UserBase(BaseModel):
    """
    사용자 스키마의 공통 속성을 정의하는 기본 클래스입니다.
    """
    email: EmailStr

class UserCreate(UserBase):
    """
    새로운 사용자를 생성할 때 사용할 스키마입니다.
    비밀번호 필드를 포함합니다.
    """
    password: str

class User(UserBase):
    """
    API 응답으로 사용자 정보를 반환할 때 사용할 스키마입니다.
    비밀번호 같은 민감한 정보는 제외됩니다.
    """
    id: uuid.UUID
    is_active: bool
    created_at: datetime

    # SQLAlchemy 모델과 같은 ORM 객체를 Pydantic 모델로 변환할 수 있도록 설정합니다.
    class Config:
        from_attributes = True # Pydantic V2
        # orm_mode = True # Pydantic V1