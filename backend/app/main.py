from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import users as users_router
from app.api.v1 import login as login_router
from app.api.v1 import runs as runs_router
from app.api.v1 import courses as courses_router
from app.api.v1 import course_attempts as course_attempts_router

app = FastAPI(
    title="R3 Project API",
    description="API for the R3 Running App, built with FastAPI.",
    version="0.1.0",
)

# ----> 2. 아래 CORS 미들웨어 설정을 통째로 추가합니다. <----
# 이 설정은 어떤 출처(origins), 메소드(methods), 헤더(headers)의 요청이든
# 우리 API 서버에 접근하는 것을 허용합니다. (개발 환경에 적합한 설정입니다.)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 출처 허용
    allow_credentials=True,
    allow_methods=["*"],   # 모든 HTTP 메소드 허용
    allow_headers=["*"],   # 모든 HTTP 헤더 허용
)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to R3 Backend!"}

app.include_router(users_router.router, prefix="/api/v1/users", tags=["users"])
app.include_router(login_router.router, prefix="/api/v1", tags=["login"])
app.include_router(runs_router.router, prefix="/api/v1/runs", tags=["runs"])
app.include_router(courses_router.router, prefix="/api/v1/courses", tags=["courses"])
app.include_router(course_attempts_router.router, prefix="/api/v1", tags=["course_attempts"])
