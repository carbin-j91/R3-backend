from fastapi import FastAPI
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

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Welcome to R3 Backend!"}

app.include_router(users_router.router, prefix="/api/v1/users", tags=["users"])
app.include_router(login_router.router, prefix="/api/v1", tags=["login"])
app.include_router(runs_router.router, prefix="/api/v1/runs", tags=["runs"])
app.include_router(courses_router.router, prefix="/api/v1/courses", tags=["courses"])
app.include_router(course_attempts_router.router, prefix="/api/v1", tags=["course_attempts"])
