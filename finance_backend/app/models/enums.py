from enum import Enum

class Provider(str, Enum):
    LOCAL = "LOCAL"
    GOOGLE = "GOOGLE"
    LOCAL_GOOGLE = "LOCAL_GOOGLE"

class AccountType(str, Enum):
    CASH = "CASH"
    WALLET = "WALLET"
    BANK = "BANK"
    CREDIT_CARD = "CREDIT_CARD"
    CRYPTO = "CRYPTO"

class CategoryType(str, Enum):
    INCOME = "INCOME"
    EXPENSE = "EXPENSE"
    BOTH = "BOTH"

class BudgetPeriod(str, Enum):
    WEEKLY = "  WEEKLY"
    MONTHLY = "MONTHLY"
    YEARLY = "YEARLY"

class TransactionType(str, Enum):
    INCOME = "INCOME"
    EXPENSE = "EXPENSE"
    TRANSFER = "TRANSFER"