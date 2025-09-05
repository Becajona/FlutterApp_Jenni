import '../../money/enums.dart';
import '../entities/income_config.dart';
import '../entities/emergency_config.dart';
import '../entities/expense.dart';

class BudgetResult {
  final double ingresoQ;
  final double gastosQ;
  final double colchonQ;
  final double ahorroQ;
  final double ahorroMensual;
  final double ahorroAnual;

  BudgetResult({
    required this.ingresoQ,
    required this.gastosQ,
    required this.colchonQ,
    required this.ahorroQ,
    required this.ahorroMensual,
    required this.ahorroAnual,
  });
}

class BudgetCalculator {
  static double _toQuincena(double amount, Frequency f) {
    switch (f) {
      case Frequency.quincenal: return amount;
      case Frequency.mensual:   return amount / 2;
      case Frequency.anual:     return amount / 24;
    }
  }

  static double _roundUp(double value, RoundingMode mode) {
    if (value <= 0) return value; // no redondear negativos
    switch (mode) {
      case RoundingMode.none:  return value;
      case RoundingMode.up10:  return (value / 10).ceil() * 10;
      case RoundingMode.up50:  return (value / 50).ceil() * 50;
      case RoundingMode.up100: return (value / 100).ceil() * 100;
    }
  }

  static BudgetResult calculate({
    required IncomeConfig income,
    required EmergencyConfig emergency,
    required List<Expense> expenses,
    double extraSavingPercent = 0,     // 0–100
    RoundingMode rounding = RoundingMode.none,
  }) {
    final ingresoQ = _toQuincena(income.amount, income.frequency);
    final gastosQ = expenses.fold<double>(0, (sum, e) => sum + _toQuincena(e.amount, e.frequency));

    final colchonQ = emergency.mode == EmergencyMode.percent
        ? ingresoQ * (emergency.value / 100.0)
        : emergency.value;

    final base = ingresoQ - gastosQ - colchonQ;

    // aplicar % extra solo si hay base positiva
    final withExtra = base > 0 ? base * (1 + (extraSavingPercent / 100.0)) : base;

    final ahorroQ = _roundUp(withExtra, rounding);
    return BudgetResult(
      ingresoQ: ingresoQ,
      gastosQ: gastosQ,
      colchonQ: colchonQ,
      ahorroQ: ahorroQ,
      ahorroMensual: ahorroQ * 2,
      ahorroAnual: ahorroQ * 24,
    );
  }
}
