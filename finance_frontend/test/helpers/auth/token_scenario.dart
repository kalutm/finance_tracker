class TokenScenario {
  final String? accessToken;
  final bool isAccessExpired;
  final String? refreshToken;
  final bool isRefreshExpired;
  final bool refreshRequestSucceeds;
  final Type? expectedException;
  final bool returnsUser;

  TokenScenario({
    required this.accessToken,
    required this.isAccessExpired,
    required this.refreshToken,
    required this.isRefreshExpired,
    required this.refreshRequestSucceeds,
    this.expectedException,
    required this.returnsUser,

  });
}