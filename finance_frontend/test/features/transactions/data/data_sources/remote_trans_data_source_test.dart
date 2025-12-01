import 'dart:convert';

import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_container.dart';
import '../../../../helpers/transactions/create_fake_transaction.dart';
import '../../../../helpers/transactions/create_fake_transaction_create.dart';
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
          "createTransaction - non 200 :${s.code} - throws ${s.expectedException.runtimeType.toString()}",
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

    


  });
}
