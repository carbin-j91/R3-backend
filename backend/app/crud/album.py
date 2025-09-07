# backend/app/crud/album.py
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .base import CRUDBase
from app.models.album import Album
from app.schemas.album import AlbumCreate, AlbumUpdate

class CRUDAlbum(CRUDBase[Album, AlbumCreate, AlbumUpdate]):
    async def create_with_owner(self, db: AsyncSession, *, obj_in: AlbumCreate, user_id: UUID) -> Album:
        db_obj = Album(
            user_id=user_id,
            run_id=obj_in.run_id,
            original_url=obj_in.original_url,
            composed_url=obj_in.composed_url,
            caption=obj_in.caption,
            tags=obj_in.tags,
            visibility=(obj_in.visibility or "private"),
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

    async def get_multi_by_user(
        self, db: AsyncSession, *, user_id: UUID, skip: int = 0, limit: int = 50
    ) -> List[Album]:
        stmt = (
            select(Album)
            .where(Album.user_id == user_id)
            .order_by(Album.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        res = await db.execute(stmt)
        return list(res.scalars())

    async def remove_for_user(self, db: AsyncSession, *, id: UUID, user_id: UUID) -> Optional[Album]:
        obj = await self.get(db, id=id)
        if not obj or obj.user_id != user_id:
            return None
        await db.delete(obj)
        await db.commit()
        return obj

# ✅ 이 인스턴스가 바로 from app.crud.album import album 로 import 되는 심볼입니다.
album = CRUDAlbum(Album)

__all__ = ["CRUDAlbum", "album"]
