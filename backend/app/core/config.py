# app/core/config.py
from typing import Optional, Dict, Any, List
from pydantic import validator
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # 이 클래스는 .env 파일의 변수들을 자동으로 읽어와 타입 검증까지 수행합니다.
    
    # API
    API_V1_STR: str = "/api/v1"

    # JWT / Auth
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int

    # POSTGRES ( .env 파일에서 직접 읽어옴 )
    POSTGRES_SERVER: str
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    
    # 위 변수들을 조합하여 최종 DATABASE URI를 동적으로 생성
    SQLALCHEMY_DATABASE_URI: Optional[str] = None

    @validator("SQLALCHEMY_DATABASE_URI", pre=True)
    def assemble_db_connection(cls, v: Optional[str], values: Dict[str, Any]) -> Any:
        if isinstance(v, str):
            return v
        return (
            f"postgresql+asyncpg://"
            f"{values.get('POSTGRES_USER')}:{values.get('POSTGRES_PASSWORD')}"
            f"@{values.get('POSTGRES_SERVER')}/{values.get('POSTGRES_DB')}"
        )

    # Media / Storage
    MEDIA_ROOT: str = "/app/media"
    MEDIA_URL: str = "/media"

    class Config:
        case_sensitive = True
        # .env 파일의 위치를 명시
        env_file = ".env"

settings = Settings()