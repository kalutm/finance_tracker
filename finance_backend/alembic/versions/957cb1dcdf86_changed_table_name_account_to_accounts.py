"""changed table name account to accounts

Revision ID: 957cb1dcdf86
Revises: 2db139c50cf8
Create Date: 2025-09-06 14:41:02.697301

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel

# revision identifiers, used by Alembic.
revision: str = '957cb1dcdf86'
down_revision: Union[str, Sequence[str], None] = '2db139c50cf8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema by renaming the 'account' table to 'accounts'."""
    # ### commands to safely rename the table and update foreign keys ###
    
    # 1. Rename the 'account' table to 'accounts'
    op.rename_table('account', 'accounts')

    # 2. Drop the old foreign key constraint from 'transactions' to 'account'
    op.drop_constraint(
        'transactions_account_id_fkey', 'transactions', type_='foreignkey'
    )

    # 3. Create a new foreign key constraint from 'transactions' to the new 'accounts' table
    op.create_foreign_key(
        'transactions_account_id_fkey', 'transactions', 'accounts',
        ['account_id'], ['id']
    )
    
    # Note: Alembic's autogenerate created new index names. The following
    # lines are needed to handle the index name changes.
    op.drop_index('ix_account_user_id', table_name='accounts')
    op.create_index(op.f('ix_accounts_user_id'), 'accounts', ['user_id'], unique=False)

    # ### end Alembic commands ###


def downgrade() -> None:
    """Downgrade schema by renaming the 'accounts' table back to 'account'."""
    # ### commands to revert the changes ###
    
    # 1. Drop the new foreign key constraint from 'transactions' to 'accounts'
    op.drop_constraint(
        'transactions_account_id_fkey', 'transactions', type_='foreignkey'
    )

    # 2. Create the original foreign key constraint from 'transactions' to the old 'account' table
    op.create_foreign_key(
        'transactions_account_id_fkey', 'transactions', 'account',
        ['account_id'], ['id']
    )

    # 3. Rename the 'accounts' table back to 'account'
    op.rename_table('accounts', 'account')
    
    # Revert the index name changes
    op.drop_index('ix_accounts_user_id', table_name='account')
    op.create_index(op.f('ix_account_user_id'), 'account', ['user_id'], unique=False)
    
    # ### end Alembic commands ###