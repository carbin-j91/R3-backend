# R3_PROJECT/backend/app/core/config.py
import os

class Settings:
    """
    애플리케이션 전역 설정.
    기본값은 개발 편의용이며, 운영/개발 환경에서 반드시 환경변수로 덮어써서 사용하세요.
    """

    # --- DB / JWT ---
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://r3user:r3password@db:5432/r3db",
    )
    JWT_SECRET_KEY: str = os.getenv(
        "JWT_SECRET_KEY",
        "super-secret-key-that-is-very-long-and-secure",
    )
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080")
    )

    # --- Media / Storage (앨범 기능) ---
    # STORAGE_BACKEND=local | s3
    STORAGE_BACKEND: str = os.getenv("STORAGE_BACKEND", "local")
    # 컨테이너 내부 저장 경로(StaticFiles로 서빙할 실제 디렉토리)
    MEDIA_ROOT: str = os.getenv("MEDIA_ROOT", "/app/media")
    # 정적 서빙 URL 프리픽스(예: /media). FastAPI StaticFiles mount 시 사용
    MEDIA_URL: str = os.getenv("MEDIA_URL", "/media")

    # --- (선택) S3 설정: STORAGE_BACKEND=s3 일 때 사용 ---
    S3_BUCKET: str | None = os.getenv("S3_BUCKET")
    S3_REGION: str | None = os.getenv("S3_REGION")
    S3_ACCESS_KEY: str | None = os.getenv("S3_ACCESS_KEY")
    S3_SECRET_KEY: str | None = os.getenv("S3_SECRET_KEY")

    def __init__(self) -> None:
        # MEDIA_URL 정규화: 앞 슬래시 보장, 뒤 슬래시 제거
        if not self.MEDIA_URL.startswith("/"):
            self.MEDIA_URL = "/" + self.MEDIA_URL
        self.MEDIA_URL = self.MEDIA_URL.rstrip("/") or "/media"

settings = Settings()

# 일부 코드가 함수 스타일을 기대할 수 있어 호환용 제공
def get_settings() -> Settings:
    return settings
