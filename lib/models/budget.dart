class BudgetExpense {
  String name;
  double amount;
  bool isPaid;
  String? id;

  BudgetExpense({
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.id,
  });

  factory BudgetExpense.fromJson(Map<String, dynamic> json) {
    return BudgetExpense(
      id: json['_id'],
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      isPaid: json['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount, 'isPaid': isPaid};
  }
}

class BudgetSection {
  String title;
  double income;
  double savings;
  List<BudgetExpense> expenses;

  BudgetSection({
    required this.title,
    required this.income,
    required this.savings,
    required this.expenses,
  });

  factory BudgetSection.fromJson(Map<String, dynamic> json) {
    var list = json['expenses'] as List? ?? [];
    List<BudgetExpense> expensesList = list
        .map((i) => BudgetExpense.fromJson(i))
        .toList();

    return BudgetSection(
      title: json['title'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      savings: (json['savings'] ?? 0).toDouble(),
      expenses: expensesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'income': income,
      'savings': savings,
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
  }

  // Computed properties
  double get totalExpenses =>
      expenses.fold(0, (sum, item) => sum + item.amount);
  double get totalPaid =>
      expenses.fold(0, (sum, item) => item.isPaid ? sum + item.amount : sum);
  double get remaining => income - totalExpenses;
  double get toSpend => remaining - savings;
}

class Budget {
  final String id;
  final int month;
  final int year;
  final List<BudgetSection> sections;
  final String type; // 'monthly' or 'bi-weekly'

  Budget({
    required this.id,
    required this.month,
    required this.year,
    required this.sections,
    required this.type,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    var list = json['sections'] as List? ?? [];
    List<BudgetSection> sectionsList = list
        .map((i) => BudgetSection.fromJson(i))
        .toList();

    return Budget(
      id: json['_id'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2024,
      sections: sectionsList,
      type: json['type'] ?? 'monthly',
    );
  }

  // Computed properties
  double get totalIncome => sections.fold(0, (sum, s) => sum + s.income);
  double get totalSpent => sections.fold(0, (sum, s) => sum + s.totalExpenses);
  double get totalExecuted => sections.fold(0, (sum, s) => sum + s.totalPaid);

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'month': month,
      'year': year,
      'type': type,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }
}
