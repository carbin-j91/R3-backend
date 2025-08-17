import uuid
from sqlalchemy import Column, String, Boolean, DateTime, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.session import Base

class Run(Base):
    """
    러닝 기록을 저장하는 'runs' 테이블의 SQLAlchemy 모델입니다.
    """
    __tablename__ = "runs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # User 모델과의 관계 설정 (Foreign Key)
    # 어느 유저의 기록인지 연결합니다.
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    distance = Column(Float, nullable=False) # 미터(m) 단위
    duration = Column(Float, nullable=False) # 초(s) 단위
    avg_pace = Column(Float, nullable=True) # 초/km 단위
    
    # 경로 좌표 데이터를 저장합니다. PostGIS의 Point 타입을 사용할 수도 있지만,
    # MVP 단계에서는 유연한 JSONB 타입을 사용하는 것이 간단합니다.
    # 예: [{"lat": 37.123, "lng": 127.123, "timestamp": "..."}]
    route = Column(JSONB, nullable=True)
    
    created_at = Column(DateTime, default=func.now())

    # User 모델과 Run 모델이 서로를 참조할 수 있도록 관계를 설정합니다.
    # 'runs'라는 이름으로 User 객체에서 이 기록들에 접근할 수 있습니다.
    owner = relationship("User", back_populates="runs")