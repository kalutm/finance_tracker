# base class for all account error's
class AccountError(Exception):
    pass

class AccountNotFound(AccountError):
    pass

class AccountNameAlreadyTaken(AccountError):
    pass

class UserNotAuthorizedForThisAccount(AccountError):
    pass

class CouldnotDeleteAccount(AccountError):
    pass