from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, models, schemas
from app.api.v1 import deps # deps만 가져옵니다.

router = APIRouter()

@router.get("/me", response_model=schemas.User)
async def read_users_me(
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    현재 로그인된 사용자의 정보를 반환합니다.
    """
    return current_user

@router.post("/", response_model=schemas.User)
async def create_new_user(
    user: schemas.UserCreate,
    db: AsyncSession = Depends(deps.get_db), # deps.get_db를 사용합니다.
):
    """
    새로운 사용자를 생성합니다.
    """
    return await crud.user.create_user(db=db, user=user)