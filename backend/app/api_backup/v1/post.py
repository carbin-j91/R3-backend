from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

# 정확한 경로를 명시합니다.
from app import crud, models, schemas
from backend.app.api.v1.deps import deps

router = APIRouter()

@router.post("/", response_model=schemas.Post)
async def create_post(
    *,
    db: AsyncSession = Depends(deps.get_db),
    post_in: schemas.PostCreate,
    current_user: models.User = Depends(deps.get_current_user)
) -> models.Post:
    post = await crud.post.create_post(db=db, post=post_in, user_id=current_user.id)
    return post

@router.get("/", response_model=List[schemas.Post])
async def read_posts(
    db: AsyncSession = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
):
    posts = await crud.post.get_posts(db=db, skip=skip, limit=limit)
    return posts