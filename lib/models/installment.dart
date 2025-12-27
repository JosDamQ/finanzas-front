class InstallmentPayment {
  final int number;
  final String date;
  final double amount;

  InstallmentPayment({
    required this.number,
    required this.date,
    required this.amount,
  });

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) {
    return InstallmentPayment(
      number: json['number'] ?? 0,
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class Installment {
  final String id;
  final String description;
  final double totalAmount;
  final double amountPerInstallment;
  final int totalInstallments;
  final int paidInstallments;
  final String currency;
  final String startDate;
  final List<InstallmentPayment> payments;

  Installment({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.amountPerInstallment,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.currency,
    required this.startDate,
    required this.payments,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    var list = json['payments'] as List? ?? [];
    List<InstallmentPayment> paymentsList = list
        .map((i) => InstallmentPayment.fromJson(i))
        .toList();

    return Installment(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      amountPerInstallment: (json['amountPerInstallment'] ?? 0).toDouble(),
      totalInstallments: json['totalInstallments'] ?? 0,
      paidInstallments: json['paidInstallments'] ?? 0,
      currency: json['currency'] ?? 'GTQ',
      startDate: json['startDate'] ?? '',
      payments: paymentsList,
    );
  }
}
