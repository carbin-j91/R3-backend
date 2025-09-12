# app/models/post.py
import uuid
from sqlalchemy import (
    Column, String, Text, DateTime, ForeignKey, Enum, UniqueConstraint, Integer, Boolean, Float
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.session import Base # DB Base 클래스 임포트 경로 확인

class Post(Base):
    __tablename__ = "posts"

    # 기본 정보
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, index=True, nullable=False)
    category = Column(String, nullable=False, index=True)

    # 콘텐츠 (원본 JSON, 렌더링용 HTML, 검색용 TEXT)
    content_json = Column(JSONB, nullable=False)
    content_html = Column(Text, nullable=False)
    content_text = Column(Text, nullable=False)

    # 메타 정보
    cover_image_url = Column(String, nullable=True)
    region = Column(String, nullable=True, index=True)
    age_group = Column(String, nullable=True, index=True)

    # 추천 시스템용
    is_hot = Column(Boolean, default=False, index=True)
    hot_score = Column(Float, default=0.0, index=True)

    # 타임스탬프
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 관계 설정
    author = relationship("User")
    images = relationship("PostImage", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    reactions = relationship("Reaction", back_populates="post", cascade="all, delete-orphan")


class Comment(Base):
    __tablename__ = "comments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    body = Column(Text, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 관계 설정
    author = relationship("User")
    post = relationship("Post", back_populates="comments")


# Enum: 반응 종류를 미리 정의하여 데이터 일관성 확보
ReactionType = Enum("like", "bookmark", name="reaction_type_enum", create_type=False)

class Reaction(Base):
    __tablename__ = "reactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    reaction_type = Column(ReactionType, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 한 명의 유저가 한 게시물에 같은 종류의 반응을 한 번만 할 수 있도록 제약
    __table_args__ = (
        UniqueConstraint("post_id", "user_id", "reaction_type", name="user_post_reaction_uc"),
    )

    # 관계 설정
    user = relationship("User")
    post = relationship("Post", back_populates="reactions")


class PostImage(Base):
    __tablename__ = "post_images"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    url = Column(String, nullable=False)
    width = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)
    order = Column(Integer, default=0, nullable=False)

    post = relationship("Post", back_populates="images")


class Report(Base):
    __tablename__ = "reports"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    reporter_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    reason = Column(String, nullable=False)
    detail = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("post_id", "reporter_id", name="user_post_report_uc"),
    )

    reporter = relationship("User")
    post = relationship("Post")