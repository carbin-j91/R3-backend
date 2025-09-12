"""community tables

Revision ID: fb173b674689
Revises: 6753befa1464
Create Date: 2025-09-12 01:04:33.741883
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'fb173b674689'
down_revision: Union[str, Sequence[str], None] = '6753befa1464'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 0) posts.id를 바꾸기 전에 참조하는 기존 comments 제거 (개발 환경 가정)
    op.drop_table('comments')

    # 1) posts 개편
    #    - author_id는 users.id(UUID)와 타입을 맞춘다.
    op.add_column('posts', sa.Column('author_id', sa.UUID(), nullable=True))  # 일단 NULL 허용
    op.add_column('posts', sa.Column('category', sa.String(length=32), nullable=False, server_default='free'))
    op.add_column('posts', sa.Column('cover_image', sa.String(length=500), nullable=True))
    op.add_column('posts', sa.Column('content_json', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")))
    op.add_column('posts', sa.Column('content_html', sa.Text(), nullable=False, server_default=''))
    op.add_column('posts', sa.Column('region', sa.String(length=64), nullable=True))
    op.add_column('posts', sa.Column('age_group', sa.String(length=16), nullable=True))
    op.add_column('posts', sa.Column('is_hot', sa.Boolean(), nullable=False, server_default=sa.text('false')))
    op.add_column('posts', sa.Column('hot_score', sa.Float(), nullable=False, server_default='0'))
    op.add_column('posts', sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')))

    # posts.id: UUID -> VARCHAR(36) (이 시점엔 comments가 없으므로 FK 충돌 없음)
    op.alter_column('posts', 'id',
                    existing_type=sa.UUID(),
                    type_=sa.String(length=36),
                    existing_nullable=False)

    # 기존 user_id -> author_id 데이터 이관 후 제약 교체
    # (posts.user_id는 UUID라고 가정)
    op.execute("UPDATE posts SET author_id = user_id")
    op.create_foreign_key(None, 'posts', 'users', ['author_id'], ['id'])
    op.alter_column('posts', 'author_id', existing_type=sa.UUID(), nullable=False)

    # 오래된 FK/컬럼 정리
    op.drop_constraint(op.f('posts_user_id_fkey'), 'posts', type_='foreignkey')
    op.drop_column('posts', 'user_id')

    # 인덱스 정리
    op.drop_index(op.f('ix_posts_title'), table_name='posts')
    op.create_index(op.f('ix_posts_age_group'), 'posts', ['age_group'], unique=False)
    op.create_index(op.f('ix_posts_author_id'), 'posts', ['author_id'], unique=False)
    op.create_index('ix_posts_cat_region_hot', 'posts', ['category', 'region', 'hot_score'], unique=False)
    op.create_index(op.f('ix_posts_category'), 'posts', ['category'], unique=False)
    op.create_index(op.f('ix_posts_region'), 'posts', ['region'], unique=False)

    # 2) comments 재생성 (post_id는 VARCHAR(36), user_id는 UUID)
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('post_id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_comments_post_id'), 'comments', ['post_id'], unique=False)
    op.create_index(op.f('ix_comments_user_id'), 'comments', ['user_id'], unique=False)

    # 3) posts를 참조하는 서브 테이블들 생성
    op.create_table(
        'post_images',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('post_id', sa.String(length=36), nullable=False),
        sa.Column('url', sa.String(length=500), nullable=False),
        sa.Column('width', sa.Integer(), nullable=True),
        sa.Column('height', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_post_images_post_id'), 'post_images', ['post_id'], unique=False)

    op.create_table(
        'reactions',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('post_id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('type', sa.String(length=20), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('post_id', 'user_id', 'type', name='uq_reaction'),
    )
    op.create_index(op.f('ix_reactions_post_id'), 'reactions', ['post_id'], unique=False)
    op.create_index(op.f('ix_reactions_user_id'), 'reactions', ['user_id'], unique=False)

    op.create_table(
        'reports',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('post_id', sa.String(length=36), nullable=False),
        sa.Column('reporter_id', sa.UUID(), nullable=False),
        sa.Column('reason', sa.String(length=20), nullable=False),
        sa.Column('detail', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['reporter_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('post_id', 'reporter_id', name='uq_report_once'),
    )
    op.create_index(op.f('ix_reports_post_id'), 'reports', ['post_id'], unique=False)
    op.create_index(op.f('ix_reports_reporter_id'), 'reports', ['reporter_id'], unique=False)
    # ### end Alembic commands ###


def downgrade() -> None:
    """Downgrade schema."""
    # ### commands auto generated by Alembic - edited to remove PostGIS/system-object creates ###
    # --- posts revert ---
    op.add_column('posts', sa.Column('user_id', sa.UUID(), nullable=False))
    op.add_column('posts', sa.Column('content', sa.TEXT(), nullable=True))
    op.drop_constraint(None, 'posts', type_='foreignkey')
    op.create_foreign_key(op.f('posts_user_id_fkey'), 'posts', 'users', ['user_id'], ['id'])
    op.drop_index(op.f('ix_posts_region'), table_name='posts')
    op.drop_index(op.f('ix_posts_category'), table_name='posts')
    op.drop_index('ix_posts_cat_region_hot', table_name='posts')
    op.drop_index(op.f('ix_posts_author_id'), table_name='posts')
    op.drop_index(op.f('ix_posts_age_group'), table_name='posts')
    op.create_index(op.f('ix_posts_title'), 'posts', ['title'], unique=False)
    op.alter_column('posts', 'created_at',
                    existing_type=postgresql.TIMESTAMP(),
                    nullable=True)
    op.alter_column('posts', 'id',
                    existing_type=sa.String(length=36),
                    type_=sa.UUID(),
                    existing_nullable=False)
    op.drop_column('posts', 'updated_at')
    op.drop_column('posts', 'hot_score')
    op.drop_column('posts', 'is_hot')
    op.drop_column('posts', 'age_group')
    op.drop_column('posts', 'region')
    op.drop_column('posts', 'content_html')
    op.drop_column('posts', 'content_json')
    op.drop_column('posts', 'cover_image')
    op.drop_column('posts', 'category')
    op.drop_column('posts', 'author_id')

    # --- comments revert ---
    op.add_column('comments', sa.Column('content', sa.TEXT(), nullable=False))
    op.drop_constraint(None, 'comments', type_='foreignkey')
    op.drop_constraint(None, 'comments', type_='foreignkey')
    op.create_foreign_key(op.f('comments_user_id_fkey'), 'comments', 'users', ['user_id'], ['id'])
    op.create_foreign_key(op.f('comments_post_id_fkey'), 'comments', 'posts', ['post_id'], ['id'])
    op.drop_index(op.f('ix_comments_user_id'), table_name='comments')
    op.drop_index(op.f('ix_comments_post_id'), table_name='comments')
    op.alter_column('comments', 'created_at',
                    existing_type=postgresql.TIMESTAMP(),
                    nullable=True)
    op.alter_column('comments', 'user_id',
                    existing_type=sa.String(length=36),
                    type_=sa.UUID(),
                    existing_nullable=False)
    op.alter_column('comments', 'post_id',
                    existing_type=sa.String(length=36),
                    type_=sa.UUID(),
                    existing_nullable=False)
    op.alter_column('comments', 'id',
                    existing_type=sa.Integer(),
                    type_=sa.UUID(),
                    existing_nullable=False,
                    autoincrement=True)
    op.drop_column('comments', 'body')

    # --- drop community tables ---
    op.drop_index(op.f('ix_reports_reporter_id'), table_name='reports')
    op.drop_index(op.f('ix_reports_post_id'), table_name='reports')
    op.drop_table('reports')

    op.drop_index(op.f('ix_reactions_user_id'), table_name='reactions')
    op.drop_index(op.f('ix_reactions_post_id'), table_name='reactions')
    op.drop_table('reactions')

    op.drop_index(op.f('ix_post_images_post_id'), table_name='post_images')
    op.drop_table('post_images')
    # ### end Alembic commands ###
