# backend/app/schemas/album.py
from typing import Any, Optional
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field

class AlbumBase(BaseModel):
    run_id: Optional[UUID] = None
    caption: Optional[str] = None
    tags: Optional[Any] = None
    visibility: Optional[str] = Field(default="private", description="'private'|'friends'|'public'")

class AlbumCreate(AlbumBase):
    composed_url: str
    original_url: Optional[str] = None

class AlbumUpdate(BaseModel):
    caption: Optional[str] = None
    tags: Optional[Any] = None
    visibility: Optional[str] = None

class AlbumOut(BaseModel):
    id: UUID
    user_id: UUID
    run_id: Optional[UUID]
    composed_url: str
    original_url: Optional[str]
    caption: Optional[str]
    tags: Optional[Any]
    visibility: str
    created_at: datetime

    class Config:
        from_attributes = True  # Pydantic v2
