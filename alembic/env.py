import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine

from alembic import context

# 우리 앱의 모델과 설정을 가져옵니다.
# ---------------------------------------------------- #
from app.core.config import settings
from app.db.session import Base
from app.models.user import User # User 모델을 임포트해야 Alembic이 인식합니다.
# ---------------------------------------------------- #

config = context.config

# .ini 파일에서 로깅 설정을 읽어옵니다.
# ----> 아래 두 줄로 수정합니다. <----
if config.config_file_name is not None:
    fileConfig(config.config_file_name)


target_metadata = Base.metadata

def include_object(object, name, type_, reflected, compare_to):
    """
    Alembic이 PostGIS 관련 테이블들을 무시하도록 만드는 함수입니다.
    """
    if type_ == "table" and object.schema == "tiger":
        return False
    elif name in ["geography_columns", "geometry_columns", "raster_columns", "raster_overviews", "spatial_ref_sys"]:
        return False
    return True

def do_run_migrations(connection) -> None:
    # ----> 아래 `include_object=include_object` 옵션을 추가합니다. <----
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        include_object=include_object,
    )

    with context.begin_transaction():
        context.run_migrations()

async def run_migrations_online() -> None:
    connectable = create_async_engine(
        settings.DATABASE_URL,
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()

if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())