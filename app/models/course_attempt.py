import uuid
from sqlalchemy import Column, DateTime, Float, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.session import Base

class CourseAttempt(Base):
    """
    사용자의 '코스 도전' 기록을 저장하는 테이블의 SQLAlchemy 모델입니다.
    """
    __tablename__ = "course_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # User, Course, Run 모델과의 관계 설정
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    course_id = Column(UUID(as_uuid=True), ForeignKey("courses.id"), nullable=False)
    run_id = Column(UUID(as_uuid=True), ForeignKey("runs.id"), nullable=False, unique=True)

    # 유사도 계산 결과
    similarity_score = Column(Float, nullable=False)
    
    # 도전 성공 여부 (예: 점수가 80% 이상)
    is_successful = Column(Boolean, default=False)

    attempted_at = Column(DateTime, default=func.now())

    # 다른 모델과의 관계 설정
    user = relationship("User")
    course = relationship("Course")
    run = relationship("Run")