"""sync courses columns

Revision ID: 9446af16ff9b
Revises: xxxx_add_rally_points_to_courses
Create Date: 2025-09-07 00:36:30.296752

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql as psql

# revision identifiers, used by Alembic.
revision = "9446af16ff9b"
down_revision: Union[str, Sequence[str], None] = 'xxxx_add_rally_points_to_courses'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1) 없는 컬럼만 추가 (PostgreSQL 구문)
    op.execute("ALTER TABLE courses ADD COLUMN IF NOT EXISTS status varchar;")
    op.execute("ALTER TABLE courses ADD COLUMN IF NOT EXISTS visibility varchar;")
    op.execute("ALTER TABLE courses ADD COLUMN IF NOT EXISTS rally_points JSONB;")
    op.execute("ALTER TABLE courses ADD COLUMN IF NOT EXISTS created_at timestamp without time zone DEFAULT now();")
    op.execute("ALTER TABLE courses ADD COLUMN IF NOT EXISTS route JSONB;")
    op.execute("ALTER TABLE courses ADD COLUMN IF NOT EXISTS distance double precision;")

    # 2) 기본값 채우기 (NULL 값만 안전하게 보정)
    op.execute("UPDATE courses SET status = COALESCE(status, 'draft');")
    op.execute("UPDATE courses SET visibility = COALESCE(visibility, 'private');")

    # 3) NOT NULL + DEFAULT 설정 (이미 존재하는 컬럼에도 안전)
    op.execute("ALTER TABLE courses ALTER COLUMN status SET DEFAULT 'draft';")
    op.execute("ALTER TABLE courses ALTER COLUMN visibility SET DEFAULT 'private';")
    op.execute("ALTER TABLE courses ALTER COLUMN status SET NOT NULL;")
    op.execute("ALTER TABLE courses ALTER COLUMN visibility SET NOT NULL;")
    pass


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table("courses") as batch:
        batch.drop_column("distance")
        batch.drop_column("route")
        batch.drop_column("created_at")
        batch.drop_column("rally_points")
        batch.drop_column("visibility")
        batch.drop_column("status")
    pass
