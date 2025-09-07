# backend/app/main.py
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.api.v1 import users, login, runs, courses, course_attempts, albums

app = FastAPI(
    title="R3 Project API",
    description="API for the R3 Running App, built with FastAPI.",
    version="0.1.0",
)

# CORS (필요 시 allow_origins를 환경별로 제한해도 됩니다)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: prod에서는 특정 도메인으로 제한 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 정적 파일 서빙: 업로드된 이미지(/app/media)를 /media로 노출 ---
# 디렉토리가 없으면 생성해둡니다(StaticFiles mount 시 오류 방지)
Path(settings.MEDIA_ROOT).mkdir(parents=True, exist_ok=True)
app.mount(settings.MEDIA_URL, StaticFiles(directory=settings.MEDIA_ROOT), name="media")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to R3 Backend!"}

# --- v1 라우터 등록 ---
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(login.router, prefix="/api/v1", tags=["login"])
app.include_router(runs.router, prefix="/api/v1/runs", tags=["runs"])
app.include_router(courses.router, prefix="/api/v1/courses", tags=["courses"])
app.include_router(course_attempts.router, prefix="/api/v1", tags=["course_attempts"])
# 앨범 라우터: 파일 내부에서 prefix="/albums"이므로 여기선 "/api/v1"만 추가하면 "/api/v1/albums" 완성
app.include_router(albums.router, prefix="/api/v1", tags=["albums"])

# app.include_router(posts.router, prefix="/api/v1/posts", tags=["posts"])  # (미사용시 주석 유지)
