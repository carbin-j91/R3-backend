from pydantic import BaseModel

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