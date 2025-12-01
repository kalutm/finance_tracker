class TransactionErrorScenario{
  final int statusCode;
  final String code;
  final Type expectedException;

  TransactionErrorScenario({
    required this.statusCode,
    required this.code,
    required this.expectedException,
  });
}