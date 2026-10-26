"""username_auth

Revision ID: 7a8b9c0d1e2f
Revises: 6757ea163043
Create Date: 2026-10-25 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7a8b9c0d1e2f'
down_revision: Union[str, Sequence[str], None] = '6757ea163043'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('username', sa.String(length=100), nullable=True))
        batch_op.alter_column('email', existing_type=sa.String(length=255), nullable=True)
        batch_op.alter_column('display_name', existing_type=sa.String(length=100), nullable=True)
        batch_op.create_index(batch_op.f('ix_users_username'), ['username'], unique=True)


def downgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_users_username'))
        batch_op.alter_column('display_name', existing_type=sa.String(length=100), nullable=False)
        batch_op.alter_column('email', existing_type=sa.String(length=255), nullable=False)
        batch_op.drop_column('username')
