# backend/alembic/env.py

import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine
from alembic import context
# ===== 우리 앱 설정/모델 =====
# .env 파일과 config.py를 통해 DB 연결 정보를 가져옵니다.
from app.core.config import settings
# 모든 모델이 Base에 등록되도록 Base를 임포트합니다.
from app.db.session import Base
# Alembic이 모델의 변경사항을 감지할 수 있도록 모든 모델을 명시적으로 임포트합니다.
from app.models.user import User
from app.models.run import Run
from app.models.album import Album
from app.models.course import Course, CourseAttempt
from app.models.post import Post, Comment, Reaction, PostImage, Report


# ===== Alembic 기본 설정 로딩 =====
config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 비동기 DB URL을 동기 URL로 변경하여 Alembic이 사용하도록 설정합니다.
# (예: postgresql+asyncpg://... -> postgresql://...)
ASYNC_DB_URL = settings.SQLALCHEMY_DATABASE_URI
SYNC_DB_URL = ASYNC_DB_URL.replace("+asyncpg", "")
config.set_main_option("sqlalchemy.url", SYNC_DB_URL)

target_metadata = Base.metadata

# ===== PostGIS 시스템 테이블/스키마 무시를 위한 필터 함수 =====
def include_object(object, name, type_, reflected, compare_to):
    """
    Alembic이 PostGIS 관련 테이블/뷰를 마이그레이션 대상에서 제외하도록 필터링합니다.
    """
    # 'tiger'나 'topology' 스키마에 속한 테이블은 무시합니다.
    schema = getattr(object, "schema", None)
    if type_ == "table" and schema in {"tiger", "topology"}:
        return False

    # PostGIS가 직접 관리하는 핵심 테이블들을 이름으로 무시합니다.
    pgis_names = {
        "geography_columns",
        "geometry_columns",
        "raster_columns",
        "raster_overviews",
        "spatial_ref_sys",
    }
    if name in pgis_names:
        return False

    # 그 외의 모든 객체는 마이그레이션 대상에 포함합니다.
    return True


# ===== Offline / Online 실행 루틴 =====
def run_migrations_offline() -> None:
    """
    DB에 연결하지 않고 SQL 스크립트만 생성하는 '오프라인' 모드.
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        include_object=include_object,  # 필터 함수 적용
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection) -> None:
    """
    실제 DB 연결을 사용하여 마이그레이션을 수행하는 함수.
    """
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        include_object=include_object,  # 필터 함수 적용
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    """
    Async 엔진을 생성하여 '온라인' 모드로 마이그레이션을 실행.
    """
    connectable = create_async_engine(
        ASYNC_DB_URL,
        poolclass=pool.NullPool,
    )
    try:
        async with connectable.connect() as connection:
            # 비동기 연결(connection)을 사용하여 동기 함수(do_run_migrations)를 실행
            await connection.run_sync(do_run_migrations)
    finally:
        # 엔진 리소스 정리
        await connectable.dispose()


# ===== Alembic 진입점 =====
if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())