from pydantic import BaseModel
from datetime import datetime
import uuid
from typing import List, Optional

from .user import User  # 댓글 작성자 정보를 표시하기 위해 User 스키마를 가져옵니다.

# ====== Comment Schemas ======
class CommentBase(BaseModel):
    content: str

class CommentCreate(CommentBase):
    pass

class Comment(CommentBase):
    id: uuid.UUID
    user_id: uuid.UUID
    post_id: uuid.UUID
    created_at: datetime
    author: Optional[User] = None # 댓글에 작성자 정보 포함

    class Config:
        from_attributes = True

# ====== Post Schemas ======
class PostBase(BaseModel):
    title: str
    content: Optional[str] = None

class PostCreate(PostBase):
    pass

class Post(PostBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    author: Optional[User] = None # 게시글에 작성자 정보 포함
    comments: List[Comment] = [] # 게시글 상세 조회 시 댓글 목록 포함

    class Config:
        from_attributes = True