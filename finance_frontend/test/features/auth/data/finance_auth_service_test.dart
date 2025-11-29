import 'dart:convert';

import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/exceptions/account_exceptions.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/accounts/create_fake_account.dart';
import '../../../helpers/accounts/create_fake_account_create.dart';
import '../../../helpers/auth/create_fake_auth_user.dart';
import '../../../helpers/auth/token_scenario.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_container.dart';

void main() {
  late MockSecureStorageService mockStorage;
  late MockNetworkClient mockNetwork;
  late MockAccountService mockAccountService;
  late MockCategoryService mockCategoryService;
  late MockTransactionService mockTransactionService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      RequestModel(method: 'GET', url: Uri.parse('http://fake.com/accounts')),
    );
  });

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockNetwork = MockNetworkClient();
    mockAccountService = MockAccountService();
    mockCategoryService = MockCategoryService();
    mockTransactionService = MockTransactionService();

    container = createTestContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue('http://fake.com'),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    reset(mockNetwork);
    reset(mockStorage);
  });

  group('FinanceAuthService - network integration & Security', () {
    test('getCurrentUser - returns appropirate response or error', () async {
      final scenarios = <TokenScenario>[
        // 1. No tokens → return null
        TokenScenario(
          accessToken: null,
          isAccessExpired: false,
          refreshToken: null,
          isRefreshExpired: false,
          refreshRequestSucceeds: false,
          expectedException: null,
          returnsUser: false,
        ),

        // 2. Access valid → return user
        TokenScenario(
          accessToken: "A",
          isAccessExpired: false,
          refreshToken: null,
          isRefreshExpired: false,
          refreshRequestSucceeds: false,
          expectedException: null,
          returnsUser: true,
        ),

        // 3. Access expired + refresh valid + refresh request OK → return user
        TokenScenario(
          accessToken: "A",
          isAccessExpired: true,
          refreshToken: "R",
          isRefreshExpired: false,
          refreshRequestSucceeds: true,
          expectedException: null,
          returnsUser: true,
        ),

        // 4. Access expired + refresh valid + refresh request FAIL → throws
        TokenScenario(
          accessToken: "A",
          isAccessExpired: true,
          refreshToken: "R",
          isRefreshExpired: false,
          refreshRequestSucceeds: false,
          expectedException: CouldnotLoadUser,
          returnsUser: false,
        ),

        // 5. Access expired + refresh invalid -> return null
        TokenScenario(
          accessToken: "A",
          isAccessExpired: true,
          refreshToken: "R",
          isRefreshExpired: true,
          refreshRequestSucceeds: false,
          expectedException: null,
          returnsUser: false,
        ),
      ];
      for (final s in scenarios) {
        test("token scenario: ${s.accessToken}, ${s.refreshToken}", () async {
          // Arrange
          when(
            () => mockStorage.readString(key: "access_token"),
          ).thenAnswer((_) async => s.accessToken);
          when(
            () => mockStorage.readString(key: "refresh_token"),
          ).thenAnswer((_) async => s.refreshToken);

          final authService = container.read(authServiceProvider);

          // Mock token expiry check
          when(() => authService.isExpired("A")).thenReturn(s.isAccessExpired);
          when(() => authService.isExpired("R")).thenReturn(s.isRefreshExpired);

          // Mock refresh request
          if (s.refreshRequestSucceeds) {
            when(
              () => mockNetwork.send(
                any(
                  that: isA<RequestModel>().having(
                    (r) => r.method,
                    "Rest method",
                    "POST",
                  ),
                ),
              ),
            ).thenAnswer(
              (_) async => ResponseModel(
                statusCode: 200,
                headers: {},
                body: jsonEncode({"acc_jwt": "NEW_ACCESS"}),
              ),
            );
          } else {
            when(
              () => mockNetwork.send(
                any(
                  that: isA<RequestModel>().having(
                    (r) => r.method,
                    "Rest method",
                    "POST",
                  ),
                ),
              ),
            ).thenAnswer(
              (_) async => ResponseModel(
                statusCode: 400,
                body: jsonEncode({"detail": "error"}),
                headers: {},
              ),
            );
          }

          // mock getUserCridentials
          if (s.returnsUser) {
            when(
              () => mockNetwork.send(
                any(
                  that: isA<RequestModel>().having(
                    (r) => r.method,
                    "Rest method",
                    "GET",
                  ),
                ),
              ),
            ).thenAnswer(
              (_) async => ResponseModel(
                statusCode: 200,
                headers: {},
                body: jsonEncode(fakeAuthUserJson(uid: '1')),
              ),
            );
          }

          // Assert
          if (s.expectedException != null) {
            expect(
              () => authService.getCurrentUser(),
              throwsA(isA<CouldnotLoadUser>()),
            );
          } else {
            final user = await authService.getCurrentUser();
            if (s.returnsUser) {
              expect(user, isNotNull);
            } else {
              expect(user, isNull);
            }
          }
        });
      }
    });

    test('getUserAccounts - non-200 -> throws CouldnotFetchAccounts', () async {
      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');

      when(() => mockNetwork.send(any())).thenAnswer(
        (_) async =>
            ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({})),
      );

      final svc = container.read(accountServiceProvider);

      await expectLater(
        svc.getUserAccounts(),
        throwsA(isA<CouldnotFetchAccounts>()),
      );

      // verify interactions
      verify(() => mockStorage.readString(key: 'access_token')).called(1);
      verify(() => mockNetwork.send(any())).called(1);
      verifyNoMoreInteractions(mockNetwork);
    });

    test('getUserAccounts - network throws exception -> rethrows', () async {
      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');
      when(() => mockNetwork.send(any())).thenThrow(Exception('network down'));
      final svc = container.read(accountServiceProvider);

      await expectLater(svc.getUserAccounts(), throwsA(isA<Exception>()));

      verify(() => mockNetwork.send(any())).called(1);
    });

    test(
      'createAccount - success returns created and updates stream & cache',
      () async {
        final create = fakeAccountCreate();

        final respBody = jsonEncode(
          fakeAccountJson(id: 1, name: 'Telebirr', type: AccountType.WALLET),
        );
        final response = ResponseModel(
          statusCode: 201,
          headers: {},
          body: respBody,
        );

        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');
        when(() => mockNetwork.send(any())).thenAnswer((_) async => response);

        final svc = container.read(accountServiceProvider);

        final emitted = <List<Account>>[];
        final sub = svc.accountsStream.listen(emitted.add);

        final created = await svc.createAccount(create);

        expect(created.id, '1');

        await Future<void>.delayed(Duration.zero); // allow emission
        expect(emitted.isNotEmpty, true);
        expect(emitted.last.any((a) => a.id == '1'), true);

        // verify the HTTP request happened
        verify(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>().having(
                (r) => r.method,
                'method',
                'POST',
              ),
            ),
          ),
        ).called(1);

        // also verify storage call before asserting no more interactions
        verify(() => mockStorage.readString(key: 'access_token')).called(1);

        verifyNoMoreInteractions(mockNetwork);
        verifyNoMoreInteractions(mockStorage);

        await sub.cancel();
      },
    );

    test('createAccount - 400 returns CouldnotCreateAccount', () async {
      final create = AccountCreate(
        name: 'CBE',
        type: AccountType.BANK,
        currency: 'ETB',
      );

      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');
      when(() => mockNetwork.send(any())).thenAnswer(
        (_) async =>
            ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({})),
      );
      final svc = container.read(accountServiceProvider);
      await expectLater(
        svc.createAccount(create),
        throwsA(isA<CouldnotCreateAccount>()),
      );

      verify(() => mockNetwork.send(any())).called(1);
      verifyNoMoreInteractions(mockNetwork);
    });

    test('deactivateAccount - subscribe-first approach', () async {
      // arrange same as above...
      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');

      when(() => mockNetwork.send(any())).thenAnswer((invocation) async {
        final req = invocation.positionalArguments[0] as RequestModel;
        if (req.method == 'POST') {
          return ResponseModel(
            statusCode: 201,
            headers: {},
            body: jsonEncode(fakeAccountJson(id: 1)),
          );
        } else if (req.method == 'PATCH') {
          return ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode(fakeAccountJson(id: 1, active: false)),
          );
        }
        return ResponseModel(
          statusCode: 200,
          headers: {},
          body: jsonEncode({'accounts': []}),
        );
      });

      final svc = container.read(accountServiceProvider);

      final emitted = <List<Account>>[];
      final sub = svc.accountsStream.listen(emitted.add);

      final created = await svc.createAccount(
        AccountCreate(name: 'A', type: AccountType.BANK, currency: 'ETB'),
      );
      expect(created.id, '1');

      final deactivated = await svc.deactivateAccount('1');
      expect(deactivated.active, false);

      // allow microtask to run and emit
      await Future<void>.delayed(Duration.zero);

      expect(emitted.isNotEmpty, true);
      expect(emitted.last.any((a) => a.id == '1' && a.active == false), true);

      await sub.cancel();
      verify(() => mockNetwork.send(any())).called(greaterThanOrEqualTo(2));
    });

    test(
      'deleteAccount - success removes from cache and emits update',
      () async {
        // Arrange: seed cache with one account via createAccount
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');

        when(() => mockNetwork.send(any())).thenAnswer((invocation) async {
          final req = invocation.positionalArguments[0] as RequestModel;
          if (req.method == 'POST') {
            return ResponseModel(
              statusCode: 201,
              headers: {},
              body: jsonEncode(fakeAccountJson(id: 42)),
            );
          } else if (req.method == 'DELETE') {
            return ResponseModel(statusCode: 204, headers: {}, body: '');
          }
          return ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode({'accounts': []}),
          );
        });
        final svc = container.read(accountServiceProvider);

        final emitted = <List<Account>>[];
        final sub = svc.accountsStream.listen(emitted.add);

        final created = await svc.createAccount(
          AccountCreate(name: 'Seed', type: AccountType.BANK, currency: 'ETB'),
        );
        expect(created.id, '42');

        // Act: delete
        await svc.deleteAccount('42');

        // Wait for stream emission
        await Future<void>.delayed(Duration.zero);
        final last =
            emitted.isNotEmpty ? emitted.last : await svc.accountsStream.first;
        expect(
          last.any((a) => a.id == '42'),
          false,
          reason: 'deleted account should be removed from cache',
        );

        await sub.cancel();
      },
    );

    test(
      'deleteAccount - 400 returns CannotDeleteAccountWithTransactions',
      () async {
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({'detail': {}}),
          ),
        );

        final svc = container.read(accountServiceProvider);

        await expectLater(
          svc.deleteAccount('1'),
          throwsA(isA<CannotDeleteAccountWithTransactions>()),
        );

        verify(() => mockNetwork.send(any())).called(1);
      },
    );

    test(
      'concurrent getUserAccounts calls lead to multiple network calls but no crash',
      () async {
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');

        when(() => mockNetwork.send(any())).thenAnswer((_) async {
          final body = jsonEncode({
            'total': 1,
            'accounts': [fakeAccountJson(id: 7)],
          });
          return ResponseModel(statusCode: 200, headers: {}, body: body);
        });
        final svc = container.read(accountServiceProvider);

        // Call twice concurrently
        await Future.wait([svc.getUserAccounts(), svc.getUserAccounts()]);

        // network should have been called at least twice
        verify(() => mockNetwork.send(any())).called(greaterThanOrEqualTo(2));
      },
    );

    test(
      'token missing -> still attempts network call but response handling occurs',
      () async {
        // token null
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => null);

        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async =>
              ResponseModel(statusCode: 401, headers: {}, body: jsonEncode({})),
        );

        final svc = container.read(accountServiceProvider);
        await expectLater(
          svc.getUserAccounts(),
          throwsA(isA<CouldnotFetchAccounts>()),
        );

        verify(() => mockStorage.readString(key: 'access_token')).called(1);
        verify(() => mockNetwork.send(any())).called(1);
      },
    );
  });
}
