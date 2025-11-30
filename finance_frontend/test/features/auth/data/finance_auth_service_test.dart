import 'dart:convert';

import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/auth/domain/entities/sign_in_account.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import '../../../helpers/auth/create_fake_auth_user.dart';
import '../../../helpers/auth/token_scenario.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_container.dart';

void main() {
  late MockSecureStorageService mockStorage;
  late MockTokenDecoderService mockDecoder;
  late MockNetworkClient mockNetwork;
  late MockSignInWithService mockSignInWith;
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
    mockDecoder = MockTokenDecoderService();
    mockNetwork = MockNetworkClient();
    mockSignInWith = MockSignInWithService();
    mockAccountService = MockAccountService();
    mockCategoryService = MockCategoryService();
    mockTransactionService = MockTransactionService();

    container = createTestContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        tokenDecoderServiceProvider.overrideWithValue(mockDecoder),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue('http://fake.com'),
        clientServerIdProvider.overrideWithValue('id'),
        signInWithServiceProvider.overrideWithValue(mockSignInWith),
        accountServiceProvider.overrideWithValue(mockAccountService),
        categoryServiceProvider.overrideWithValue(mockCategoryService),
        transactionServiceProvider.overrideWithValue(mockTransactionService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    reset(mockNetwork);
    reset(mockStorage);
  });

  group("FinanceAuthService - detailed test for all method's under it", () {
    group(
      "Test For getUserCridential's all other's depend on this - crucial to test first",
      () {
        test('getUserCridentials - success - returns user', () async {
          // Arrange
          when(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>().having(
                  (r) => r.url.toString(),
                  "get me url",
                  contains("/me"),
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

          // Act
          final authService = container.read(authServiceProvider);
          final user = await authService.getUserCridentials("fake_access");

          // Assert
          expect(user.uid, '1');
        });

        test("getUserCridentials - non 200 - throw's ", () async {
          // Arrange
          when(() => mockNetwork.send(any())).thenAnswer(
            (_) async => ResponseModel(
              statusCode: 400,
              headers: {},
              body: jsonEncode({"detail": "error"}),
            ),
          );
          final authService = container.read(authServiceProvider);

          // Act & Assert
          expect(
            () => authService.getUserCridentials("fake_access"),
            throwsA(isA<CouldnotGetUser>()),
          );
        });
      },
    );

    group('FinanceAuthService - UserStatus and token managment', () {
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
          refreshToken: "R",
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
        test(
          "token scenario: acc: ${s.accessToken}, ref: ${s.refreshToken}, acc_exp: ${s.isAccessExpired}, ref_exp: ${s.isRefreshExpired}, return_user: ${s.returnsUser}",
          () async {
            // Arrange
            when(
              () => mockStorage.readString(key: "access_token"),
            ).thenAnswer((_) async => s.accessToken);
            when(
              () => mockStorage.readString(key: "refresh_token"),
            ).thenAnswer((_) async => s.refreshToken);
            when(
              () => mockStorage.saveString(
                key: "access_token",
                value: "NEW_ACCESS",
              ),
            ).thenAnswer((_) async {});
            when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

            final authService = container.read(authServiceProvider);

            // Mock token expiry check
            when(
              () => mockDecoder.isExpired("A"),
            ).thenReturn(s.isAccessExpired);
            when(
              () => mockDecoder.isExpired("R"),
            ).thenReturn(s.isRefreshExpired);

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

            // mock getUserCridentials and verify correct url was used
            if (s.returnsUser) {
              when(
                () => mockNetwork.send(
                  any(
                    that: isA<RequestModel>()
                        .having((r) => r.method, "Rest method", "GET")
                        .having(
                          (r) => r.url.toString(),
                          "get me url",
                          contains("/me"),
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
                expect(user!.uid, "1");
              } else {
                expect(user, isNull);
              }
            }
          },
        );
      }
    });

    group("FinanceAuthService - login and register", () {
      test("login with google - success - return's user", () async {
        // Arrange
        when(
          () => mockStorage.saveString(key: "access_token", value: "fake_acc"),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.saveString(key: "refresh_token", value: "fake_ref"),
        ).thenAnswer((_) async {});

        // mock getUserCridentials
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

        // mock google sign in's idToken
        when(() => mockSignInWith.getAccount()).thenAnswer(
          (_) async =>
              SignInAccount(email: "foo@max.com", idToken: "fake_id_token"),
        );
        when(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>().having(
                (r) => r.url.toString(),
                "login with google url",
                contains("login/google"),
              ),
            ),
          ),
        ).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode({"acc_jwt": "fake_acc", "ref_jwt": "fake_ref"}),
          ),
        );

        // Act
        final authService = container.read(authServiceProvider);
        final user = await authService.loginWithGoogle();

        // Assert
        expect(user!.uid, "1");
        // verify that the token's are stored
        verify(
          () => mockStorage.saveString(key: "access_token", value: "fake_acc"),
        ).called(1);
        verify(
          () => mockStorage.saveString(key: "refresh_token", value: "fake_ref"),
        ).called(1);
      });

      test("login with google - non 200 - throw's", () async {
        // Arrange

        // mock google sign in's idToken
        when(() => mockSignInWith.getAccount()).thenAnswer(
          (_) async =>
              SignInAccount(email: "foo@max.com", idToken: "fake_id_token"),
        );

        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "error"}),
          ),
        );

        // Act
        final authService = container.read(authServiceProvider);
        final user = authService.loginWithGoogle();

        // Assert
        expect(() => user, throwsA(isA<CouldnotLogInWithGoogle>()));
      });

      test("login with email and password - success - return's user", () async {
        // Arrange
        when(
          () =>
              mockStorage.saveString(key: "access_token", value: "fake_access"),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.saveString(key: "refresh_token", value: "fake_ref"),
        ).thenAnswer((_) async {});

        // mock getUserCridentials
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

        when(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>()
                  .having((r) => r.method, "Rest method", "POST")
                  .having(
                    (r) => r.url.toString(),
                    "login url",
                    contains("/login"),
                  ),
            ),
          ),
        ).thenAnswer((_) async {
          return ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode({'acc_jwt': 'fake_access', 'ref_jwt': 'fake_ref'}),
          );
        });

        // Act
        final authService = container.read(authServiceProvider);
        final user = await authService.loginWithEmailAndPassword(
          "foo@max.com",
          "foobarbaz",
        );

        // Assert
        expect(user.uid, '1');
        // verify that the token's are stored
        verify(
          () =>
              mockStorage.saveString(key: "access_token", value: "fake_access"),
        ).called(1);
        verify(
          () => mockStorage.saveString(key: "refresh_token", value: "fake_ref"),
        ).called(1);
      });

      test("login with email and password - non 200 - throws", () async {
        // Arrange
        when(() => mockNetwork.send(any())).thenAnswer(
          (invocation) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "error"}),
          ),
        );

        // Act
        final authService = container.read(authServiceProvider);
        final user = authService.loginWithEmailAndPassword(
          "foo@max.com",
          "foobarbaz",
        );

        // Assert
        expect(() => user, throwsA(isA<CouldnotLogIn>()));
      });

      test(
        "register with email and password - success - return's user",
        () async {
          // Arrange
          when(
            () => mockStorage.saveString(
              key: "access_token",
              value: "fake_access",
            ),
          ).thenAnswer((_) async {});
          when(
            () =>
                mockStorage.saveString(key: "refresh_token", value: "fake_ref"),
          ).thenAnswer((_) async {});

          // mock getUserCridentials
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

          when(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>()
                    .having((r) => r.method, "Rest method", "POST")
                    .having(
                      (r) => r.url.toString(),
                      "register url",
                      contains("/register"),
                    ),
              ),
            ),
          ).thenAnswer((_) async {
            return ResponseModel(
              statusCode: 200,
              headers: {},
              body: jsonEncode({
                'acc_jwt': 'fake_access',
                'ref_jwt': 'fake_ref',
              }),
            );
          });

          // Act
          final authService = container.read(authServiceProvider);
          final user = await authService.registerWithEmailAndPassword(
            "foo@max.com",
            "foobarbaz",
          );

          // Assert

          expect(user.uid, '1');
          // verify that the token's are stored
          verify(
            () => mockStorage.saveString(
              key: "access_token",
              value: "fake_access",
            ),
          ).called(1);
          verify(
            () =>
                mockStorage.saveString(key: "refresh_token", value: "fake_ref"),
          ).called(1);
        },
      );

      test("register with email and password - non 200 - throws", () async {
        // Arrange
        when(() => mockNetwork.send(any())).thenAnswer(
          (invocation) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "error"}),
          ),
        );

        // Act
        final authService = container.read(authServiceProvider);
        final user = authService.loginWithEmailAndPassword(
          "foo@max.com",
          "foobarbaz",
        );

        // Assert
        expect(() => user, throwsA(isA<CouldnotLogIn>()));
      });
    });

    group("FinanceAuthService - send verificatoin, logout and delete", () {
      test("send verification - success - sends appropirate body", () async {
        // Arrange
        when(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>().having(
                (r) => r.url.toString(),
                "resend-verification url",
                contains("/resend-verification"),
              ),
            ),
          ),
        ).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 200,
            headers: {},
            body: "email verificatoin link sent successfully",
          ),
        );

        // Act
        final authService = container.read(authServiceProvider);
        await authService.sendVerificationEmail("foo@max.com");

        // nothing to Assert
      });

      test("send verification - non 200 - throws", () async {
        // Arrange
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "error"}),
          ),
        );

        final authService = container.read(authServiceProvider);

        // Act & Assert
        expect(
          () => authService.sendVerificationEmail("foo@max.com"),
          throwsA(isA<CouldnotSendEmailVerificatonLink>()),
        );
      });

      test("logout clear's cache and delete's token's", () async {
        // Arrange
        when(() => mockAccountService.clearCache()).thenAnswer((_) async {});
        when(() => mockCategoryService.clearCache()).thenAnswer((_) async {});
        when(
          () => mockTransactionService.clearCache(),
        ).thenAnswer((_) async {});

        when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

        // Act
        final authService = container.read(authServiceProvider);
        await authService.logout();

        // Assert

        // verify that the account, category and transaction's cache's are cleared
        verify(() => mockAccountService.clearCache()).called(1);
        verify(() => mockCategoryService.clearCache()).called(1);
        verify(() => mockTransactionService.clearCache()).called(1);

        // verify that the token's are deleted after a logout
        verify(() => mockStorage.deleteAll()).called(1);
      });

      test(
        "delete current user - success - call's appropirate method's",
        () async {
          // Arrange
          when(
            () => mockStorage.readString(key: "access_token"),
          ).thenAnswer((_) async => "fake_acc");
          when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
          when(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>()
                    .having((r) => r.method, "RestApi mehtod", "DELETE")
                    .having(
                      (r) => r.url.toString(),
                      "delete me url",
                      contains("/me"),
                    ),
              ),
            ),
          ).thenAnswer(
            (_) async => ResponseModel(
              statusCode: 200,
              headers: {},
              body: jsonEncode("user account deleted succesfully"),
            ),
          );

          // Act
          final authService = container.read(authServiceProvider);
          await authService.deleteCurrentUser();

          // Assert
          // verify thta the token's are deleted on deletion
          verify(() => mockStorage.deleteAll()).called(1);
        },
      );

      test("delete current user - non 200 - throwsA<CouldnotDeleteUser>", () async {
        // Arrange
        when(
          () => mockStorage.readString(key: "access_token"),
        ).thenAnswer((_) async => "fake_acc");
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "error"}),
          ),
        );
        final authService = container.read(authServiceProvider);

        // Act & Assert
        expect(
          () => authService.deleteCurrentUser(),
          throwsA(isA<CouldnotDeleteUser>()),
        );
      });

      test("delete current user - access token == null - throwsA<NoUserToDelete>", () async {
        // Arrange 
        when(() => mockStorage.readString(key: "access_token")).thenAnswer((_) async => null);
        final authService = container.read(authServiceProvider);

        // Act & Assert
        expect(() => authService.deleteCurrentUser(), throwsA(isA<NoUserToDelete>()));
      },);
    });
  });
}
