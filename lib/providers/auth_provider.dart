import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> checkAuth({bool fromSplash = false}) async {
    print("DEBUG: checkAuth called, fromSplash: $fromSplash");
    final token = await StorageService.read('jwt_token');
    print("DEBUG: token exists: ${token != null}");

    if (token != null) {
      // Check if biometrics enabled (for both splash and manual login)
      final bioEnabled = await StorageService.read('biometrics_enabled');
      print("DEBUG: biometrics enabled: $bioEnabled");

      if (bioEnabled == 'true') {
        print("DEBUG: Attempting biometric authentication");
        final didAuthenticate = await _authenticateBiometrics();
        print("DEBUG: Biometric auth result: $didAuthenticate");

        if (!didAuthenticate) {
          // If biometric failed or canceled, force manual login
          print("DEBUG: Biometric auth failed, requiring manual login");
          _isAuthenticated = false;
          notifyListeners();
          return;
        }
      }

      try {
        final response = await _httpService.client.get('/users/profile');
        if (response.data['success']) {
          _user = response.data['data'];
          _isAuthenticated = true;
          print("DEBUG: Profile loaded successfully");
        } else {
          _isAuthenticated = false;
          await StorageService.delete('jwt_token');
          print("DEBUG: Profile load failed, token deleted");
        }
      } catch (e) {
        _isAuthenticated = false;
        await StorageService.delete('jwt_token');
        print("DEBUG: Profile API error: $e");
      }
    } else {
      _isAuthenticated = false;
      print("DEBUG: No token found");
    }
    notifyListeners();
  }

  Future<bool> _authenticateBiometrics() async {
    try {
      print("DEBUG: Starting biometric authentication");

      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      print(
        "DEBUG: canAuthenticateWithBiometrics: $canAuthenticateWithBiometrics",
      );
      print("DEBUG: canAuthenticate: $canAuthenticate");

      if (!canAuthenticate) {
        print("DEBUG: Device cannot authenticate");
        return false;
      }

      // Get available biometrics
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      print("DEBUG: Available biometrics: $availableBiometrics");

      if (availableBiometrics.isEmpty) {
        print("DEBUG: No biometrics available");
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Por favor autentícate para acceder a tu cuenta',
        biometricOnly: true,
      );

      print("DEBUG: Authentication result: $didAuthenticate");
      return didAuthenticate;
    } catch (e) {
      print("DEBUG: Biometric authentication error: $e");
      return false;
    }
  }

  Future<bool> shouldShowBiometricDialog() async {
    try {
      // Check if already enabled
      final alreadyEnabled = await StorageService.read('biometrics_enabled');
      if (alreadyEnabled == 'true') {
        return false; // Already enabled
      }

      // Check device support
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      return canAuthenticate;
    } catch (e) {
      print("DEBUG: Error checking if should show biometric dialog: $e");
      return false;
    }
  }

  Future<bool> enableBiometrics() async {
    try {
      print("DEBUG: Enabling biometrics");

      // Test biometric authentication before enabling
      final bool didAuthenticate = await _authenticateBiometrics();

      if (didAuthenticate) {
        await StorageService.write('biometrics_enabled', 'true');
        print("DEBUG: Biometrics enabled successfully");
        return true;
      } else {
        print("DEBUG: Biometric test failed, not enabling");
        return false;
      }
    } catch (e) {
      print("DEBUG: Error enabling biometrics: $e");
      return false;
    }
  }

  Future<void> disableBiometrics() async {
    await StorageService.delete('biometrics_enabled');
    await StorageService.delete('stored_email');
    await StorageService.delete('stored_password');
  }

  Future<void> fullLogout() async {
    // Complete logout that also clears biometric data
    await StorageService.delete('jwt_token');
    await StorageService.delete('biometrics_enabled');
    await StorageService.delete('stored_email');
    await StorageService.delete('stored_password');
    _isAuthenticated = false;
    _user = null;
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

        await StorageService.write('jwt_token', token);

        // Store credentials for biometric login (only if biometrics is enabled)
        final bioEnabled = await StorageService.read('biometrics_enabled');
        if (bioEnabled == 'true') {
          await StorageService.write('stored_email', email);
          await StorageService.write('stored_password', password);
          print("DEBUG: Stored credentials for biometric login");
        }

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
    await StorageService.delete('jwt_token');
    // DON'T delete stored credentials - we need them for biometric login
    // await StorageService.delete('stored_email');
    // await StorageService.delete('stored_password');
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
