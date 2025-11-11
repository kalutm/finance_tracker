class AccountException implements Exception {}

class CouldnotFetchAccounts implements AccountException {}

class CouldnotCreateAccount implements AccountException {}

class CouldnotGetAccont implements AccountException {}

class CouldnotUpdateAccount implements AccountException {}

class CouldnotDeactivateAccount implements AccountException {}

class CouldnotRestoreAccount implements AccountException {}

class CouldnotDeleteAccount implements AccountException {}

class CannotDeleteAccountWithTransactions implements AccountException{}