from fastapi import FastAPI
from app.api.v1 import users as users_router
from app.api.v1 import login as login_router


# FastAPI 애플리케이션 인스턴스 생성
app = FastAPI(
    title="R3 Project API",
    description="API for the R3 Running App, built with FastAPI.",
    version="0.1.0",
)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to R3 Backend!"}

app.include_router(users_router.router, prefix="/api/v1/users", tags=["users"])
# ----> 2. login 라우터를 앱에 포함시킵니다. <----
app.include_router(login_router.router, prefix="/api/v1", tags=["login"])