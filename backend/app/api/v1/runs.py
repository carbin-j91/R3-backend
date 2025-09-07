# app/api/v1/runs.py
from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from app import crud, models, schemas
from app.api.v1 import deps

router = APIRouter()

@router.post("/", response_model=schemas.Run)
async def create_run(
    *,
    db: AsyncSession = Depends(deps.get_db),
    # 루트 바디로 RunCreate를 받습니다. (embed 사용 X)
    run_in: schemas.RunCreate,
    current_user: models.User = Depends(deps.get_current_user),
) -> Any:
    # ✅ 함수명 맞추기: create_run_with_owner
    return await crud.run.create_run_with_owner(db=db, run_in=run_in, user_id=current_user.id)

@router.get("/", response_model=List[schemas.Run])
async def read_runs(
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
) -> List[models.Run]:
    return await crud.run.get_runs_by_user(db=db, user_id=current_user.id)

@router.get("/{run_id}", response_model=schemas.Run)
async def read_run(
    run_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    return run

@router.patch("/{run_id}", response_model=schemas.Run)
async def update_run(
    run_id: uuid.UUID,
    run_in: schemas.RunUpdate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    return await crud.run.update_run(db=db, db_run=run, run_in=run_in)

@router.delete("/{run_id}", response_model=schemas.Run)
async def delete_run(
    run_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    await crud.run.delete_run(db=db, db_run=run)
    return run
