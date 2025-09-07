# backend/alembic/env.py

import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine

from alembic import context

# ===== 우리 앱 설정/모델 =====
from app.core.config import settings
from app.db.session import Base  # Base.metadata 가 모든 모델을 포함하도록 보장
# Alembic이 모델을 인식하도록 명시 임포트
from app.models.user import User
from app.models.run import Run
from app.models.album import Album

# ===== Alembic 기본 설정 로딩 =====
config = context.config

# .ini 파일의 로깅 설정 적용
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# offline 모드에서 사용할 sqlalchemy.url을 동기 드라이버로 세팅
# (예: postgresql+asyncpg -> postgresql)
ASYNC_DB_URL = settings.DATABASE_URL
SYNC_DB_URL = ASYNC_DB_URL.replace("+asyncpg", "")
config.set_main_option("sqlalchemy.url", SYNC_DB_URL)

# 마이그레이션 타겟 메타데이터
target_metadata = Base.metadata


# ===== PostGIS 시스템 테이블/스키마 무시 =====
def include_object(object, name, type_, reflected, compare_to):
    """
    Alembic이 PostGIS 관련 테이블/뷰를 마이그레이션 대상에서 제외하도록 필터링합니다.
    """
    # 스키마 기준 필터링 (예: tiger, topology)
    schema = getattr(object, "schema", None)
    if type_ == "table" and schema in {"tiger", "topology"}:
        return False

    # 테이블/뷰 이름 기준 필터링
    pgis_names = {
        "geography_columns",
        "geometry_columns",
        "raster_columns",
        "raster_overviews",
        "spatial_ref_sys",
    }
    if name in pgis_names:
        return False

    return True


# ===== Offline / Online 실행 루틴 =====
def run_migrations_offline() -> None:
    """
    DB 연결을 만들지 않고(오프라인) 마이그레이션 스크립트를 생성.
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,          # 컬럼 타입 변경도 비교
        include_object=include_object,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection) -> None:
    """
    실제 마이그레이션 실행(온라인). async 연결에서 sync 컨텍스트로 브릿지.
    """
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,          # 컬럼 타입 변경도 비교
        include_object=include_object,
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    """
    Async 엔진으로 온라인 마이그레이션 실행.
    """
    connectable = create_async_engine(
        ASYNC_DB_URL,
        poolclass=pool.NullPool,
    )
    try:
        async with connectable.connect() as connection:
            # async → sync 브릿지로 실제 마이그레이션 수행
            await connection.run_sync(do_run_migrations)
    finally:
        await connectable.dispose()


# ===== 진입점 =====
if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
