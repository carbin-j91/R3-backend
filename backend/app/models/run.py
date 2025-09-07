import uuid
from sqlalchemy import Column, String, Boolean, DateTime, Float, ForeignKey, Integer, Text
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
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    distance = Column(Float, nullable=False) # 미터(m) 단위
    duration = Column(Float, nullable=False) # 초(s) 단위
    
    route = Column(JSONB, nullable=True)
    created_at = Column(DateTime, default=func.now())
    end_at = Column(DateTime, nullable=True)
    # ----> 아래 새로운 컬럼들을 추가합니다. <----
    
    calories_burned = Column(Float, nullable=True)
    avg_pace = Column(Float, nullable=True) # 초/km 단위
    avg_heart_rate = Column(Integer, nullable=True)
    avg_cadence = Column(Integer, nullable=True)
    total_elevation_gain = Column(Float, nullable=True)
    status = Column(String, default="finished", nullable=False)
    # 구간별 기록을 JSON 형태로 저장합니다.
    # 예: [{"split": 1, "pace": 330.5, "elevation": 10.2, ...}]
    splits = Column(JSONB, nullable=True)
    is_edited = Column(Boolean, default=False, nullable=False)
    chart_data = Column(JSONB, nullable=True)
    
    is_course_candidate = Column(Boolean, default=False, nullable=False)

    # 유저 관계
    owner = relationship("User", back_populates="runs", lazy="selectin")

    # ✅ 코스 생성 원본 런(1:1)
    created_course = relationship(
        "Course",
        back_populates="original_run",
        uselist=False,
        lazy="selectin",
    )

    # ✅ 코스 도전(1:1) – 한 Run은 하나의 CourseAttempt와만 매핑
    course_attempt = relationship(
        "CourseAttempt",
        back_populates="run",
        uselist=False,
        lazy="selectin",
    )