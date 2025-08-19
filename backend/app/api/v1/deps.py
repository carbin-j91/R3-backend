from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession
import uuid # uuid를 가져옵니다.

from app import crud, models, schemas
from app.core.config import settings
from app.db.session import AsyncSessionLocal

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/token")

async def get_current_user(
    db: AsyncSession = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> models.User:
    """
    토큰을 검증하고 현재 로그인된 사용자를 반환하는 의존성 함수입니다.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        # ----> "sub"는 이제 이메일이 아닌 ID입니다. <----
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        # token_data = schemas.TokenData(email=email) # 이 줄은 더 이상 필요 없습니다.
    except (JWTError, ValueError): # ID가 UUID 형식이 아닐 경우도 대비합니다.
        raise credentials_exception
    
    # ----> 이메일 대신 ID로 사용자를 찾습니다. <----
    user = await crud.user.get_user_by_id(db, user_id=uuid.UUID(user_id))
    
    if user is None:
        raise credentials_exception
    return user