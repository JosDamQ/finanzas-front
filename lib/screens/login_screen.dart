import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _biometricsEnabled = false;
  bool _checkingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final enabled = await StorageService.read('biometrics_enabled');
      final bioUserEmail = await StorageService.read('biometric_user_email');
      final storedEmail = await StorageService.read('stored_email');

      // Only show Face ID button if:
      // 1. Biometrics is enabled
      // 2. There's a biometric user configured
      // 3. There are stored credentials for that user
      final shouldShow =
          enabled == 'true' &&
          bioUserEmail != null &&
          storedEmail != null &&
          storedEmail == bioUserEmail;

      setState(() {
        _biometricsEnabled = shouldShow;
        _checkingBiometrics = false;
      });
    } catch (e) {
      setState(() {
        _checkingBiometrics = false;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      // Get biometric configuration
      final bioUserEmail = await StorageService.read('biometric_user_email');
      final storedEmail = await StorageService.read('stored_email');
      final storedPassword = await StorageService.read('stored_password');

      // Verify we have valid biometric setup
      if (bioUserEmail == null ||
          storedEmail == null ||
          storedPassword == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Configuración biométrica inválida. Configura Face ID nuevamente.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Verify stored credentials match biometric user
      if (storedEmail != bioUserEmail) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error de configuración biométrica. Configura Face ID nuevamente.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Authenticate with biometrics
      final localAuth = LocalAuthentication();
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a tu cuenta',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        // If biometric auth successful, do login with stored credentials
        final authProvider = context.read<AuthProvider>();
        await authProvider.login(storedEmail, storedPassword);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Autenticación biométrica cancelada"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Bienvenido",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Biometric Login Button (if enabled)
                if (_checkingBiometrics)
                  const Center(child: CircularProgressIndicator())
                else if (_biometricsEnabled) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.face, size: 48, color: Colors.blue),
                        const SizedBox(height: 12),
                        const Text(
                          "Usar Face ID",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Toca para autenticarte con Face ID",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text("Autenticar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("O ingresa manualmente"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 24),
                if (authProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await authProvider.login(
                            _emailController.text,
                            _passwordController.text,
                          );
                          // Biometric dialog will be shown in Dashboard
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll("DioException: ", ""),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Ingresar"),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text("¿No tienes cuenta? Regístrate"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
