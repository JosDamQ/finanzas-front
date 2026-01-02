import 'package:flutter/material.dart';
import '../services/http_service.dart';
import '../models/credit_card.dart';
import '../models/transaction.dart';
import '../models/installment.dart';

class CardProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();

  List<CreditCard> _cards = [];
  bool _isLoading = false;

  // Detail State
  CreditCard? _selectedCard;
  List<Transaction> _transactions = [];
  List<Installment> _installments = [];

  List<CreditCard> get cards => _cards;
  bool get isLoading => _isLoading;
  CreditCard? get selectedCard => _selectedCard;
  List<Transaction> get transactions => _transactions;
  List<Installment> get installments => _installments;

  Future<void> getCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _httpService.client.get('/credit-cards');
      if (response.data['success']) {
        final List data = response.data['data'];
        _cards = data.map((e) => CreditCard.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCardDetail(String id) async {
    _isLoading = true;
    _selectedCard = null; // Reset previous selection
    notifyListeners();

    try {
      final response = await _httpService.client.get('/credit-cards/$id');
      if (response.data['success']) {
        final data = response.data['data'];
        _selectedCard = CreditCard.fromJson(data['card']);

        final List tList = data['transactions'];
        _transactions = tList.map((e) => Transaction.fromJson(e)).toList();

        final List iList = data['installments'];
        _installments = iList.map((e) => Installment.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> payTransaction(String transactionId) async {
    try {
      final response = await _httpService.client.post(
        '/credit-cards/transactions/$transactionId/pay',
      );
      if (response.data['success']) {
        // Update local state
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          if (_selectedCard != null) {
            await getCardDetail(_selectedCard!.id);
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final response = await _httpService.client.delete(
        '/credit-cards/transactions/$transactionId',
      );
      if (response.data['success']) {
        // Update local state
        if (_selectedCard != null) {
          await getCardDetail(_selectedCard!.id);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createCard(
    String name,
    double limit,
    int cutoffDay,
    int paymentDay, {
    double? installmentsLimit,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _httpService.client.post(
        '/credit-cards',
        data: {
          'name': name,
          'limitGTQ': limit,
          'installmentsLimit': installmentsLimit,
          'cutoffDay': cutoffDay,
          'paymentDay': paymentDay,
          'exchangeRate': 8,
        },
      );

      if (response.data['success']) {
        await getCards(); // Refresh list
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(
    String cardId,
    double amount,
    String description,
    String date,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _httpService.client.post(
        '/credit-cards/$cardId/transactions',
        data: {
          'amount': amount,
          'description': description,
          'date': date,
          'currency': 'GTQ', // Default for now, can be improved
        },
      );

      if (response.data['success']) {
        await getCardDetail(cardId);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInstallment(
    String cardId,
    double amount,
    String description,
    int totalMonths,
    String date,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final amountPerInstallment = amount / totalMonths;

      final response = await _httpService.client.post(
        '/credit-cards/$cardId/installments',
        data: {
          'description': description,
          'totalAmount': amount,
          'currency': 'GTQ',
          'totalInstallments': totalMonths,
          'amountPerInstallment': amountPerInstallment,
          'startDate': date,
        },
      );

      if (response.data['success']) {
        await getCardDetail(cardId);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> payInstallment(String installmentId) async {
    try {
      final response = await _httpService.client.post(
        '/credit-cards/installments/$installmentId/pay',
      );
      if (response.data['success']) {
        if (_selectedCard != null) {
          await getCardDetail(_selectedCard!.id);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
