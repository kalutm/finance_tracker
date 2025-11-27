import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// abstractions & implementations
import 'package:finance_frontend/core/network/network_client.dart'; // NetworkClient
import 'package:finance_frontend/core/network/http_network_client.dart'; // HttpNetworkClient

import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart'; // SecureStorageService
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart'; // FinanceSecureStorageService

import 'package:finance_frontend/features/settings/domain/services/shared_preferences_service.dart'; // SharedPreferencesService
import 'package:finance_frontend/features/settings/data/services/finance_shared_preferences_service.dart'; // FinanceSharedPreferencesService

import 'package:finance_frontend/features/auth/domain/services/auth_service.dart'; // AuthService
import 'package:finance_frontend/features/auth/data/services/finance_auth_service.dart'; // FinanceAuthService

import 'package:finance_frontend/features/accounts/domain/service/account_service.dart'; // AccountService
import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart'; // FinanceAccountService

import 'package:finance_frontend/features/categories/domain/service/category_service.dart'; // CategoryService
import 'package:finance_frontend/features/categories/data/services/finance_category_service.dart'; // FinanceCategoryService

import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart'; // TransactionService
import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart'; // FinanceTransactionService

import 'package:finance_frontend/features/transactions/domain/data_source/trans_data_source.dart'; // TransDataSource
import 'package:finance_frontend/features/transactions/data/data_sources/remote_trans_data_source.dart'; // RemoteTransDataSource

// Blocs / Cubits
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart'; // AuthCubit
import 'package:finance_frontend/features/settings/presentation/cubits/settings_cubit.dart'; // SettingsCubit
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart'; // AccountsBloc
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart'; // AccountFormBloc
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart'; // CategoriesBloc
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_bloc.dart'; // CategoryFormBloc
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_bloc.dart'; // TransactionsBloc
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_bloc.dart'; // TransactionFormBloc

/// Low level / core providers ///

/// Rest Api base Url provider
final baseUrlProvider = Provider<String>((ref) {
  return dotenv.env["API_BASE_URL_MOBILE"]!;
});

/// http.Client provider
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferencesService>((ref) {
  return FinanceSharedPreferencesService();
});

/// Secure storage provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return FinanceSecureStorageService();
});

/// NetworkClient abstraction
final networkClientProvider = Provider<NetworkClient>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return HttpNetworkClient(httpClient);
});

/// Services & DataSources  ///

/// AccountService exposed as AccountService (interface)
final accountServiceProvider = Provider<AccountService>((ref) {
  return FinanceAccountService(
    secureStorageService: ref.read(secureStorageProvider),
    client: ref.read(networkClientProvider),
    baseUrl: ref.read(baseUrlProvider),
  );
});

/// CategoryService exposed as CategoryService (interface)
final categoryServiceProvider = Provider<CategoryService>((ref) {
  return FinanceCategoryService(
    secureStorageService: ref.read(secureStorageProvider),
    client: ref.read(networkClientProvider),
    baseUrl: ref.read(baseUrlProvider),
  );
});

/// TransDataSource (remote) exposed as TransDataSource (interface)
final transDataSourceProvider = Provider<TransDataSource>((ref) {
  return RemoteTransDataSource(
   secureStorageService: ref.read(secureStorageProvider),
   client: ref.read(networkClientProvider),
   baseUrl: ref.read(baseUrlProvider),
  );
});

/// TransactionService exposed as TransactionService (interface)
final transactionServiceProvider = Provider<TransactionService>((ref) {
  // Note: depends on AccountService (interface) and TransDataSource (interface)
  return FinanceTransactionService(
    ref.read(accountServiceProvider),
    ref.read(transDataSourceProvider),
  );
});

/// AuthService exposed as AuthService (interface)
final authServiceProvider = Provider<AuthService>((ref) {
  return FinanceAuthService(
    secureStorageService: ref.read(secureStorageProvider),
    client: ref.read(networkClientProvider),
    accountService: ref.read(accountServiceProvider),
    categoryService: ref.read(categoryServiceProvider),
    transactionService: ref.read(transactionServiceProvider),
    baseUrl: ref.read(baseUrlProvider),
  );
});

/// Blocs / Cubits ///

/// AuthCubit
final authCubitProvider = Provider<AuthCubit>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthCubit(service);
});

/// SettingsCubit
final settingsCubitProvider = Provider<SettingsCubit>((ref) {
  final service = ref.read(sharedPreferencesProvider);
  return SettingsCubit(service);
});

/// AccountsBloc
final accountsBlocProvider = Provider<AccountsBloc>((ref) {
  final service = ref.read(accountServiceProvider);
  return AccountsBloc(service);
});

/// AccountFormBloc
final accountFormBlocProvider = Provider<AccountFormBloc>((ref) {
  final service = ref.read(accountServiceProvider);
  return AccountFormBloc(service);
});

/// CategoriesBloc
final categoriesBlocProvider = Provider<CategoriesBloc>((ref) {
  final service = ref.read(categoryServiceProvider);
  return CategoriesBloc(service);
});

/// CategoryFormBloc
final categoryFormBlocProvider = Provider<CategoryFormBloc>((ref) {
  final service = ref.read(categoryServiceProvider);
  return CategoryFormBloc(service);
});

/// TransactionsBloc
final transactionsBlocProvider = Provider<TransactionsBloc>((ref) {
  final service = ref.read(transactionServiceProvider);
  return TransactionsBloc(service);
});

/// TransactionFormBloc
final transactionFormBlocProvider = Provider<TransactionFormBloc>((ref) {
  final service = ref.read(transactionServiceProvider);
  return TransactionFormBloc(service);
});
