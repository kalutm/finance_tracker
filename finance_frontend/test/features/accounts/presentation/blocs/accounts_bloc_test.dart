import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_event.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAccountService mockAccount;

  setUp(() {
    mockAccount = MockAccountService();
  });

  AccountsBloc createBloc() {
    final container = ProviderContainer(
      overrides: [accountServiceProvider.overrideWithValue(mockAccount)],
    );
    return container.read(accountsBlocProvider);
  }

  blocTest<AccountsBloc, AccountsState>(
    'emits loaded accounts',
    build: () {
      when(() => mockAccount.getUserAccounts()).thenAnswer(
        (_) async => [
          Account(
            id: "1",
            name: 'Cash',
            balance: '50',
            type: AccountType.CASH,
            currency: 'ETB',
            active: true,
            createdAt: DateTime.now(),
          ),
        ],
      );

      return createBloc();
    },
    act: (bloc) => bloc.add(LoadAccounts()),
    expect: () => [isA<AccountsLoading>(), isA<AccountsLoaded>()],
  );
}
