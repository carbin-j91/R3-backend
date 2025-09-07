"""create courses and course_attempts

Revision ID: 9d36035bb1d5
Revises: 83bee2293f3f
Create Date: 2025-09-06 23:39:10.564965

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9d36035bb1d5'
down_revision: Union[str, Sequence[str], None] = '83bee2293f3f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
