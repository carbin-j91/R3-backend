from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import users, login, runs, courses, course_attempts, posts

app = FastAPI(
    title="R3 Project API",
    description="API for the R3 Running App, built with FastAPI.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to R3 Backend!"}

app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(login.router, prefix="/api/v1", tags=["login"])
app.include_router(runs.router, prefix="/api/v1/runs", tags=["runs"])
app.include_router(courses.router, prefix="/api/v1/courses", tags=["courses"])
app.include_router(course_attempts.router, prefix="/api/v1", tags=["course_attempts"])
app.include_router(posts.router, prefix="/api/v1/posts", tags=["posts"])