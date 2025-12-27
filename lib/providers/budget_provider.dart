import 'package:flutter/material.dart';
import '../services/http_service.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();

  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> getBudgets({int? year}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final query = year != null ? '?year=$year' : '';
      final response = await _httpService.client.get('/budgets$query');
      if (response.data['success']) {
        final List data = response.data['data'];
        _budgets = data.map((e) => Budget.fromJson(e)).toList();
        // Sort by year desc, month desc
        _budgets.sort((a, b) {
          if (a.year != b.year) return b.year.compareTo(a.year);
          return b.month.compareTo(a.month);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      final response = await _httpService.client.delete('/budgets/$id');
      if (response.data['success']) {
        _budgets.removeWhere((b) => b.id == id);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> copyBudget(
    String sourceBudgetId,
    int toMonth,
    int toYear,
  ) async {
    try {
      final response = await _httpService.client.post(
        '/budgets/copy',
        data: {
          'sourceBudgetId': sourceBudgetId,
          'targetMonth': toMonth,
          'targetYear': toYear,
        },
      );

      if (response.data['success']) {
        await getBudgets(); // Refresh list
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createBudget(int month, int year, String type) async {
    _isLoading = true;
    notifyListeners();
    try {
      List<Map<String, dynamic>> initialSections = [];

      if (type == 'bi-weekly') {
        initialSections = [
          {
            'title': 'Primera Quincena',
            'income': 0,
            'expenses': [],
            'savings': 0,
          },
          {
            'title': 'Segunda Quincena',
            'income': 0,
            'expenses': [],
            'savings': 0,
          },
        ];
      } else {
        initialSections = [
          {'title': 'Mes Completo', 'income': 0, 'expenses': [], 'savings': 0},
        ];
      }

      final response = await _httpService.client.post(
        '/budgets',
        data: {
          'month': month,
          'year': year,
          'sections': initialSections,
          'type': type,
          'currency': 'GTQ',
        },
      );

      if (response.data['success']) {
        await getBudgets();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBudget(Budget budget) async {
    // Optimistic update could be done here, but let's just call API
    try {
      final response = await _httpService.client.put(
        '/budgets/${budget.id}',
        data: {
          'month': budget.month,
          'year': budget.year,
          'type': budget.type,
          'currency': 'GTQ',
          'sections': budget.sections.map((s) => s.toJson()).toList(),
        },
      );

      if (response.data['success']) {
        // Refresh or update local list
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          _budgets[index] = Budget.fromJson(response.data['data']);
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
