import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../config/app_colors.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _installmentsLimitController = TextEditingController();
  final _cutoffController = TextEditingController();
  final _paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Tarjeta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la Tarjeta",
                  hintText: "Ej. Visa Oro",
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(
                  labelText: "Límite (GTQ)",
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Requerido";
                  if (double.tryParse(v) == null) return "Inválido";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _installmentsLimitController,
                decoration: const InputDecoration(
                  labelText: "Límite Cuotas (Opcional)",
                  hintText: "Por defecto: Límite * 2",
                  prefixIcon: Icon(Icons.layers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cutoffController,
                      decoration: const InputDecoration(
                        labelText: "Día Corte",
                        hintText: "1-31",
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Req." : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _paymentController,
                      decoration: const InputDecoration(
                        labelText: "Día Pago",
                        hintText: "1-31",
                        prefixIcon: Icon(Icons.event),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Req." : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await provider.createCard(
                          _nameController.text,
                          double.parse(_limitController.text),
                          int.parse(_cutoffController.text),
                          int.parse(_paymentController.text),
                          installmentsLimit:
                              _installmentsLimitController.text.isNotEmpty
                              ? double.parse(_installmentsLimitController.text)
                              : null,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
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
                  child: const Text("Guardar Tarjeta"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
