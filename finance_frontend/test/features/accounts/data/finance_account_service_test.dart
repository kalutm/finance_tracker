import 'dart:convert';

import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/exceptions/account_exceptions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockSecureStorageService mockStorage;
  late MockNetworkClient mockNetwork;

  setUpAll(() {
    registerFallbackValue(
      RequestModel(
        method: "GET",
        url: Uri.parse("http://fake.com/accounts"),
        headers: {
          "Authorization": "Bearer fake_access_token",
          "Content-Type": "application/json",
        },
      ),
    );
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

    // Arrange
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
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

    // Act
    final accounts = await accountService.getUserAccounts();

    //Assert
    expect(accounts.length, 3);
  });

  test('test get user accounts throws Error', () async {
    // Arrange
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
    when(() => mockNetwork.send(any())).thenAnswer((_) async {
      return ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({}));
    });

    final container = ProviderContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue("http://fake.com"),
      ],
    );
    final accountService = container.read(accountServiceProvider);

    // Act & Assert
    expect(
      () => accountService.getUserAccounts(),
      throwsA(isA<CouldnotFetchAccounts>()),
    );
  });

  test('test create account success', () async {
    // Arrange
    final create = AccountCreate(
      name: "CBE",
      type: AccountType.BANK,
      currency: "ETB",
    );
    final response = ResponseModel(
      statusCode: 201,
      headers: {},
      body: jsonEncode({
        'id': 1,
        'balance': '50',
        'name': 'Telebirr',
        'type': AccountType.WALLET.name,
        'currency': 'ETB',
        'active': true,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
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

    // Act
    final account = await accountService.createAccount(create);

    // Assert
    expect(account.id, "1");
  });

  test('test create account throws Error', () async {
    // Arrange
    final create = AccountCreate(
      name: "CBE",
      type: AccountType.BANK,
      currency: "ETB",
    );

    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
    when(() => mockNetwork.send(any())).thenAnswer((_) async {
      return ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({}));
    });

    final container = ProviderContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue("http://fake.com"),
      ],
    );
    final accountService = container.read(accountServiceProvider);

    // Act & Assert
    expect(
      () => accountService.createAccount(create),
      throwsA(isA<CouldnotCreateAccount>()),
    );
  });

  test('test deactivate account success', () async {
    // Arrange
    final response = ResponseModel(
      statusCode: 200,
      headers: {},
      body: jsonEncode({
        'id': 1,
        'balance': '50',
        'name': 'Telebirr',
        'type': AccountType.WALLET.name,
        'currency': 'ETB',
        'active': false,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
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

    // Act
    final account = await accountService.deactivateAccount("1");

    // Assert
    expect(account.id, "1");
    expect(account.active, false);
  });

  test('test deactivate account throws Error', () async {
    // Arrange
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
    when(() => mockNetwork.send(any())).thenAnswer((_) async {
      return ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({}));
    });

    final container = ProviderContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue("http://fake.com"),
      ],
    );
    final accountService = container.read(accountServiceProvider);

    // Act & Assert
    expect(
      () => accountService.deactivateAccount("1"),
      throwsA(isA<CouldnotDeactivateAccount>()),
    );
  });

  test('test delete account success', () async {
    // Arrange
    final response = ResponseModel(
      statusCode: 204,
      headers: {},
      body: jsonEncode({}),
    );
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
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

    // Act
    await accountService.deleteAccount("1");
    // final currAccounts = await accountService.accountsStream.last;
    // final idx = currAccounts.indexWhere((a) => a.id == "1");
    // // Assert
    // expect(idx, -1);
    
  });

  test('test delete account throws Error', () async {
    // Arrange
    when(() => mockStorage.readString(key: "access_token")).thenAnswer((
      _,
    ) async {
      return "fake_access_token";
    });
    when(() => mockNetwork.send(any())).thenAnswer((_) async {
      return ResponseModel(statusCode: 401, headers: {}, body: jsonEncode({}));
    });

    final container = ProviderContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue("http://fake.com"),
      ],
    );
    final accountService = container.read(accountServiceProvider);

    // Act & Assert
    expect(
      () => accountService.deleteAccount("1"),
      throwsA(isA<CouldnotDeleteAccount>()),
    );
  });
}
