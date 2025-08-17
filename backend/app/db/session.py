from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

from app.core.config import settings

# 비동기 데이터베이스 엔진을 생성합니다.
# SQLAlchemy 2.0부터는 비동기(asyncio)를 정식으로 지원하여 성능을 높일 수 있습니다.
engine = create_async_engine(settings.DATABASE_URL, echo=True)

# 데이터베이스 세션을 생성하는 세션 메이커를 설정합니다.
# autocommit=False: 커밋을 자동으로 하지 않음 (명시적 커밋 필요)
# autoflush=False: 데이터를 자동으로 flush 하지 않음
AsyncSessionLocal = async_sessionmaker(autocommit=False, autoflush=False, bind=engine)

# SQLAlchemy 모델의 베이스 클래스를 생성합니다.
# 앞으로 만들 모든 데이터베이스 모델(테이블)은 이 Base 클래스를 상속받게 됩니다.
Base = declarative_base()