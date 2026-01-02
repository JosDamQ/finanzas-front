import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/card_provider.dart';
import '../models/credit_card.dart';
import '../config/app_colors.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

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

    if (shouldShow && mounted) {
      _showBiometricDialog();
    }
  }

  Future<void> _showBiometricDialog() async {
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
              Navigator.pop(ctx);
            },
            child: const Text("No, gracias"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final success = await context
                  .read<AuthProvider>()
                  .enableBiometrics();

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

  Future<void> _tryActivateNotifications() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          title: Text("Activando Notificaciones"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Intentando obtener token de notificaciones..."),
            ],
          ),
        ),
      );

      // Try to get and send FCM token
      final success = await NotificationService.tryToSendTokenToBackend();

      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Also try to send via AuthProvider
        final authProvider = context.read<AuthProvider>();
        await authProvider.sendFCMTokenManually();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Notificaciones activadas exitosamente!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No se pudo activar las notificaciones. Inténtalo más tarde.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showBiometricSettings() async {
    final authProvider = context.read<AuthProvider>();

    // Check if biometrics is enabled AND if current user is the biometric user
    final bioEnabled = await StorageService.read('biometrics_enabled');
    final bioUserEmail = await StorageService.read('biometric_user_email');
    final currentUserEmail = authProvider.user?['email'];

    // Only show as enabled if biometrics is active AND current user is the biometric user
    bool isEnabled =
        bioEnabled == 'true' &&
        bioUserEmail != null &&
        currentUserEmail != null &&
        bioUserEmail == currentUserEmail;

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
                        // Activar biometría para este usuario
                        // Si otro usuario tenía biometría, se desactivará automáticamente
                        final success = await authProvider.enableBiometrics();
                        if (success) {
                          setState(() => isEnabled = true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Biometría activada exitosamente para esta cuenta",
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
                              "Se desactivará Face ID para esta cuenta. Tendrás que ingresar tu email y contraseña manualmente.",
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
                                        content: Text(
                                          "Biometría desactivada para esta cuenta",
                                        ),
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
          // Notification settings button
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.orange),
            onPressed: () => _tryActivateNotifications(),
            tooltip: "Activar Notificaciones",
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

    // Show all pending expenses (not just top 3)
    final allPending = pendingExpenses;

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

        if (allPending.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pendiente de Pago",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "${allPending.length} pendientes",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Contenedor con scroll propio para los pagos pendientes
          Container(
            height: allPending.length > 3
                ? 200
                : null, // Altura fija solo si hay más de 3 items
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: allPending.length > 3
                ? ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: allPending.length,
                    itemBuilder: (context, index) {
                      final expense = allPending[index];
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          title: Text(expense['name']),
                          trailing: Text(
                            "Q ${(expense['amount'] as double).toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          dense: true,
                        ),
                      );
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: allPending
                          .map(
                            (expense) => Card(
                              color: AppColors.surface,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                ),
                                title: Text(expense['name']),
                                trailing: Text(
                                  "Q ${(expense['amount'] as double).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                dense: true,
                              ),
                            ),
                          )
                          .toList(),
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
