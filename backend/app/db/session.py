# app/db/session.py

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base

from app.core.config import settings

# 💡 settings.DATABASE_URL -> settings.SQLALCHEMY_DATABASE_URI 로 수정
engine = create_async_engine(settings.SQLALCHEMY_DATABASE_URI, pool_pre_ping=True)
SessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine, 
    class_=AsyncSession
)

Base = declarative_base()

# DB 세션을 가져오는 Dependency (API에서 사용)
async def get_db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session