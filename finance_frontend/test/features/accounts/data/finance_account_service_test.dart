import 'dart:convert';

import 'package:finance_frontend/core/network/network_client.dart';
import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/mocks.dart';

class MockHttpNetworkClient extends Mock implements NetworkClient {}

class MockFinanceSecureStorageService extends Mock
    implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorage;
  late MockNetworkClient mockNetwork;

  setUpAll(() {
    registerFallbackValue(RequestModel(
      method: "GET",
      url: Uri.parse("http://fake.com/accounts"),
      headers: {
      "Authorization": "Bearer fake_access_token",
      "Content-Type": "application/json",
    },
    ));
    mockStorage = MockSecureStorageService();
    mockNetwork = MockNetworkClient();
  });

  test('test get user accounts success', () async {
    final body = jsonEncode({
      "total": 3,
      "accounts": [
        {
          'id': 1,
          'balance': '50',
          'name': 'Telebirr',
          'type': AccountType.WALLET.name,
          'currency': 'ETB',
          'active': true,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'balance': '50',
          'name': 'Dashen',
          'type': AccountType.BANK.name,
          'currency': 'ETB',
          'active': true,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 3,
          'balance': '50',
          'name': 'CBE',
          'type': AccountType.BANK.name,
          'currency': 'ETB',
          'active': true,
          'created_at': DateTime.now().toIso8601String(),
        },
      ],
    });

    final response = ResponseModel(statusCode: 200, headers: {}, body: body);

    // arrange
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((_) async {
      return "fake_access_token";
    },);
    when(() => mockNetwork.send(any())).thenAnswer((_) async {
      return response;
    });
    

    final container = ProviderContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue("http://fake.com"),
      ],
    );
    final accountService = container.read(accountServiceProvider);

    // act
    final accounts = await accountService.getUserAccounts();

    // assert
    expect(accounts.length, 3);
  });
}
