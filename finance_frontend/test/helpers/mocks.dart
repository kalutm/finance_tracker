import 'package:finance_frontend/core/network/network_client.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'package:finance_frontend/features/transactions/domain/data_source/trans_data_source.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockSecureStorageService extends Mock
    implements SecureStorageService {}

class MockNetworkClient extends Mock
    implements NetworkClient {}

class MockHttpClient extends Mock
    implements http.Client {}

class MockAccountService extends Mock
    implements AccountService {}

class MockCategoryService extends Mock
    implements CategoryService {}

class MockTransactionService extends Mock
    implements TransactionService {}

class MockTransDataSource extends Mock
    implements TransDataSource {}
