from datetime import datetime, timedelta, timezone
from passlib.context import CryptContext
from jose import JWTError, jwt
from app.core.config import settings

# CryptContext는 어떤 해싱 알고리즘을 사용할지 passlib에 알려줍니다.
# "bcrypt"는 현재 산업 표준으로 사용되는 강력한 해싱 알고리즘입니다.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    """
    평문 비밀번호를 bcrypt를 사용하여 해싱합니다.
    """
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    평문 비밀번호와 저장된 해시를 비교하여 일치 여부를 확인합니다.
    """
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    """
    주어진 데이터로 JWT 액세스 토큰을 생성합니다.
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # 기본 만료 시간: 15분
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt