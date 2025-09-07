# backend/app/api/v1/albums.py
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from typing import List
from uuid import UUID
from pathlib import Path
import os

from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.core.config import settings
from app.schemas.album import AlbumCreate, AlbumUpdate, AlbumOut
from app.crud.album import album as crud_album
from app.models.user import User

router = APIRouter(prefix="/albums", tags=["albums"])

def ensure_media_dir() -> Path:
    root = Path(settings.MEDIA_ROOT).resolve()
    (root / "albums").mkdir(parents=True, exist_ok=True)
    return root

def build_media_url(rel_path: str) -> str:
    return f"{settings.MEDIA_URL.rstrip('/')}/{rel_path.lstrip('/')}"

@router.post("/upload", summary="(local) 합성 이미지 파일 업로드", response_model=dict)
async def upload_composed_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    if settings.STORAGE_BACKEND != "local":
        raise HTTPException(status_code=501, detail="Use S3 upload on this deployment.")

    media_root = ensure_media_dir()
    user_dir = media_root / "albums" / str(current_user.id)
    user_dir.mkdir(parents=True, exist_ok=True)

    fname = f"{os.path.splitext(file.filename or 'image')[0]}_{os.urandom(4).hex()}.png"
    fpath = user_dir / fname

    data = await file.read()
    with open(fpath, "wb") as f:
        f.write(data)

    rel = f"albums/{current_user.id}/{fname}"
    url = build_media_url(rel)
    return {"url": url, "relative_path": rel}

@router.post("/", response_model=AlbumOut, status_code=status.HTTP_201_CREATED)
async def create_album(
    payload: AlbumCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    created = await crud_album.create_with_owner(db, obj_in=payload, user_id=current_user.id)
    return created

@router.get("/", response_model=List[AlbumOut])
async def list_my_albums(
    skip: int = 0, limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = await crud_album.get_multi_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return items

@router.get("/{album_id}", response_model=AlbumOut)
async def get_album(
    album_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    obj = await crud_album.get(db, id=album_id)
    if not obj or obj.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Album not found")
    return obj

@router.delete("/{album_id}", response_model=AlbumOut)
async def delete_album(
    album_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    obj = await crud_album.remove_for_user(db, id=album_id, user_id=current_user.id)
    if not obj:
        raise HTTPException(status_code=404, detail="Album not found")
    return obj
