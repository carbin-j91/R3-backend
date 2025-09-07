"""add rally_points to courses

Revision ID: 0951308fefa0
Revises: 9d36035bb1d5
Create Date: 2025-09-07 00:30:50.594985

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql as psql

# revision identifiers, used by Alembic.
revision = "xxxx_add_rally_points_to_courses"
down_revision: Union[str, Sequence[str], None] = '9d36035bb1d5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column("courses", sa.Column("rally_points", psql.JSONB(), nullable=True))
    pass


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("courses", "rally_points")
    pass
