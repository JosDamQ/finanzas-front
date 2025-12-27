import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../config/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Backend expects: YYYY-MM-DD (ISO 8601 part) or similar?
      // The context says "birthdate". Let's assume ISO or standard string.
      // Usually standard date format is safe.
      setState(() {
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Cuenta")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre Completo",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v!.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Teléfono",
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthdateController,
                  decoration: const InputDecoration(
                    labelText: "Fecha de Nacimiento",
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 32),
                if (authProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await authProvider.register(
                            _nameController.text,
                            _emailController.text,
                            _passwordController.text,
                            _phoneController.text,
                            _birthdateController.text,
                          );
                          // Navigator pop happens automatically if AuthWrapper detects auth change?
                          // Yes, but if we are pushed from Login, we might need to pop first to let wrapper handle.
                          // Actually, wrapper is at root. If we are authenticated, wrapper rebuilds and shows Dashboard.
                          // BUT we are currently in a pushed route on top of Login.
                          // So we should pop everything until first route.
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
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
                    child: const Text("Registrarse"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
