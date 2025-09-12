"""Add community features tables

Revision ID: c3a52b72ead1
Revises: 6753befa1464
Create Date: 2025-09-12 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'c3a52b72ead1'
down_revision: Union[str, None] = '6753befa1464'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ### Create Community Tables ###
    op.create_table('posts',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('author_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('category', sa.String(), nullable=False),
        sa.Column('content_json', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('content_html', sa.Text(), nullable=False),
        sa.Column('content_text', sa.Text(), nullable=False),
        sa.Column('cover_image_url', sa.String(), nullable=True),
        sa.Column('region', sa.String(), nullable=True),
        sa.Column('age_group', sa.String(), nullable=True),
        sa.Column('is_hot', sa.Boolean(), nullable=True),
        sa.Column('hot_score', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['author_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_posts_age_group'), 'posts', ['age_group'], unique=False)
    op.create_index(op.f('ix_posts_category'), 'posts', ['category'], unique=False)
    op.create_index(op.f('ix_posts_hot_score'), 'posts', ['hot_score'], unique=False)
    op.create_index(op.f('ix_posts_is_hot'), 'posts', ['is_hot'], unique=False)
    op.create_index(op.f('ix_posts_region'), 'posts', ['region'], unique=False)
    op.create_index(op.f('ix_posts_title'), 'posts', ['title'], unique=False)

    op.create_table('comments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('author_id', sa.UUID(), nullable=False),
        sa.Column('post_id', sa.UUID(), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['author_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    op.create_table('post_images',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('post_id', sa.UUID(), nullable=False),
        sa.Column('url', sa.String(), nullable=False),
        sa.Column('width', sa.Integer(), nullable=True),
        sa.Column('height', sa.Integer(), nullable=True),
        sa.Column('order', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    op.create_table('reactions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('post_id', sa.UUID(), nullable=False),
        sa.Column('reaction_type', sa.Enum('like', 'bookmark', name='reaction_type_enum'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('post_id', 'user_id', 'reaction_type', name='user_post_reaction_uc')
    )

    op.create_table('reports',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('reporter_id', sa.UUID(), nullable=False),
        sa.Column('post_id', sa.UUID(), nullable=False),
        sa.Column('reason', sa.String(), nullable=False),
        sa.Column('detail', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['reporter_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('post_id', 'reporter_id', name='user_post_report_uc')
    )
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### Drop Community Tables ###
    op.drop_table('reports')
    op.drop_table('reactions')
    op.drop_table('post_images')
    op.drop_table('comments')
    op.drop_index(op.f('ix_posts_title'), table_name='posts')
    op.drop_index(op.f('ix_posts_region'), table_name='posts')
    op.drop_index(op.f('ix_posts_is_hot'), table_name='posts')
    op.drop_index(op.f('ix_posts_hot_score'), table_name='posts')
    op.drop_index(op.f('ix_posts_category'), table_name='posts')
    op.drop_index(op.f('ix_posts_age_group'), table_name='posts')
    op.drop_table('posts')
    # ### end Alembic commands ###