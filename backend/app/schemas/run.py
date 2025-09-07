# app/schemas/run.py
from pydantic import BaseModel, Field
from pydantic import ConfigDict
from datetime import datetime
import uuid
from typing import List, Optional, Any

class RunBase(BaseModel):
    """
    Run 스키마의 공통 속성
    """
    title: Optional[str] = None
    notes: Optional[str] = None
    distance: Optional[float] = None
    duration: Optional[float] = None
    route: Optional[List[Any]] = None

    calories_burned: Optional[float] = None
    avg_pace: Optional[float] = None
    avg_heart_rate: Optional[int] = None
    avg_cadence: Optional[int] = None
    total_elevation_gain: Optional[float] = None
    splits: Optional[List[Any]] = None
    # 내부 필드는 snake_case로, 외부 JSON은 chartData로
    chart_data: Optional[List[Any]] = Field(default=None, alias="chartData")

    # camelCase ↔ snake_case 모두 허용 + ORM 호환
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)


class RunCreate(BaseModel):
    """
    새로운 러닝 기록 생성 스키마.
    러닝 시작 시 우선 is_course_candidate만 받되,
    필요하면 RunBase로 확장해도 됩니다.
    """
    is_course_candidate: bool = Field(default=False, alias="isCourseCandidate")

    model_config = ConfigDict(populate_by_name=True, from_attributes=True)


class RunUpdate(BaseModel):
    """
    부분 업데이트용 스키마 (모든 필드 선택)
    """
    title: Optional[str] = None
    notes: Optional[str] = None
    distance: Optional[float] = None
    duration: Optional[float] = None
    route: Optional[List[Any]] = None
    calories_burned: Optional[float] = None
    avg_pace: Optional[float] = None
    avg_heart_rate: Optional[int] = None
    avg_cadence: Optional[int] = None
    total_elevation_gain: Optional[float] = None
    splits: Optional[List[Any]] = None
    status: Optional[str] = None
    end_at: Optional[datetime] = None
    is_edited: Optional[bool] = None
    is_course_candidate: Optional[bool] = Field(default=None, alias="isCourseCandidate")
    chart_data: Optional[List[Any]] = Field(default=None, alias="chartData")

    model_config = ConfigDict(populate_by_name=True, from_attributes=True)


class Run(RunBase):
    """
    API 응답 스키마
    """
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    end_at: Optional[datetime] = None
    status: Optional[str] = None
    is_edited: bool
    is_course_candidate: bool = Field(default=False, alias="isCourseCandidate")

    model_config = ConfigDict(populate_by_name=True, from_attributes=True)
