"""enable full cascade delete when deleting a user

Revision ID: c472f4a1cefe
Revises: 625b860aafa4
Create Date: 2025-11-16 12:31:01.165187

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


# revision identifiers, used by Alembic.
revision: str = "c472f4a1cefe"
down_revision: Union[str, Sequence[str], None] = "625b860aafa4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema: enable ON DELETE CASCADE everywhere."""

    # ACCOUNTS
    op.drop_constraint("account_user_id_fkey", "accounts", type_="foreignkey")
    op.create_foreign_key(
        "fk_accounts_user_id_users",
        "accounts",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )

    # BUDGETS
    op.drop_constraint("budgets_user_id_fkey", "budgets", type_="foreignkey")
    op.drop_constraint("budgets_category_id_fkey", "budgets", type_="foreignkey")

    op.create_foreign_key(
        "fk_budgets_user_id_users",
        "budgets",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_budgets_category_id_categories",
        "budgets",
        "categories",
        ["category_id"],
        ["id"],
        ondelete="CASCADE",
    )

    # CATEGORIES
    op.drop_constraint("categories_user_id_fkey", "categories", type_="foreignkey")
    op.create_foreign_key(
        "fk_categories_user_id_users",
        "categories",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )

    # TRANSACTIONS
    op.drop_constraint(
        "transactions_account_id_fkey", "transactions", type_="foreignkey"
    )
    op.drop_constraint("transactions_user_id_fkey", "transactions", type_="foreignkey")
    op.drop_constraint(
        "transactions_category_id_fkey", "transactions", type_="foreignkey"
    )

    op.create_foreign_key(
        "fk_transactions_user_id_users",
        "transactions",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_transactions_category_id_categories",
        "transactions",
        "categories",
        ["category_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_transactions_account_id_accounts",
        "transactions",
        "accounts",
        ["account_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    """Downgrade schema: restore original FK constraints without CASCADE."""

    # TRANSACTIONS
    op.drop_constraint(
        "fk_transactions_account_id_accounts", "transactions", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_transactions_category_id_categories", "transactions", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_transactions_user_id_users", "transactions", type_="foreignkey"
    )

    op.create_foreign_key(
        "transactions_account_id_fkey",
        "transactions",
        "accounts",
        ["account_id"],
        ["id"],
    )
    op.create_foreign_key(
        "transactions_category_id_fkey",
        "transactions",
        "categories",
        ["category_id"],
        ["id"],
    )
    op.create_foreign_key(
        "transactions_user_id_fkey",
        "transactions",
        "users",
        ["user_id"],
        ["id"],
    )

    # CATEGORIES
    op.drop_constraint("fk_categories_user_id_users", "categories", type_="foreignkey")
    op.create_foreign_key(
        "categories_user_id_fkey",
        "categories",
        "users",
        ["user_id"],
        ["id"],
    )

    # BUDGETS
    op.drop_constraint(
        "fk_budgets_category_id_categories", "budgets", type_="foreignkey"
    )
    op.drop_constraint("fk_budgets_user_id_users", "budgets", type_="foreignkey")

    op.create_foreign_key(
        "budgets_category_id_fkey",
        "budgets",
        "categories",
        ["category_id"],
        ["id"],
    )
    op.create_foreign_key(
        "budgets_user_id_fkey",
        "budgets",
        "users",
        ["user_id"],
        ["id"],
    )

    # ACCOUNTS
    op.drop_constraint("fk_accounts_user_id_users", "accounts", type_="foreignkey")
    op.create_foreign_key(
        "account_user_id_fkey",
        "accounts",
        "users",
        ["user_id"],
        ["id"],
    )
