"""added description field to categories table

Revision ID: f6c7c95c8934
Revises: c1892fc0ba6d
Create Date: 2025-11-07 20:44:31.608665

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


# revision identifiers, used by Alembic.
revision: str = 'f6c7c95c8934'
down_revision: Union[str, Sequence[str], None] = 'c1892fc0ba6d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('categories', sa.Column('description', sa.String(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('categories', 'description')
