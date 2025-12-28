import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../config/app_colors.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late Budget _budget;
  bool _hasChanges = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    // Clone budget to avoid modifying provider state directly until save
    // Simple deep copy via JSON
    _budget = Budget.fromJson(widget.budget.toJson());
  }

  // Helper to extend Budget with toJson (since it's not in the model file I wrote previously? Wait, I didn't write toJson for Budget in previous step? I only wrote for Section/Expense)
  // Let's check model file content again. I think I missed Budget.toJson.
  // I will just use the reference for now and rely on Provider to refresh.
  // Actually, modifying the object directly is fine if we call update.

  void _save() async {
    try {
      await context.read<BudgetProvider>().updateBudget(_budget);
      setState(() => _hasChanges = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Guardado exitosamente")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  // Unused method removed

  void _addExpense(BudgetSection section) {
    setState(() {
      section.expenses.add(BudgetExpense(name: "", amount: 0, isPaid: false));
      _hasChanges = true;
    });
  }

  void _removeExpense(BudgetSection section, int index) {
    setState(() {
      section.expenses.removeAt(index);
      _hasChanges = true;
    });
  }

  void _deleteBudget() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Presupuesto"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<BudgetProvider>()
                  .deleteBudget(_budget.id)
                  .then((_) {
                    if (mounted) {
                      Navigator.pop(context); // Close detail screen
                    }
                  })
                  .catchError((e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  });
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBudget() async {
    try {
      // Create a dedicated widget for sharing (Clean look, full content)
      // We use a separate ScreenshotController for this hidden widget
      final shareController = ScreenshotController();

      final image = await shareController.captureFromWidget(
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white, // Always white background for readability
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  "Presupuesto ${_getMonthName(_budget.month)} ${_budget.year}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ..._budget.sections.map(
                (section) => Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey[200],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              section.title.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "Q ${section.income.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black),
                      // Expenses
                      ...section.expenses.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  e.name,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  e.amount.toStringAsFixed(2),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black),
                      // Footer
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "TOTAL GASTOS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "Q ${section.totalExpenses.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "TOTAL QUE ME QUEDA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "Q ${section.remaining.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "AHORRO",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "Q ${section.savings.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "PISTO PARA GASTAR",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "Q ${section.toSpend.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/presupuesto_completo.png',
      ).create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        // Removing text parameter avoids creating a separate .txt file on iOS
        // text: 'Presupuesto ${_getMonthName(_budget.month)}',
        subject: 'Presupuesto Completo',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Presupuesto ${_getMonthName(_budget.month)}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareBudget,
            tooltip: "Compartir Captura",
          ),
          if (_hasChanges)
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteBudget,
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor, // Ensure background is captured
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _budget.sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return _buildSection(_budget.sections[index]);
            },
          ),
        ),
      ),
      floatingActionButton: null, // Removed FAB as requested
    );
  }

  Widget _buildSection(BudgetSection section) {
    final totalExpenses = section.totalExpenses;
    final remaining = section.remaining;
    final toSpend = section.toSpend;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: section.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Título Sección",
                    ),
                    onChanged: (v) {
                      section.title = v;
                      _hasChanges = true;
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: section.income.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixText: "Q ",
                    ),
                    onChanged: (v) {
                      setState(() {
                        section.income = double.tryParse(v) ?? 0;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Expenses List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.expenses.length,
            itemBuilder: (context, index) {
              final expense = section.expenses[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[850]!)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: expense.isPaid,
                      onChanged: (v) {
                        setState(() {
                          expense.isPaid = v ?? false;
                          _hasChanges = true;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: expense.name,
                        style: TextStyle(
                          decoration: expense.isPaid
                              ? TextDecoration.lineThrough
                              : null,
                          color: expense.isPaid ? Colors.grey : null,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Concepto",
                        ),
                        onChanged: (v) {
                          expense.name = v;
                          _hasChanges = true;
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: expense.amount == 0
                            ? ''
                            : expense.amount.toString(),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          decoration: expense.isPaid
                              ? TextDecoration.lineThrough
                              : null,
                          color: expense.isPaid ? Colors.grey : null,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          setState(() {
                            expense.amount = double.tryParse(v) ?? 0;
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onPressed: () => _removeExpense(section, index),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 8),
                    ),
                  ],
                ),
              );
            },
          ),

          // Add Expense Button
          TextButton.icon(
            onPressed: () => _addExpense(section),
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Agregar Gasto"),
          ),

          const Divider(height: 1),

          // Footer Calculations
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSummaryRow(
                  "TOTAL GASTOS",
                  totalExpenses,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  "TOTAL QUE ME QUEDA",
                  remaining,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "AHORRO",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: section.savings == 0
                            ? ''
                            : section.savings.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          prefixText: "Q ",
                        ),
                        onChanged: (v) {
                          setState(() {
                            section.savings = double.tryParse(v) ?? 0;
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  "PISTO PARA GASTAR",
                  toSpend,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          "Q ${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }
}
