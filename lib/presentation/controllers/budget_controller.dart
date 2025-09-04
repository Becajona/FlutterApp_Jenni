import 'package:flutter/foundation.dart';

import '../../money/enums.dart';
import '../../domain/entities/income_config.dart';
import '../../domain/entities/emergency_config.dart';
import '../../domain/entities/expense.dart';
import '../../domain/services/budget_calculator.dart'; // Aquí están BudgetResult y BudgetCalculator

class BudgetController extends ChangeNotifier {
  IncomeConfig? _income;
  EmergencyConfig? _emergency;
  final List<Expense> _expenses = [];
  double extraSavingPercent = 0;

  // Getters de estado
  IncomeConfig? get income => _income;
  EmergencyConfig? get emergency => _emergency;
  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get hasMinimumSetup => _income != null; // por ahora sólo ingresos
  bool get isFullyConfigured => _income != null && _emergency != null;

  // Setters / acciones de configuración
  void setIncome(double amount, Frequency frequency) {
    _income = IncomeConfig(amount: amount, frequency: frequency);
    notifyListeners();
  }

  void setEmergency(EmergencyConfig cfg) {
    _emergency = cfg;
    notifyListeners();
  }

  void setExtraSavingPercent(double value) {
    extraSavingPercent = value;
    notifyListeners();
  }

  // CRUD de gastos
  void addExpense(Expense e) {
    _expenses.add(e);
    notifyListeners();
  }

  void updateExpense(Expense e) {
    final i = _expenses.indexWhere((x) => x.id == e.id);
    if (i != -1) {
      _expenses[i] = e;
      notifyListeners();
    }
  }

  void removeExpense(String id) {
    _expenses.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  /// Total de gastos prorrateado a quincena (útil para mostrar en lista/encabezado)
  double get totalExpensesQuincena {
    return _expenses.fold<double>(0, (sum, e) {
      switch (e.frequency) {
        case Frequency.quincenal:
          return sum + e.amount;
        case Frequency.mensual:
          return sum + e.amount / 2;
        case Frequency.anual:
          return sum + e.amount / 24;
      }
    });
  }

  /// Ejecuta el cálculo completo del presupuesto.
  /// Si no hay ingresos configurados, devuelve `null`.
  BudgetResult? calculate() {
    if (_income == null) return null;

    return BudgetCalculator.calculate(
      income: _income!,
      emergency: _emergency ??
          const EmergencyConfig(
            mode: EmergencyMode.percent,
            value: 10,
            goalMonths: 3,
          ),
      expenses: _expenses,
      extraSavingPercent: extraSavingPercent,
    );
  }
}
