class TransactionException implements Exception {}

class CouldnotCreateTransaction implements TransactionException {}

class CouldnotCreateTransferTransaction implements TransactionException {}

class CouldnotFetchTransactions implements TransactionException {}

class CouldnotGetTransaction implements TransactionException {}

class CouldnotUpdateTransaction implements TransactionException {}

class CouldnotDeleteTransaction implements TransactionException {}

class CouldnotDeleteTransferTransaction implements TransactionException {}

class CouldnotGenerateTransactionsSummary implements TransactionException {}

class CouldnotGenerateTransactionsStats implements TransactionException {}

class CouldnotGenerateTimeSeries implements TransactionException {}

class CouldnotGetAccountBalances implements TransactionException {}

class CannotUpdateTransferTransactions implements TransactionException {}

class AccountBalanceTnsufficient implements TransactionException {}

class InvalidInputtedAmount implements TransactionException {}

class InvalidTransferTransaction implements TransactionException {}

class CouldnotCreateBulkTransactions implements TransactionException {
  final int code;
  CouldnotCreateBulkTransactions(this.code);
}