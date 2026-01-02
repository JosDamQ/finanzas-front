import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../config/app_colors.dart';

import 'add_budget_screen.dart';

import 'budget_detail_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().getBudgets(year: _selectedYear);
    });
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

  List<DropdownMenuItem<int>> _generateYearItems() {
    final currentYear = DateTime.now().year;
    final years = <int>[];

    // Agregar años desde 2020 hasta 3 años en el futuro
    for (int year = 2020; year <= currentYear + 3; year++) {
      years.add(year);
    }

    return years.reversed.map((year) {
      return DropdownMenuItem<int>(value: year, child: Text(year.toString()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Presupuestos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Nuevo Presupuesto",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Copiar mes anterior",
            onPressed: () => _showCopyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.grey),
                const SizedBox(width: 12),
                const Text(
                  "Año:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isDense: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      dropdownColor: AppColors.surface,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                      items: _generateYearItems(),
                      onChanged: (year) {
                        if (year != null) {
                          setState(() {
                            _selectedYear = year;
                          });
                          context.read<BudgetProvider>().getBudgets(year: year);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.budgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No tienes presupuestos para $_selectedYear",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddBudgetScreen(),
                            ),
                          ),
                          child: const Text("Crear presupuesto"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.budgets.length,
                    itemBuilder: (context, index) {
                      return _buildBudgetCard(provider.budgets[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final income = budget.totalIncome;
    final spent = budget.totalSpent; // This is Planned Expenses
    final executed = budget.totalExecuted; // This is Paid Expenses

    // Progress Bar: (Paid / Income) to show how much of budget is GONE
    // Or (Paid / Planned) to show completion?
    // User said: "progress bar que sale abajo de un presupuesto que se vaya llenando conforme se tachan los gastos"
    // Usually means execution % of the plan.
    // Let's use Executed / Income as it's safer limit.
    // If Income is 0, use Executed / Spent (if > 0).

    double progress = 0.0;
    if (spent > 0) {
      progress = executed / spent;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BudgetDetailScreen(budget: budget)),
        );
        // Refresh when coming back
        if (mounted) {
          context.read<BudgetProvider>().getBudgets(year: _selectedYear);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_getMonthName(budget.month)} ${budget.year}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    budget.type == 'bi-weekly' ? 'Quincenal' : 'Mensual',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ingresos"),
                  Text(
                    "Q ${income.toStringAsFixed(2)}",
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Gastos"),
                  Text(
                    "Q ${spent.toStringAsFixed(2)}",
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 1.0 ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${budget.sections.length} Secciones",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCopyDialog(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    final budgets = provider.budgets;

    int fromMonth;
    int fromYear;
    String sourceId;

    if (budgets.isNotEmpty) {
      final latest = budgets.first;
      fromMonth = latest.month;
      fromYear = latest.year;
      sourceId = latest.id;
    } else {
      // Fallback to current month if no budgets exist
      // But we can't copy if no source exists!
      // We should probably just show create dialog or error.
      // Or maybe the user meant "Create Next Month"?
      // For now let's just return and maybe show snackbar "Crea un presupuesto primero"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay presupuestos para copiar. Crea uno nuevo."),
        ),
      );
      return;
    }

    // Target is next month of the latest budget
    int toMonth = fromMonth + 1;
    int toYear = fromYear;
    if (toMonth > 12) {
      toMonth = 1;
      toYear += 1;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Copiar Presupuesto"),
        content: Text(
          "¿Copiar presupuesto de ${_getMonthName(fromMonth)} $fromYear a ${_getMonthName(toMonth)} $toYear?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final provider = context.read<BudgetProvider>();
              provider
                  .copyBudget(sourceId, toMonth, toYear)
                  .then((_) {
                    // Actualizar el año seleccionado si se copió a un año diferente
                    if (toYear != _selectedYear && mounted) {
                      setState(() {
                        _selectedYear = toYear;
                      });
                    }
                    if (mounted) {
                      provider.getBudgets(year: _selectedYear);
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Presupuesto copiado")),
                      );
                    }
                  })
                  .catchError((e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  });
            },
            child: const Text("Copiar"),
          ),
        ],
      ),
    );
  }
}
