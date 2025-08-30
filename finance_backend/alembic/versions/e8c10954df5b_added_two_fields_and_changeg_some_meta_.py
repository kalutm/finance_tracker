"""added two fields and changeg some meta data of the users table

Revision ID: e8c10954df5b
Revises: 2e71ad04a34e
Create Date: 2025-08-28 09:52:10.956274

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


# revision identifiers, used by Alembic.
revision: str = 'e8c10954df5b'
down_revision: Union[str, Sequence[str], None] = '2e71ad04a34e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema for users and account tables."""
    conn = op.get_bind()

    # 1. Drop foreign key in account referencing users.id
    op.drop_constraint("account_user_id_fkey", "account", type_="foreignkey")

    # 2. Alter users.id to UUID
    op.execute("ALTER TABLE users ALTER COLUMN id TYPE uuid USING id::uuid")

    # 3. Alter account.user_id to UUID to match users.id
    op.execute("ALTER TABLE account ALTER COLUMN user_id TYPE uuid USING user_id::uuid")

    # 4. Recreate foreign key
    op.create_foreign_key(
        "account_user_id_fkey",
        source_table="account",
        referent_table="users",
        local_cols=["user_id"],
        remote_cols=["id"],
    )

    # 5. Create provider enum type
    provider_enum = sa.Enum("LOCAL", "GOOGLE", "LOCAL_GOOGLE", name="provider")
    provider_enum.create(conn, checkfirst=True)

    # 6. Add provider columns
    op.add_column("users", sa.Column("provider", provider_enum, nullable=False))
    op.add_column("users", sa.Column("provider_id", sa.String(), nullable=True))

    # 7. Make password_hash nullable
    op.alter_column(
        "users",
        "password_hash",
        existing_type=sa.VARCHAR(),
        nullable=True
    )

    # 8. Add unique constraint on email
    op.create_unique_constraint("uq_users_email", "users", ["email"])




def downgrade() -> None:
    """Downgrade schema safely."""

    # Revert password_hash to NOT NULL
    op.alter_column(
        "users",
        "password_hash",
        existing_type=sa.VARCHAR(),
        nullable=False
    )

    # Drop provider columns
    op.drop_column("users", "provider_id")
    op.drop_column("users", "provider")

    # Drop the enum type
    op.execute("DROP TYPE provider")

    # Drop and recreate FK safely for downgrade
    op.drop_constraint("account_user_id_fkey", "account", type_="foreignkey")
    op.execute("ALTER TABLE account ALTER COLUMN user_id TYPE VARCHAR USING user_id::text")
    op.execute("ALTER TABLE users ALTER COLUMN id TYPE VARCHAR USING id::text")
    op.create_foreign_key(
        "account_user_id_fkey",
        source_table="account",
        referent_table="users",
        local_cols=["user_id"],
        remote_cols=["id"],
    )
