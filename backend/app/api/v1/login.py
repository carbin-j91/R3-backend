from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.core.security import create_access_token, verify_password
from app.core.config import settings
from app.api.v1 import deps

router = APIRouter()

@router.post("/token", response_model=schemas.Token)
async def login_for_access_token(
    db: AsyncSession = Depends(deps.get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    """
    사용자 이메일(username)과 비밀번호로 로그인하여 액세스 토큰을 발급받습니다.
    """
    user = await crud.user.get_user_by_email(db, email=form_data.username)
    if not user or not user.hashed_password or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/kakao", response_model=schemas.Token)
async def login_via_kakao(
    user_in: schemas.UserSocialLogin,
    db: AsyncSession = Depends(deps.get_db),
):
    """
    카카오 사용자 정보(social_id)를 받아 R3 서비스 토큰을 발급합니다.
    - 사용자가 DB에 없으면 자동으로 회원가입 처리됩니다.
    """
    user = await crud.user.get_or_create_social_user(db, user_in=user_in)
    if not user:
        raise HTTPException(
            status_code=400,
            detail="Error while processing Kakao login."
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}