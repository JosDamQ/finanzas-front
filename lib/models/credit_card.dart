class CreditCard {
  final String id;
  final String name;
  final double limitGTQ;
  final double totalDebtGTQ;
  final double availableGTQ;
  final double installmentsLimit;
  final double installmentsDebtGTQ;
  final double availableInstallmentsGTQ;
  final String closingDate;
  final String paymentDate;
  final String? bankName;

  CreditCard({
    required this.id,
    required this.name,
    required this.limitGTQ,
    required this.totalDebtGTQ,
    required this.availableGTQ,
    required this.installmentsLimit,
    required this.installmentsDebtGTQ,
    required this.availableInstallmentsGTQ,
    required this.closingDate,
    required this.paymentDate,
    this.bankName,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Tarjeta',
      limitGTQ: (json['limitGTQ'] ?? 0).toDouble(),
      totalDebtGTQ: (json['totalDebtGTQ'] ?? 0).toDouble(),
      availableGTQ: (json['availableGTQ'] ?? 0).toDouble(),
      installmentsLimit: (json['installmentsLimit'] ?? 0).toDouble(),
      installmentsDebtGTQ: (json['installmentsDebtGTQ'] ?? 0).toDouble(),
      availableInstallmentsGTQ: (json['availableInstallmentsGTQ'] ?? 0)
          .toDouble(),
      closingDate: json['closingDate']?.toString() ?? '1',
      paymentDate: json['paymentDate']?.toString() ?? '15',
      bankName: json['bankName'],
    );
  }
}
