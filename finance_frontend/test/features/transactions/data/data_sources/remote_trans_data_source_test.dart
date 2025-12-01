import 'dart:convert';

import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_container.dart';
import '../../../../helpers/transactions/create_fake_transaction.dart';
import '../../../../helpers/transactions/create_fake_transaction_create.dart';
import '../../../../helpers/transactions/create_fake_transfer_transaction_create.dart';
import '../../../../helpers/transactions/transaction_error_scenario.dart';

void main() {
  late MockSecureStorageService mockStorage;
  late MockNetworkClient mockNetwork;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      RequestModel(
        method: 'GET',
        url: Uri.parse('http://fake.com/transactions'),
      ),
    );
  });

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockNetwork = MockNetworkClient();

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

  group("RemoteTransDataSource - detailed test for all method's under it", () {
    group("tests for createTransaction", () {
      test("createTransaction - success - return's transaction", () async {
        // Arrange
        when(
          () => mockStorage.readString(key: "access_token"),
        ).thenAnswer((_) async => "fake_acc");
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 201,
            headers: {},
            body: jsonEncode(fakeTransactionJson(id: 1)),
          ),
        );

        // Act
        final transDs = container.read(transDataSourceProvider);
        final created = await transDs.createTransaction(
          fakeTransactionCreate(),
        );

        // Assert
        expect(created.id, "1");
        // verify the dependencies method's have been called with proper input's
        verify(() => mockStorage.readString(key: "access_token")).called(1);
        verify(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>()
                  .having((r) => r.method, "RestApi method", "POST")
                  .having(
                    (r) => r.url.toString(),
                    "transaction's url",
                    contains("/transactions"),
                  ),
            ),
          ),
        );

        verifyNoMoreInteractions(mockStorage);
        verifyNoMoreInteractions(mockNetwork);
      });

      /// create transaction error test's
      final scenarios = [
        TransactionErrorScenario(
          statusCode: 400,
          code: "INVALID_AMOUNT",
          expectedException: InvalidInputtedAmount,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "INSUFFICIENT_BALANCE",
          expectedException: AccountBalanceTnsufficient,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "Error",
          expectedException: CouldnotCreateTransaction,
        ),
      ];

      for (TransactionErrorScenario s in scenarios) {
        test(
          "createTransaction - non 201 :${s.code} - throws ${s.expectedException.toString()}",
          () async {
            // Arrange
            when(
              () => mockStorage.readString(key: "access_token"),
            ).thenAnswer((_) async => "fake_acc");
            when(() => mockNetwork.send(any())).thenAnswer(
              (_) async => ResponseModel(
                statusCode: s.statusCode,
                headers: {},
                body: jsonEncode({
                  "detail": {"code": s.code},
                }),
              ),
            );

            final transDs = container.read(transDataSourceProvider);

            Object typeMatcher;
            typeMatcher = isA<CouldnotCreateTransaction>();
            if (s.expectedException == InvalidInputtedAmount) {
              typeMatcher = isA<InvalidInputtedAmount>();
            }
            if (s.expectedException == AccountBalanceTnsufficient) {
              typeMatcher = isA<AccountBalanceTnsufficient>();
            }

            // Act & Assert
            expect(
              () => transDs.createTransaction(fakeTransactionCreate()),
              throwsA(typeMatcher),
            );
          },
        );
      }
    });

    group("tests for createTransferTransaction", () {
      test(
        "createTransferTransaction - success - return's the two transaction's",
        () async {
          // Arrange
          when(
            () => mockStorage.readString(key: "access_token"),
          ).thenAnswer((_) async => "fake_acc");
          when(() => mockNetwork.send(any())).thenAnswer(
            (_) async => ResponseModel(
              statusCode: 201,
              headers: {},
              body: jsonEncode({
                "outgoing_transaction": fakeTransactionJson(
                  id: 1,
                  accountId: 1,
                  transferGroupId: "fake_transfer_id",
                  type: TransactionType.TRANSFER,
                  isOutGoing: true,
                ),
                "incoming_transaction": fakeTransactionJson(
                  id: 2,
                  accountId: 2,
                  transferGroupId: "fake_transfer_id",
                  type: TransactionType.TRANSFER,
                  isOutGoing: false,
                ),
              }),
            ),
          );

          // Act
          final transDs = container.read(transDataSourceProvider);
          final (outgoing, incoming) = await transDs.createTransferTransaction(
            fakeTransferTransactionCreate(),
          );

          // Assert
          expect(outgoing.id, "1");
          expect(incoming.id, "2");
          expect(outgoing.isOutGoing, true);
          expect(incoming.isOutGoing, false);
          expect(outgoing.accountId, "1");
          expect(incoming.accountId, "2");
          expect(outgoing.transferGroupId, "fake_transfer_id");
          expect(incoming.transferGroupId, "fake_transfer_id");

          // verify the dependencies method's have been called with proper input's
          verify(() => mockStorage.readString(key: "access_token")).called(1);
          verify(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>()
                    .having((r) => r.method, "RestApi method", "POST")
                    .having(
                      (r) => r.url.toString(),
                      "transfer transaction's url",
                      contains("/transfer"),
                    ),
              ),
            ),
          );

          verifyNoMoreInteractions(mockStorage);
          verifyNoMoreInteractions(mockNetwork);
        },
      );

      /// create transaction error test's
      final scenarios = [
        TransactionErrorScenario(
          statusCode: 400,
          code: "INVALID_AMOUNT",
          expectedException: InvalidInputtedAmount,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "INSUFFICIENT_BALANCE",
          expectedException: AccountBalanceTnsufficient,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "Error",
          expectedException: CouldnotCreateTransferTransaction,
        ),
      ];

      for (TransactionErrorScenario s in scenarios) {
        test(
          "createTransferTransaction - non 201 :${s.code} - throws ${s.expectedException.toString()}",
          () async {
            // Arrange
            when(
              () => mockStorage.readString(key: "access_token"),
            ).thenAnswer((_) async => "fake_acc");
            when(() => mockNetwork.send(any())).thenAnswer(
              (_) async => ResponseModel(
                statusCode: s.statusCode,
                headers: {},
                body: jsonEncode({
                  "detail": {"code": s.code},
                }),
              ),
            );

            final transDs = container.read(transDataSourceProvider);

            Object typeMatcher;
            typeMatcher = isA<CouldnotCreateTransferTransaction>();
            if (s.expectedException == InvalidInputtedAmount) {
              typeMatcher = isA<InvalidInputtedAmount>();
            }
            if (s.expectedException == AccountBalanceTnsufficient) {
              typeMatcher = isA<AccountBalanceTnsufficient>();
            }

            // Act & Assert
            expect(
              () => transDs.createTransferTransaction(
                fakeTransferTransactionCreate(),
              ),
              throwsA(typeMatcher),
            );
          },
        );
      }
    });

    group("tests for delete Transaction", () {
      test(
        "deleteTransaction - success - call's appiropirate mehtod's",
        () async {
          // Arrange
          when(
            () => mockStorage.readString(key: "access_token"),
          ).thenAnswer((_) async => "fake_acc");
          when(() => mockNetwork.send(any())).thenAnswer(
            (_) async => ResponseModel(
              statusCode: 204,
              headers: {},
              body: jsonEncode({}),
            ),
          );

          // Act
          final transDs = container.read(transDataSourceProvider);
          final id = "to_be_deleted_id";
          await transDs.deleteTransaction(id);

          // Assert
          // verify the dependencies method's have been called with proper input's
          verify(() => mockStorage.readString(key: "access_token")).called(1);
          verify(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>()
                    .having((r) => r.method, "RestApi method", "DELETE")
                    .having(
                      (r) => r.url.toString(),
                      "delete transaction's url",
                      contains("/transactions/$id"),
                    ),
              ),
            ),
          );

          verifyNoMoreInteractions(mockStorage);
          verifyNoMoreInteractions(mockNetwork);
        },
      );

      /// create transaction error test's
      final scenarios = [
        TransactionErrorScenario(
          statusCode: 400,
          code: "INSUFFICIENT_BALANCE",
          expectedException: AccountBalanceTnsufficient,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "Error",
          expectedException: CouldnotDeleteTransaction,
        ),
      ];

      for (TransactionErrorScenario s in scenarios) {
        test(
          "deleteTransaction - non 204 :${s.code} - throws ${s.expectedException.toString()}",
          () async {
            // Arrange
            when(
              () => mockStorage.readString(key: "access_token"),
            ).thenAnswer((_) async => "fake_acc");
            when(() => mockNetwork.send(any())).thenAnswer(
              (_) async => ResponseModel(
                statusCode: s.statusCode,
                headers: {},
                body: jsonEncode({
                  "detail": {"code": s.code},
                }),
              ),
            );

            final transDs = container.read(transDataSourceProvider);

            Object typeMatcher;
            typeMatcher = isA<CouldnotDeleteTransaction>();
            if (s.expectedException == AccountBalanceTnsufficient) {
              typeMatcher = isA<AccountBalanceTnsufficient>();
            }

            // Act & Assert
            expect(
              () => transDs.deleteTransaction("to_be_deleted_id"),
              throwsA(typeMatcher),
            );
          },
        );
      }
    });

    group("tests for deleteTransferTransaction", () {
      test(
        "deleteTransferTransaction - success - call's appropirate method's",
        () async {
          // Arrange
          when(
            () => mockStorage.readString(key: "access_token"),
          ).thenAnswer((_) async => "fake_acc");
          when(() => mockNetwork.send(any())).thenAnswer(
            (_) async => ResponseModel(
              statusCode: 204,
              headers: {},
              body: jsonEncode({}),
            ),
          );

          // Act
          final transDs = container.read(transDataSourceProvider);
          final transferGroupId = "to_be_deleted_trans_id";
          await transDs.deleteTransferTransaction(transferGroupId);

          // Assert
          // verify the dependencies method's have been called with proper input's
          verify(() => mockStorage.readString(key: "access_token")).called(1);
          verify(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>()
                    .having((r) => r.method, "RestApi method", "DELETE")
                    .having(
                      (r) => r.url.toString(),
                      "delete transfer transaction's url",
                      contains("/transfer/$transferGroupId"),
                    ),
              ),
            ),
          );

          verifyNoMoreInteractions(mockStorage);
          verifyNoMoreInteractions(mockNetwork);
        },
      );

      /// create transaction error test's
      final scenarios = [
        TransactionErrorScenario(
          statusCode: 400,
          code: "INVALID_TRANSFER_TRANSACTION",
          expectedException: InvalidTransferTransaction,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "INSUFFICIENT_BALANCE",
          expectedException: AccountBalanceTnsufficient,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "Error",
          expectedException: CouldnotDeleteTransferTransaction,
        ),
      ];

      for (TransactionErrorScenario s in scenarios) {
        test(
          "createTransferTransaction - non 204 :${s.code} - throws ${s.expectedException.toString()}",
          () async {
            // Arrange
            when(
              () => mockStorage.readString(key: "access_token"),
            ).thenAnswer((_) async => "fake_acc");
            when(() => mockNetwork.send(any())).thenAnswer(
              (_) async => ResponseModel(
                statusCode: s.statusCode,
                headers: {},
                body: jsonEncode({
                  "detail": {"code": s.code},
                }),
              ),
            );

            final transDs = container.read(transDataSourceProvider);

            Object typeMatcher;
            typeMatcher = isA<CouldnotDeleteTransferTransaction>();
            if (s.expectedException == InvalidTransferTransaction) {
              typeMatcher = isA<InvalidTransferTransaction>();
            }
            if (s.expectedException == AccountBalanceTnsufficient) {
              typeMatcher = isA<AccountBalanceTnsufficient>();
            }

            // Act & Assert
            expect(
              () => transDs.deleteTransferTransaction("to_be_deleted_trans_id"),
              throwsA(typeMatcher),
            );
          },
        );
      }
    });

    group("tests for getTransaction & getUserTransactions", () {
      test("getTransaction - success - return's transaction", () async {
        // Arrange
        when(
          () => mockStorage.readString(key: "access_token"),
        ).thenAnswer((_) async => "fake_acc");
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode(fakeTransactionJson(id: 1)),
          ),
        );

        // Act
        final transDs = container.read(transDataSourceProvider);
        final id = "1";
        final trans = await transDs.getTransaction(id);

        // Assert
        expect(trans.id, "1");
        // verify the dependencies method's have been called with proper input's
        verify(() => mockStorage.readString(key: "access_token")).called(1);
        verify(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>()
                  .having((r) => r.method, "RestApi method", "GET")
                  .having(
                    (r) => r.url.toString(),
                    "get transaction url",
                    contains("/transactions/$id"),
                  ),
            ),
          ),
        );

        verifyNoMoreInteractions(mockStorage);
        verifyNoMoreInteractions(mockNetwork);
      });

      test("getTransaction - non 200 - throws", () async {
        // Arrange
        when(
          () => mockStorage.readString(key: "access_token"),
        ).thenAnswer((_) async => "fake_acc");
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "Error"}),
          ),
        );

        final transDs = container.read(transDataSourceProvider);

        // Act & Assert
        expect(
          () => transDs.getTransaction("1"),
          throwsA(isA<CouldnotGetTransaction>()),
        );
      });

      test("getUserTransactions - success - return's transaction's", () async {
        // Arrange
        final body = {
          "total": 3,
          "transactions": [
            fakeTransactionJson(id: 1),
            fakeTransactionJson(id: 2),
            fakeTransactionJson(id: 3),
          ],
        };
        when(
          () => mockStorage.readString(key: "access_token"),
        ).thenAnswer((_) async => "fake_acc");
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode(body),
          ),
        );

        // Act
        final transDs = container.read(transDataSourceProvider);
        final transactions = await transDs.getUserTransactions();

        // Assert
        expect(transactions, isNotEmpty);
        expect(transactions.length, 3);
        expect(transactions.any((t) => t.id == "1"), true);
        // verify the dependencies method's have been called with proper input's
        verify(() => mockStorage.readString(key: "access_token")).called(1);
        verify(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>()
                  .having((r) => r.method, "RestApi method", "GET")
                  .having(
                    (r) => r.url.toString(),
                    "get transaction's url",
                    contains("/transactions"),
                  ),
            ),
          ),
        );

        verifyNoMoreInteractions(mockStorage);
        verifyNoMoreInteractions(mockNetwork);
      });

      test("getUserTransaction's - non 200 - throws", () async {
        // Arrange
        when(
          () => mockStorage.readString(key: "access_token"),
        ).thenAnswer((_) async => "fake_acc");
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({"detail": "Error"}),
          ),
        );

        final transDs = container.read(transDataSourceProvider);

        // Act & Assert
        expect(
          () => transDs.getUserTransactions(),
          throwsA(isA<CouldnotFetchTransactions>()),
        );
      });
    });

    group("tests for updateTransaction", () {
      test(
        "updateTransaction - success - return's the updated transaction",
        () async {
          // Arrange
          when(
            () => mockStorage.readString(key: "access_token"),
          ).thenAnswer((_) async => "fake_acc");
          when(() => mockNetwork.send(any())).thenAnswer(
            (_) async => ResponseModel(
              statusCode: 200,
              headers: {},
              body: jsonEncode(fakeTransactionJson(id: 1)),
            ),
          );

          // Act
          final transDs = container.read(transDataSourceProvider);
          final id = "1";
          final updated = await transDs.updateTransaction(
            id,
            TransactionPatch(),
          );

          // Assert
          expect(updated.id, "1");
          // verify the dependencies method's have been called with proper input's
          verify(() => mockStorage.readString(key: "access_token")).called(1);
          verify(
            () => mockNetwork.send(
              any(
                that: isA<RequestModel>()
                    .having((r) => r.method, "RestApi method", "PATCH")
                    .having(
                      (r) => r.url.toString(),
                      "update transaction url",
                      contains("/transactions/$id"),
                    ),
              ),
            ),
          );

          verifyNoMoreInteractions(mockStorage);
          verifyNoMoreInteractions(mockNetwork);
        },
      );

      /// create transaction error test's
      final scenarios = [
        TransactionErrorScenario(
          statusCode: 400,
          code: "INVALID_AMOUNT",
          expectedException: InvalidInputtedAmount,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "INSUFFICIENT_BALANCE",
          expectedException: AccountBalanceTnsufficient,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "CANNOT_UPDATE_TRANSACTION",
          expectedException: CannotUpdateTransferTransactions,
        ),
        TransactionErrorScenario(
          statusCode: 400,
          code: "Error",
          expectedException: CouldnotUpdateTransaction,
        ),
      ];

      for (TransactionErrorScenario s in scenarios) {
        test(
          "createTransaction - non 200 :${s.code} - throws ${s.expectedException.toString()}",
          () async {
            // Arrange
            when(
              () => mockStorage.readString(key: "access_token"),
            ).thenAnswer((_) async => "fake_acc");
            when(() => mockNetwork.send(any())).thenAnswer(
              (_) async => ResponseModel(
                statusCode: s.statusCode,
                headers: {},
                body: jsonEncode({
                  "detail": {"code": s.code},
                }),
              ),
            );

            final transDs = container.read(transDataSourceProvider);

            Object typeMatcher;
            typeMatcher = isA<CouldnotUpdateTransaction>();
            if (s.expectedException == InvalidInputtedAmount) {
              typeMatcher = isA<InvalidInputtedAmount>();
            }
            if (s.expectedException == AccountBalanceTnsufficient) {
              typeMatcher = isA<AccountBalanceTnsufficient>();
            }
            if (s.expectedException == CannotUpdateTransferTransactions){
              typeMatcher = isA<CannotUpdateTransferTransactions>();
            }

            // Act & Assert
            expect(
              () => transDs.updateTransaction("1", TransactionPatch()),
              throwsA(typeMatcher),
            );
          },
        );
      }
    });
  });
}
