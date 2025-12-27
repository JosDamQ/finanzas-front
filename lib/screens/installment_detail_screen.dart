import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/installment.dart';
import '../providers/card_provider.dart';
import '../config/app_colors.dart';

class InstallmentDetailScreen extends StatelessWidget {
  final Installment installment;

  const InstallmentDetailScreen({super.key, required this.installment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Cuotas")),
      body: Column(
        children: [
          // Header Circular Progress
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  installment.description,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Circular Progress and Text in Column, not Stack
                Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value:
                            installment.paidInstallments /
                            installment.totalInstallments,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text(
                          "${installment.paidInstallments} de ${installment.totalInstallments}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Cuotas Pagadas",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Total: ${installment.currency} ${installment.totalAmount}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const Divider(),
          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: installment.totalInstallments,
              itemBuilder: (context, index) {
                final monthNumber = index + 1;
                final isPaid = monthNumber <= installment.paidInstallments;
                final isCurrent =
                    monthNumber == installment.paidInstallments + 1;

                // Try to find payment record
                InstallmentPayment? paymentRecord;
                try {
                  paymentRecord = installment.payments.firstWhere(
                    (p) => p.number == monthNumber,
                  );
                } catch (_) {}

                Color statusColor = Colors.grey;
                IconData statusIcon = Icons.lock_clock;

                if (isPaid) {
                  statusColor = AppColors.primary; // Green
                  statusIcon = Icons.check_circle;
                } else if (isCurrent) {
                  statusColor = AppColors.warning; // Yellow
                  statusIcon = Icons.access_time_filled;
                }

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Text(
                            "$monthNumber",
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mes $monthNumber",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isPaid && paymentRecord != null)
                                Text(
                                  "Pagado: ${paymentRecord.date.split('T')[0]}",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                )
                              else if (isPaid)
                                Text(
                                  "Pagado",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                )
                              else if (isCurrent)
                                Text(
                                  "Pendiente de Pago",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                )
                              else
                                const Text(
                                  "Próximamente",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<CardProvider>()
                                  .payInstallment(installment.id)
                                  .then((_) {
                                    if (context.mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // Pop to refresh parent or refresh self?
                                      // Parent refreshes via provider, but we passed "installment" object which is stale.
                                      // Better to pop.
                                    }
                                  })
                                  .catchError((e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Pagar"),
                          )
                        else
                          Icon(statusIcon, color: statusColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
