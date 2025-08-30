import os
from datetime import timedelta

class Settings:
    """
    애플리케이션의 설정을 관리하는 클래스입니다.
    환경 변수에서 설정 값을 가져옵니다.
    """
    # 데이터베이스 연결 URL
    # docker-compose.yml에서 설정한 환경 변수를 가져옵니다.
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://r3user:r3password@db:5432/r3db")

    # JWT를 생성하고 검증하는 데 사용되는 비밀 키입니다.
    # 이 값은 절대 외부에 노출되어서는 안 됩니다.
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "super-secret-key-that-is-very-long-and-secure")
    
    # 토큰에 사용할 암호화 알고리즘입니다.
    JWT_ALGORITHM: str = "HS256"

    # 액세스 토큰의 만료 시간을 설정합니다. (예: 30분)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080

# 설정 클래스의 인스턴스를 생성하여 다른 파일에서 쉽게 가져다 쓸 수 있도록 합니다.
settings = Settings()