import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .user import User
from app.db.session import Base

class Post(Base):
    """
    사용자가 작성한 '게시글' 정보를 저장하는 테이블입니다.
    """
    __tablename__ = "posts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, index=True, nullable=False)
    content = Column(Text, nullable=True)
    
    # User 모델과의 관계 설정
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    created_at = Column(DateTime, default=func.now())

    # User 모델 및 Comment 모델과의 관계 설정
    author = relationship("User")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")

class Comment(Base):
    """
    게시글에 달린 '댓글' 정보를 저장하는 테이블입니다.
    """
    __tablename__ = "comments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    content = Column(Text, nullable=False)

    # User, Post 모델과의 관계 설정
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id"), nullable=False)

    created_at = Column(DateTime, default=func.now())

    # 다른 모델과의 관계 설정
    author = relationship("User")
    post = relationship("Post", back_populates="comments")
    
    