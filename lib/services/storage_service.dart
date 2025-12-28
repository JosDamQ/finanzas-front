import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print("DEBUG: Storage read error for key '$key': $e");
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print("DEBUG: Storage write success for key '$key'");
    } catch (e) {
      print("DEBUG: Storage write error for key '$key': $e");
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      print("DEBUG: Storage delete success for key '$key'");
    } catch (e) {
      print("DEBUG: Storage delete error for key '$key': $e");
    }
  }

  static Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      print("DEBUG: Storage readAll error: $e");
      return {};
    }
  }
}
