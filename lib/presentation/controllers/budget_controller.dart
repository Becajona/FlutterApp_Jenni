import 'package:flutter/foundation.dart';

import '../../money/enums.dart'; // <-- ruta correcta
import '../../domain/entities/income_config.dart';
import '../../domain/entities/emergency_config.dart';
import '../../domain/entities/expense.dart';
import '../../domain/services/budget_calculator.dart'; // <-- aquí están BudgetResult y BudgetCalculator

class BudgetController extends ChangeNotifier {
  IncomeConfig? _income;
  EmergencyConfig? _emergency;
  final List<Expense> _expenses = [];
  double extraSavingPercent = 0;

  IncomeConfig? get income => _income;
  EmergencyConfig? get emergency => _emergency;
  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get hasMinimumSetup => _income != null; // de momento con ingresos basta
  bool get isFullyConfigured => _income != null && _emergency != null;

  void setIncome(double amount, Frequency frequency) {
    _income = IncomeConfig(amount: amount, frequency: frequency);
    notifyListeners();
  }

  void setEmergency(EmergencyConfig cfg) {
    _emergency = cfg;
    notifyListeners();
  }

  void addExpense(Expense e) {
    _expenses.add(e);
    notifyListeners();
  }

  BudgetResult? calculate() {
    if (_income == null) return null;
    return BudgetCalculator.calculate(
      income: _income!,
      emergency: _emergency ??
          const EmergencyConfig(mode: EmergencyMode.percent, value: 10, goalMonths: 3),
      expenses: _expenses,
      extraSavingPercent: extraSavingPercent,
    );
  }
}
