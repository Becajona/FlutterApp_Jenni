import 'package:flutter/foundation.dart';

import '../../money/enums.dart'; // <- Asegúrate que aquí está RoundingMode
import '../../domain/entities/income_config.dart';
import '../../domain/entities/emergency_config.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/settings.dart';            // <- NUEVO
import '../../domain/services/budget_calculator.dart';  // BudgetResult / BudgetCalculator

class BudgetController extends ChangeNotifier {
  // ------------------ Estado principal ------------------
  IncomeConfig? _income;
  EmergencyConfig? _emergency;
  final List<Expense> _expenses = [];

  // Ajustes de ahorro automático (porcentaje extra + redondeo)
  Settings _settings = const Settings();                // <- NUEVO
  Settings get settings => _settings;

  // ------------------ Getters conveniencia ------------------
  IncomeConfig? get income => _income;
  EmergencyConfig? get emergency => _emergency;
  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get hasMinimumSetup => _income != null;                 // con ingresos basta para avanzar
  bool get isFullyConfigured => _income != null && _emergency != null;

  // ------------------ Setters / acciones de configuración ------------------
  void setIncome(double amount, Frequency frequency) {
    _income = IncomeConfig(amount: amount, frequency: frequency);
    notifyListeners();
  }

  void setEmergency(EmergencyConfig cfg) {
    _emergency = cfg;
    notifyListeners();
  }

  // Ajustes completos
  void setSettings(Settings s) {
    _settings = s;
    notifyListeners();
  }

  // Solo % extra
  void setExtraPercent(double p) {
    _settings = _settings.copyWith(extraSavingPercent: p);
    notifyListeners();
  }

  // Solo modo de redondeo
  void setRounding(RoundingMode mode) {
    _settings = _settings.copyWith(rounding: mode);
    notifyListeners();
  }

  // ------------------ CRUD de gastos ------------------
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

  // Total prorrateado a quincena (para encabezados/UX)
  double get totalExpensesQuincena {
    return _expenses.fold<double>(0, (sum, e) {
      switch (e.frequency) {
        case Frequency.quincenal: return sum + e.amount;
        case Frequency.mensual:   return sum + e.amount / 2;
        case Frequency.anual:     return sum + e.amount / 24;
      }
    });
  }

  // ------------------ Cálculo principal ------------------
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
      extraSavingPercent: _settings.extraSavingPercent, // <- aplica % extra
      rounding: _settings.rounding,                    // <- aplica redondeo
    );
  }
}
