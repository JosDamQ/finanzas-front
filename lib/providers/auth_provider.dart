import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../services/http_service.dart';

class AuthProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      try {
        final response = await _httpService.client.get('/users/profile');
        if (response.data['success']) {
          _user = response.data['data'];
          _isAuthenticated = true;
        } else {
          _isAuthenticated = false;
          await _storage.delete(key: 'jwt_token');
        }
      } catch (e) {
        _isAuthenticated = false;
        await _storage.delete(key: 'jwt_token');
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _httpService.client.post(
        '/users/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['success']) {
        final token = response.data['data']['token'];
        final userData = response.data['data']['user'];

        await _storage.write(key: 'jwt_token', value: token);
        _user = userData;
        _isAuthenticated = true;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String phone,
    String birthdate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _httpService.client.post(
        '/users/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': int.tryParse(phone.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          'birthdate': birthdate,
        },
      );

      if (response.data['success']) {
        // Auto login or just return success
        // Let's perform auto-login for better UX
        await login(email, password);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
