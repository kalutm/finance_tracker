import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceSecureStorageService implements SecureStorageService {
  static final FinanceSecureStorageService _instance = FinanceSecureStorageService._internal();

  factory FinanceSecureStorageService() {
    return _instance;
  }

  FinanceSecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> saveString({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> readString({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> deleteString({required String key}) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
}
