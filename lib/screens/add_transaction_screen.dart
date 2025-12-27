import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/card_provider.dart';
import '../config/app_colors.dart';

class AddTransactionScreen extends StatefulWidget {
  final String cardId;

  const AddTransactionScreen({super.key, required this.cardId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _monthsController = TextEditingController(); // For installments

  bool _isInstallment = false; // Toggle

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Gasto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle Type
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isInstallment = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isInstallment
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Gasto Normal",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isInstallment
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isInstallment = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isInstallment
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Cuotas",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isInstallment
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Monto (GTQ)",
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Requerido";
                  if (double.tryParse(v) == null) return "Inválido";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Fecha",
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),

              if (_isInstallment) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthsController,
                  decoration: const InputDecoration(
                    labelText: "Número de Cuotas (Meses)",
                    hintText: "Ej. 3, 6, 12",
                    prefixIcon: Icon(Icons.timelapse),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (!_isInstallment) return null;
                    if (v == null || v.isEmpty) return "Requerido";
                    if (int.tryParse(v) == null)
                      return "Debe ser número entero";
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        if (_isInstallment) {
                          await provider.addInstallment(
                            widget.cardId,
                            double.parse(_amountController.text),
                            _descriptionController.text,
                            int.parse(_monthsController.text),
                            _dateController.text,
                          );
                        } else {
                          await provider.addTransaction(
                            widget.cardId,
                            double.parse(_amountController.text),
                            _descriptionController.text,
                            _dateController.text,
                          );
                        }
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
                  child: Text(
                    _isInstallment ? "Crear Plan de Cuotas" : "Agregar Gasto",
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
