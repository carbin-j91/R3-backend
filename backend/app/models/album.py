# backend/app/models/album.py
from uuid import uuid4

from sqlalchemy import Column, String, Text, ForeignKey, TIMESTAMP, text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.session import Base  # ✅ 여기만 수정

class Album(Base):
    __tablename__ = "albums"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    run_id = Column(UUID(as_uuid=True), ForeignKey("runs.id", ondelete="SET NULL"), nullable=True, index=True)

    original_url = Column(Text, nullable=True)
    composed_url = Column(Text, nullable=False)

    caption = Column(String(255), nullable=True)
    tags = Column(JSONB, nullable=True)
    visibility = Column(String(20), nullable=False, default="private")

    created_at = Column(TIMESTAMP(timezone=False), nullable=False, server_default=text("now()"))

    user = relationship("User", lazy="selectin")
    run = relationship("Run", lazy="selectin")
