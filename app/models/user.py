import uuid
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.session import Base

class User(Base):
    """
    사용자 정보를 저장하는 'users' 테이블의 SQLAlchemy 모델입니다.
    """
    # __tablename__은 SQLAlchemy에게 이 모델이 어떤 테이블과 매핑되는지 알려줍니다.
    __tablename__ = "users"
    is_active = Column(Boolean(), default=True)
    created_at = Column(DateTime, default=func.now())
    # ----> 2. 아래 관계 설정을 추가합니다. <----
    # 이 사용자가 작성한 모든 러닝 기록에 접근할 수 있습니다.
    runs = relationship("Run", back_populates="owner")
    # 기본 키(Primary Key)로 UUID를 사용합니다.
    # UUID는 추측이 불가능하여 id를 통한 직접적인 객체 접근(예: /users/1)을 방지해 보안에 유리합니다.
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    email = Column(String, unique=True, index=True, nullable=False)
    nickname = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean(), default=True)

    # default=func.now()는 데이터베이스 서버의 현재 시간을 기본값으로 사용하도록 합니다.
    created_at = Column(DateTime, default=func.now())