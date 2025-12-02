import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../helpers/accounts/create_fake_account_model.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_container.dart';
import '../../../../helpers/transactions/create_fake_transaction_create.dart';
import '../../../../helpers/transactions/create_fake_transaction_model.dart';
import '../../../../helpers/transactions/create_fake_transfer_transaction_create.dart';

void main() {
  late MockAccountService mockAccountService;
  late MockTransDataSource mockTransDataSource;
  late ProviderContainer container;

  setUp(() {
    mockAccountService = MockAccountService();
    mockTransDataSource = MockTransDataSource();

    container = createTestContainer(
      overrides: [
        accountServiceProvider.overrideWithValue(mockAccountService),
        transDataSourceProvider.overrideWithValue(mockTransDataSource),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    reset(mockAccountService);
    reset(mockTransDataSource);
  });

  group('FinanceTransactionService - caching and stream updating', () {
    // demo account's to return when mocking accountService.getUserAcccounts
    final accounts = [
      createFakeAccount(id: "1"),
      createFakeAccount(id: "2"),
      createFakeAccount(id: "3"),
    ];

    test(
      'getUserTransactions - success returns list and emits cache',
      () async {
        // Arrange
        final transactions = [
          fakeTransactionModel(id: "1"),
          fakeTransactionModel(id: "2"),
          fakeTransactionModel(id: "3"),
        ];
        when(
          () => mockTransDataSource.getUserTransactions(),
        ).thenAnswer((_) async => transactions);

        final svc = container.read(transactionServiceProvider);

        // subscribe to stream before triggering
        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);

        // Act
        final list = await svc.getUserTransactions();

        // Assert
        expect(list.length, 3);
        await Future<void>.delayed(Duration.zero);
        expect(emitted.isNotEmpty, true);
        expect(emitted.last.length, 3);

        // verify interactions
        verify(() => mockTransDataSource.getUserTransactions()).called(1);

        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );

    test(
      'createTransaction - success - returns created and updates stream & cache',
      () async {
        final create = fakeTransactionCreate();

        when(
          () => mockTransDataSource.createTransaction(create),
        ).thenAnswer((_) async => fakeTransactionModel(id: "1"));
        when(
          () => mockAccountService.getUserAccounts(),
        ).thenAnswer((_) async => accounts);

        final svc = container.read(transactionServiceProvider);

        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);

        final created = await svc.createTransaction(create);

        expect(created.id, '1');

        await Future<void>.delayed(Duration.zero); // allow emission
        expect(emitted.isNotEmpty, true);
        expect(emitted.last.length, 1);
        expect(emitted.last.any((a) => a.id == '1'), true);

        // verify the accountService.getUserAccounts have been called
        verify(() => mockAccountService.getUserAccounts()).called(1);

        // also verify data source call before asserting no more interactions
        verify(() => mockTransDataSource.createTransaction(create)).called(1);

        verifyNoMoreInteractions(mockAccountService);
        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );

    test(
      "createTransferTransaction - success - return's the two transaction's and updates stream & cache",
      () async {
        // Arrange
        final create = fakeTransferTransactionCreate();
        final transferGroup = "fake_transfer_group_id";
        when(
          () => mockTransDataSource.createTransferTransaction(create),
        ).thenAnswer(
          (_) async => (
            fakeTransactionModel(
              id: "1",
              accountId: "1",
              transferGroupId: transferGroup,
              type: TransactionType.TRANSFER,
              isOutGoing: true,
            ),
            fakeTransactionModel(
              id: "2",
              accountId: "2",
              transferGroupId: transferGroup,
              type: TransactionType.TRANSFER,
              isOutGoing: false,
            ),
          ),
        );
        when(
          () => mockAccountService.getUserAccounts(),
        ).thenAnswer((_) async => accounts);

        final svc = container.read(transactionServiceProvider);

        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);

        final (outgoing, incoming) = await svc.createTransferTransaction(
          create,
        );

        expect(outgoing.id, "1");
        expect(incoming.id, "2");
        expect(outgoing.isOutGoing, true);
        expect(incoming.isOutGoing, false);
        expect(outgoing.accountId, "1");
        expect(incoming.accountId, "2");
        expect(outgoing.transferGroupId, transferGroup);
        expect(incoming.transferGroupId, transferGroup);

        await Future<void>.delayed(Duration.zero); // allow emission
        expect(emitted.isNotEmpty, true);
        expect(emitted.last.length, 2);
        expect(emitted.last.any((t) => t.id == '1'), true);
        expect(
          emitted.last.any((t) => t.transferGroupId == transferGroup),
          true,
        );

        // verify the accountService.getUserAccounts have been called
        verify(() => mockAccountService.getUserAccounts()).called(1);

        // also verify data source call before asserting no more interactions
        verify(
          () => mockTransDataSource.createTransferTransaction(create),
        ).called(1);

        verifyNoMoreInteractions(mockAccountService);
        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );

    test(
      'deleteTransaction - success removes from cache and emits updated list',
      () async {
        // Arrange: seed cache with  a Transaction via createTransaction
        final create = fakeTransactionCreate();
        when(
          () => mockTransDataSource.createTransaction(create),
        ).thenAnswer((_) async => fakeTransactionModel(id: "1"));
        when(
          () => mockTransDataSource.deleteTransaction("1"),
        ).thenAnswer((_) async {});

        when(
          () => mockAccountService.getUserAccounts(),
        ).thenAnswer((_) async => accounts);
        final svc = container.read(transactionServiceProvider);

        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);

        final created = await svc.createTransaction(create);
        expect(created.id, '1');

        // Act: delete
        await svc.deleteTransaction('1');

        // Wait for stream emission
        await Future<void>.delayed(Duration.zero);
        final last = emitted.last;
        expect(
          last.any((t) => t.id == '1'),
          false,
          reason: 'deleted transaction should be removed from cache',
        );

        // verify the accountService.getUserAccounts have been called
        verify(() => mockAccountService.getUserAccounts()).called(2);

        // also verify data source call before asserting no more interactions
        verify(() => mockTransDataSource.deleteTransaction("1")).called(1);
        verify(() => mockTransDataSource.createTransaction(create)).called(1);

        verifyNoMoreInteractions(mockAccountService);
        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );

    test(
      'deleteTransferTransaction - success removes the two transaction from cache and emits updated list',
      () async {
        // Arrange: seed cache with TransferTransaction's via createTransferTransaction
        final transferGroup = "fake_transfer_group";
        final create = fakeTransferTransactionCreate();
        when(
          () => mockTransDataSource.createTransferTransaction(create),
        ).thenAnswer(
          (_) async => (
            fakeTransactionModel(
              id: "1",
              accountId: "1",
              transferGroupId: transferGroup,
              type: TransactionType.TRANSFER,
              isOutGoing: true,
            ),
            fakeTransactionModel(
              id: "2",
              accountId: "2",
              transferGroupId: transferGroup,
              type: TransactionType.TRANSFER,
              isOutGoing: false,
            ),
          ),
        );
        when(
          () => mockTransDataSource.deleteTransferTransaction(transferGroup),
        ).thenAnswer((_) async {});

        when(
          () => mockAccountService.getUserAccounts(),
        ).thenAnswer((_) async => accounts);
        final svc = container.read(transactionServiceProvider);

        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);

        final (outgoing, incoming) = await svc.createTransferTransaction(
          create,
        );
        expect(outgoing.id, "1");
        expect(incoming.id, "2");

        // Act: delete
        await svc.deleteTransferTransaction(transferGroup);

        // Wait for stream emission
        await Future<void>.delayed(Duration.zero);
        final last = emitted.last;
        expect(
          last.any((t) => t.transferGroupId == transferGroup),
          false,
          reason: 'deleted transfer transactions should be removed from cache',
        );

        // verify the accountService.getUserAccounts have been called
        verify(() => mockAccountService.getUserAccounts()).called(2);

        // also verify data source call before asserting no more interactions
        verify(
          () => mockTransDataSource.deleteTransferTransaction(transferGroup),
        ).called(1);

        verify(
          () => mockTransDataSource.createTransferTransaction(create),
        ).called(1);

        verifyNoMoreInteractions(mockAccountService);
        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );

    test(
      "getTransaction - success - return's transaction if in cache and will insert to if not in cache, most importantly it will update the stream",
      () async {
        // Arrange: seed cache with  a Transaction via createTransaction
        final create = fakeTransactionCreate();
        when(
          () => mockTransDataSource.createTransaction(create),
        ).thenAnswer((_) async => fakeTransactionModel(id: "1"));
        // this one is to test that getTransaction will insert the transaction if not found in the cache
        when(
          () => mockTransDataSource.getTransaction("2"),
        ).thenAnswer((_) async => fakeTransactionModel(id: "2"));

        when(
          () => mockAccountService.getUserAccounts(),
        ).thenAnswer((_) async => accounts);
        final svc = container.read(transactionServiceProvider);

        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);
        // create a transaction with id one so that it will be cached
        final created = await svc.createTransaction(create);
        expect(created.id, '1');

        // Act
        // will get returned from cache
        final cachedTrans = await svc.getTransaction('1');

        /// will get inserted to the cache since it's not initially found in the cache
        final uncachedTrans = await svc.getTransaction('2');

        expect(cachedTrans.id, "1");
        expect(uncachedTrans.id, "2");

        // Wait for stream emission
        await Future<void>.delayed(Duration.zero);
        final last = emitted.last;
        expect(emitted.last, isNotEmpty);
        expect(last.length, 2);
        expect(
          last.any((t) => t.id == "1"),
          true,
          reason:
              "transaction created via createTransaction should be in the cache",
        );
        expect(
          last.any((t) => t.id == "2"),
          true,
          reason:
              "transaction will be inserted to the cacahe via getTransaction",
        );

        // verify the accountService.getUserAccounts have been called
        // called via createTransaction
        verify(() => mockAccountService.getUserAccounts()).called(1);

        // also verify data source call before asserting no more interactions
        // the get transaction will only be called if not found in the cache so in our case it will only be called once for the transaction with id : 2
        // but for the transaction with id : 1 getTransaction won't be called since it will be inserted to the cache via createTransaction
        verify(() => mockTransDataSource.getTransaction("2")).called(1);

        verify(() => mockTransDataSource.createTransaction(create)).called(1);

        verifyNoMoreInteractions(mockAccountService);
        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );

    test(
      "updateTransaction - success - return's the updated transaction and update's the cache, insert to the cache if not found, and most importantly it emit's to the stream",
      () async {
        // Arrange: seed cache with  a Transaction via createTransaction
        final patch = TransactionPatch();
        final create = fakeTransactionCreate();
        when(
          () => mockTransDataSource.createTransaction(create),
        ).thenAnswer((_) async => fakeTransactionModel(id: "1"));
        when(
          () => mockTransDataSource.updateTransaction("1", patch),
        ).thenAnswer((_) async => fakeTransactionModel(id: "1", amount: "100"));
        // this one is to test that updateTransaction will insert the transaction in to the cache if not found
        when(
          () => mockTransDataSource.updateTransaction("2", patch),
        ).thenAnswer((_) async => fakeTransactionModel(id: "2", amount: "150"));

        when(
          () => mockAccountService.getUserAccounts(),
        ).thenAnswer((_) async => accounts);
        final svc = container.read(transactionServiceProvider);

        final emitted = <List<Transaction>>[];
        final sub = svc.transactionsStream.listen(emitted.add);

        final created = await svc.createTransaction(create);
        expect(created.id, '1');

        // Act: update
        final cachedUpdated = await svc.updateTransaction('1', patch);
        final uncachedUpdated = await svc.updateTransaction('2', patch);

        expect(cachedUpdated.id, "1");
        expect(uncachedUpdated.id, "2");

        // Wait for stream emission
        await Future<void>.delayed(Duration.zero);
        final last = emitted.last;
        expect(emitted.last, isNotEmpty);
        expect(last.length, 2);
        expect(
          last.any((t) => t.id == "2"),
          true,
          reason:
              "although not found in the cache initially update should insert it to the cache",
        );
        expect(
          last.any((t) => t.amount == '100'),
          true,
          reason: "we updated the transaction's amount to be 100",
        );
        expect(
          last.any((t) => t.amount == '50'),
          false,
          reason:
              "we updated the transaction's amount to be 100 so the old one must be overwritten",
        );

        // verify the accountService.getUserAccounts have been called
        // two for updateTransaction & one for createTransaction
        verify(() => mockAccountService.getUserAccounts()).called(3);

        // also verify data source call before asserting no more interactions
        verify(
          () => mockTransDataSource.updateTransaction("1", patch),
        ).called(1);
        verify(
          () => mockTransDataSource.updateTransaction("2", patch),
        ).called(1);
        verify(() => mockTransDataSource.createTransaction(create)).called(1);

        verifyNoMoreInteractions(mockAccountService);
        verifyNoMoreInteractions(mockTransDataSource);

        await sub.cancel();
      },
    );
  });
  
}
