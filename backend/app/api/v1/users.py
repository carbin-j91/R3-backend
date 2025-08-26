from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app import crud, models, schemas
from app.api.v1 import deps

router = APIRouter() # <--- 이 줄이 빠져있었을 겁니다!

@router.get("/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(deps.get_current_user)):
    return current_user

@router.post("/", response_model=schemas.User)
async def create_new_user(user: schemas.UserCreate, db: AsyncSession = Depends(deps.get_db)):
    return await crud.user.create_user(db=db, user=user)

@router.patch("/me", response_model=schemas.User)
async def update_user_me(
    *,
    db: AsyncSession = Depends(deps.get_db),
    user_in: schemas.UserUpdate,
    current_user: models.User = Depends(deps.get_current_user)
) -> models.User:
    """
    현재 로그인된 사용자의 프로필을 수정합니다.
    """
    user = await crud.user.update_user(db=db, db_user=current_user, user_in=user_in)
    return user