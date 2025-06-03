import 'package:flutter/material.dart';

class BalanceService extends ChangeNotifier {
  double _balance = 0.0;

  double get balance => _balance;

  void updateBalance(double newBalance) {
    if (_balance != newBalance) {
      _balance = newBalance;
      notifyListeners();
    }
  }
}
