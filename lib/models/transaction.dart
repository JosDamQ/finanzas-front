class Transaction {
  final String id;
  final String description;
  final double amount;
  final String date;
  final bool isPaid;
  final String currency;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isPaid,
    required this.currency,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      isPaid: json['isPaid'] ?? false,
      currency: json['currency'] ?? 'GTQ',
    );
  }
}
