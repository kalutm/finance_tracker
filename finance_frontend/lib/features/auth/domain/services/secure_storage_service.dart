abstract class SecureStorageService {
  Future<void> saveString({required String key, required String value});
  Future<String?> readString({required String key});
  Future<void> deleteString({required String key});
  Future<void> deleteAll();
}