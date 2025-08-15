from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select # select 추가
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import get_password_hash

# ----> 아래 함수를 추가합니다. <----
async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    """
    이메일 주소로 사용자를 조회합니다.
    """
    result = await db.execute(select(User).filter(User.email == email))
    return result.scalars().first()

async def create_user(db: AsyncSession, user: UserCreate) -> User:
    """
    새로운 사용자를 데이터베이스에 생성합니다.
    - user: Pydantic 스키마로부터 받은 사용자 생성 데이터 (이메일, 비밀번호)
    - db: 데이터베이스 세션
    """
    # 아직 비밀번호 해싱을 적용하지 않았습니다.
    # 우선은 평문으로 저장하고, 바로 다음 단계에서 보안을 강화할 예정입니다.
    # ----> 2. User 모델을 만들기 전에 비밀번호를 해싱합니다. <----
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password  # 평문 비밀번호 대신 해시 값을 저장합니다.
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user