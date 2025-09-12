from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession
import uuid
from typing import Optional

from app import crud, models, schemas
from app.core.config import settings
from app.db.session import SessionLocal

# DB 세션을 가져오는 Dependency
async def get_db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session

# OAuth2 스킴 정의, 로그인 API 경로를 settings에서 가져와 일관성 유지
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/login/access-token"
)

async def get_current_user(
    db: AsyncSession = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> models.User:
    """
    (필수) 토큰을 검증하고 현재 로그인된 사용자를 반환합니다.
    유효하지 않은 경우 401 Unauthorized 오류를 발생시킵니다.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # 💡 수정: config.py와 일치하도록 변수 이름 변경
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        token_data = schemas.TokenPayload(sub=user_id)
    except (JWTError, ValueError):
        raise credentials_exception

    user = await crud.user.get_user_by_id(db, user_id=uuid.UUID(token_data.sub))

    if user is None:
        raise credentials_exception
    return user


async def get_optional_current_user(
    db: AsyncSession = Depends(get_db), token: Optional[str] = Depends(oauth2_scheme)
) -> Optional[models.User]:
    """
    (선택) 토큰이 없거나 유효하지 않아도 오류를 발생시키지 않고 None을 반환합니다.
    비로그인 상태에서도 API를 호출할 수 있도록 허용할 때 사용합니다.
    """
    if not token:
        return None
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
        token_data = schemas.TokenPayload(sub=user_id)
    except (JWTError, ValueError):
        return None # 토큰이 유효하지 않으면 조용히 None 반환

    user = await crud.user.get_user_by_id(db, user_id=uuid.UUID(token_data.sub))
    return user