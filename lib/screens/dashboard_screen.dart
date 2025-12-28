import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/card_provider.dart';
import '../models/credit_card.dart';
import '../config/app_colors.dart';
import '../services/storage_service.dart';

import 'card_detail_screen.dart';
import 'budgets_screen.dart';
import 'budget_detail_screen.dart';
import 'add_card_screen.dart';

import '../providers/budget_provider.dart';
import '../models/budget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().getCards();
      context.read<BudgetProvider>().getBudgets();
      _checkBiometricDialog();
    });
  }

  Future<void> _checkBiometricDialog() async {
    // Add a delay to ensure the screen is fully loaded
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final shouldShow = await authProvider.shouldShowBiometricDialog();

    print("DEBUG: Dashboard - shouldShowBiometricDialog: $shouldShow");

    if (shouldShow && mounted) {
      _showBiometricDialog();
    }
  }

  Future<void> _showBiometricDialog() async {
    print("DEBUG: Dashboard - showing biometric dialog");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Biometría"),
        content: const Text(
          "¿Deseas activar FaceID/Huella para iniciar sesión más rápido la próxima vez?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              print("DEBUG: Dashboard - User declined biometrics");
              Navigator.pop(ctx);
            },
            child: const Text("No, gracias"),
          ),
          ElevatedButton(
            onPressed: () async {
              print("DEBUG: Dashboard - User accepted biometrics, testing...");
              Navigator.pop(ctx);

              final success = await context
                  .read<AuthProvider>()
                  .enableBiometrics();
              print("DEBUG: Dashboard - Enable biometrics result: $success");

              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Biometría activada exitosamente"),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("No se pudo activar la biometría"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Sí, activar"),
          ),
        ],
      ),
    );
  }

  Future<void> _showBiometricSettings() async {
    final authProvider = context.read<AuthProvider>();
    final bioEnabled = await StorageService.read('biometrics_enabled');
    bool isEnabled = bioEnabled == 'true';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue),
              SizedBox(width: 12),
              Text("Configuración\nBiométrica"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Activa la autenticación biométrica para acceder más rápido a tu cuenta.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Face ID / Huella Digital",
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: isEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) async {
                      if (value) {
                        // Activar biometría
                        final success = await authProvider.enableBiometrics();
                        if (success) {
                          setState(() => isEnabled = true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Biometría activada exitosamente",
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "No se pudo activar la biometría",
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      } else {
                        // Desactivar biometría
                        showDialog(
                          context: context,
                          builder: (confirmCtx) => AlertDialog(
                            title: const Text("¿Desactivar Biometría?"),
                            content: const Text(
                              "Se eliminarán las credenciales guardadas y tendrás que ingresar tu email y contraseña manualmente.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx),
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                onPressed: () async {
                                  await authProvider.disableBiometrics();
                                  setState(() => isEnabled = false);
                                  Navigator.pop(confirmCtx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Biometría desactivada"),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                  }
                                },
                                child: const Text("Desactivar"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              if (isEnabled) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "La biometría está activa. Podrás usar Face ID en el login.",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final user = context.read<AuthProvider>().user;

    // Find current month budget
    final now = DateTime.now();
    Budget? currentBudget;
    try {
      currentBudget = budgetProvider.budgets.firstWhere(
        (b) => b.month == now.month && b.year == now.year,
      );
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text("Hola, ${user?['name'] ?? 'Usuario'}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCardScreen()),
            ),
            tooltip: "Agregar Tarjeta",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          // Biometric settings button
          IconButton(
            icon: const Icon(Icons.fingerprint, color: Colors.blue),
            onPressed: () => _showBiometricSettings(),
            tooltip: "Configuración Biométrica",
          ),
        ],
      ),
      body: cardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<CardProvider>().getCards(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mis Tarjetas",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (cardProvider.cards.isEmpty)
                    Card(
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddCardScreen(),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Agregar Tarjeta",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        itemCount: cardProvider.cards.length,
                        controller: PageController(viewportFraction: 0.9),
                        itemBuilder: (context, index) {
                          return _buildCreditCard(cardProvider.cards[index]);
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Resumen Mensual",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetsScreen(),
                          ),
                        ),
                        child: const Text("Ver Presupuestos"),
                      ),
                    ],
                  ),
                  // Financial Health Monitor
                  if (currentBudget != null) ...[
                    _buildFinancialHealthCard(currentBudget),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFinancialHealthCard(Budget budget) {
    // Calculate "Pisto Para Gastar" (Money Left to Spend)
    double pistoLibre = 0;
    double totalAhorro = 0;
    List<Map<String, dynamic>> pendingExpenses = [];

    for (var section in budget.sections) {
      pistoLibre += section.toSpend;
      totalAhorro += section.savings;

      for (var expense in section.expenses) {
        if (!expense.isPaid) {
          pendingExpenses.add({'name': expense.name, 'amount': expense.amount});
        }
      }
    }

    // Show top 3 pending
    final topPending = pendingExpenses.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Card: Pisto Libre
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetDetailScreen(budget: budget),
              ),
            );
            // Refresh dashboard when coming back
            if (context.mounted) {
              context.read<BudgetProvider>().getBudgets();
              context.read<CardProvider>().getCards();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pistoLibre >= 0
                    ? [
                        const Color(0xFF1B5E20),
                        const Color(0xFF2E7D32),
                      ] // Green
                    : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)], // Red
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (pistoLibre >= 0 ? Colors.green : Colors.red)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pisto Para Gastar",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Q ${pistoLibre.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.savings, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Ahorro: Q ${totalAhorro.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (topPending.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            "Pendiente de Pago",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...topPending.map(
            (e) => Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                title: Text(e['name']),
                trailing: Text(
                  "Q ${(e['amount'] as double).toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                dense: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCreditCard(CreditCard card) {
    final double progress = card.limitGTQ > 0
        ? (card.totalDebtGTQ / card.limitGTQ)
        : 0.0;
    Color progressColor = AppColors.primary;
    if (progress > 0.5) progressColor = AppColors.warning;
    if (progress > 0.9) progressColor = AppColors.error;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: card.id)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (card.bankName != null)
                    Text(
                      card.bankName!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Disponible Normal",
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                      Text(
                        "Q ${card.availableGTQ.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Disp. Cuotas",
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                      Text(
                        "Q ${card.availableInstallmentsGTQ.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Deuda Normal: Q ${card.totalDebtGTQ.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "Límite: Q ${card.limitGTQ.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
