from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import uuid # uuid를 가져옵니다.

from app import crud, models, schemas
from app.api.v1 import deps

router = APIRouter()

@router.post("/", response_model=schemas.Run)
async def create_run(
    *,
    db: AsyncSession = Depends(deps.get_db),
    run_in: schemas.RunCreate,
    current_user: models.User = Depends(deps.get_current_user)
) -> models.Run:
    """
    현재 로그인된 사용자의 새로운 러닝 기록을 생성합니다.
    """
    run = await crud.run.create_run(db=db, run=run_in, user_id=current_user.id)
    return run

@router.get("/", response_model=List[schemas.Run])
async def read_runs(
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
) -> List[models.Run]:
    """
    현재 로그인된 사용자의 모든 러닝 기록 목록을 반환합니다.
    """
    runs = await crud.run.get_runs_by_user(db=db, user_id=current_user.id)
    return runs


@router.get("/{run_id}", response_model=schemas.Run)
async def read_run(
    run_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    ID로 특정 러닝 기록을 조회합니다.
    """
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
    """
    ID로 특정 러닝 기록을 수정합니다.
    """
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    
    run = await crud.run.update_run(db=db, db_run=run, run_in=run_in)
    return run

@router.delete("/{run_id}", response_model=schemas.Run)
async def delete_run(
    run_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
):
    """
    ID로 특정 러닝 기록을 삭제합니다.
    """
    run = await crud.run.get_run(db=db, id=run_id, user_id=current_user.id)
    if not run:
        raise HTTPException(status_code=404, detail="Run not found")
    
    await crud.run.delete_run(db=db, db_run=run)
    return run
