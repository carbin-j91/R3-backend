from pydantic import BaseModel
from typing import Optional

class Token(BaseModel):
    """
    로그인 API의 응답으로 사용할 토큰 스키마입니다.
    """
    access_token: str
    token_type: str

class TokenData(BaseModel):
    """
    JWT 토큰 안에 담길 데이터(payload)의 형식을 정의합니다.
    """
    email: str | None = None
    
class TokenPayload(BaseModel):
    """
    JWT 토큰의 payload(내용)에 대한 스키마
    'sub' (subject) 필드에 사용자 ID가 담깁니다.
    """
    sub: Optional[str] = None