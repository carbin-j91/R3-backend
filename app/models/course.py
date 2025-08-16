import uuid
from sqlalchemy import Column, String, Text, DateTime, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.session import Base

class Course(Base):
    """
    사용자가 생성한 '코스' 정보를 저장하는 테이블의 SQLAlchemy 모델입니다.
    """
    __tablename__ = "courses"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)

    # User 모델과의 관계 설정
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    # 코스의 원본이 된 Run 기록의 ID (선택사항)
    original_run_id = Column(UUID(as_uuid=True), ForeignKey("runs.id"), nullable=True)

    distance = Column(Float, nullable=False) # 미터(m) 단위
    duration = Column(Float, nullable=False) # 초(s) 단위
    
    # 코스 경로 데이터
    route = Column(JSONB, nullable=True)

    created_at = Column(DateTime, default=func.now())

    # User 모델과의 관계 설정
    creator = relationship("User")