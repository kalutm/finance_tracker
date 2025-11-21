class TransactionError(Exception):
    pass

class InsufficientBalance(TransactionError):
    pass

class TransactionNotFound(TransactionError):
    pass

class InvalidAmount(TransactionError):
    pass

class CanNotUpdateTransaction(TransactionError):
    pass

class InvalidTransferTransaction(TransactionError):
    pass