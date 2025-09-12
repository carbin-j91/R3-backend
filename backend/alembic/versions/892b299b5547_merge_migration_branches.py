"""Merge migration branches

Revision ID: 892b299b5547
Revises: c3a52b72ead1, fb173b674689
Create Date: 2025-09-12 07:57:18.716450

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '892b299b5547'
down_revision: Union[str, Sequence[str], None] = ('c3a52b72ead1', 'fb173b674689')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
