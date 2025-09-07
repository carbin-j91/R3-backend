# app/models/course.py
import uuid
from typing import TYPE_CHECKING
from sqlalchemy import Column, String, Boolean, DateTime, Float, ForeignKey, Text, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

if TYPE_CHECKING:
    from .run import Run
    from .user import User

class Course(Base):
    __tablename__ = "courses"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    original_run_id = Column(UUID(as_uuid=True), ForeignKey("runs.id"), nullable=True)

    distance = Column(Float, nullable=False)  # meters
    route = Column(JSONB, nullable=True)      # 초기엔 JSONB 유지(추후 PostGIS로 이관)
    rally_points = Column(JSONB, nullable=True)

    status = Column(String, default="draft", nullable=False)       # draft/published/archived
    visibility = Column(String, default="private", nullable=False) # private/public/unlisted

    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    # 관계
    owner = relationship("User", lazy="selectin")
    # ✅ 오타 수정: back_populates
    # ✅ Run과의 역방향 관계 이름이 created_course여야 함
    original_run = relationship(
        "Run",
        back_populates="created_course",
        lazy="selectin",
    )

    attempts = relationship(
        "CourseAttempt",
        back_populates="course",
        lazy="selectin",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        # 같은 사용자가 같은 이름으로 중복 코스 생성 방지(선택)
        UniqueConstraint('user_id', 'name', name='uq_courses_user_name'),
        Index('ix_courses_status', 'status'),
        Index('ix_courses_visibility', 'visibility'),
    )


class CourseAttempt(Base):
    __tablename__ = "course_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    course_id = Column(UUID(as_uuid=True), ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    run_id = Column(UUID(as_uuid=True), ForeignKey("runs.id"), unique=True, nullable=False)

    # 서버가 계산하여 기록(생성 시 필수 X)
    similarity_score = Column(Float, nullable=True)
    is_successful = Column(Boolean, default=False, nullable=False)

    attempted_at = Column(DateTime, server_default=func.now(), nullable=False)

    # 관계
    user = relationship("User", lazy="selectin")
    course = relationship("Course", back_populates="attempts", lazy="selectin")
    run = relationship("Run", back_populates="course_attempt", lazy="selectin")
