import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../models/credit_card.dart';
import '../models/transaction.dart'
    as model; // Alias to avoid conflict with dart:html if web
import '../models/installment.dart';
import '../config/app_colors.dart';

import 'add_transaction_screen.dart';
import 'installment_detail_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final String cardId;

  const CardDetailScreen({super.key, required this.cardId});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().getCardDetail(widget.cardId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();
    final card = provider.selectedCard;

    if (provider.isLoading || card == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Transacciones"),
            Tab(text: "Cuotas"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(provider.transactions, context),
          _buildInstallmentsTab(provider.installments),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(cardId: widget.cardId),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionsTab(
    List<model.Transaction> transactions,
    BuildContext context,
  ) {
    if (transactions.isEmpty) {
      return const Center(child: Text("No hay transacciones"));
    }

    final provider = context.watch<CardProvider>();
    final card = provider.selectedCard;

    return Column(
      children: [
        if (card != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Límite Normal",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "Q ${card.limitGTQ.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Disponible",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "Q ${card.availableGTQ.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return _buildTransactionItem(t, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(model.Transaction t, BuildContext context) {
    // If paid, just show. If not paid, allow swipe.
    if (t.isPaid) {
      return Card(
        color: AppColors.surface,
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: AppColors.primary),
          title: Text(t.description),
          subtitle: Text(t.date.split('T')[0]),
          trailing: Text(
            "${t.currency} ${t.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.payment, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("¿Pagar Transacción?"),
            content: Text(
              "Se marcará como pagada y liberará límite.\n\n${t.description} - ${t.currency} ${t.amount}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Pagar"),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<CardProvider>().payTransaction(t.id).catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
          // Refresh to restore item if failed? Ideally yes, but here we assume success or reload.
        });
      },
      child: Card(
        color: AppColors.surface,
        child: ListTile(
          leading: const Icon(Icons.credit_card, color: AppColors.white),
          title: Text(t.description),
          subtitle: Text(t.date.split('T')[0]),
          trailing: Text(
            "${t.currency} ${t.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentsTab(List<Installment> installments) {
    return Consumer<CardProvider>(
      builder: (context, provider, child) {
        final card = provider.selectedCard;
        return Column(
          children: [
            if (card != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Límite Cuotas",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "Q ${card.installmentsLimit.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Disponible",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "Q ${card.availableInstallmentsGTQ.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: installments.isEmpty
                  ? const Center(child: Text("No hay cuotas pendientes"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: installments.length,
                      itemBuilder: (context, index) {
                        final i = installments[index];
                        final progress =
                            i.paidInstallments / i.totalInstallments;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InstallmentDetailScreen(installment: i),
                              ),
                            );
                          },
                          child: Card(
                            color: AppColors.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        i.description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "${i.paidInstallments}/${i.totalInstallments}",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[800],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total: ${i.currency} ${i.totalAmount}",
                                      ),
                                      Text(
                                        "Cuota: ${i.currency} ${i.amountPerInstallment.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
