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
      case Frequency.quincenal:
        return amount;
      case Frequency.mensual:
        return amount / 2;
      case Frequency.anual:
        return amount / 24;
    }
  }

  static BudgetResult calculate({
    required IncomeConfig income,
    required EmergencyConfig emergency,
    required List<Expense> expenses,
    double extraSavingPercent = 0,
  }) {
    final ingresoQ = _toQuincena(income.amount, income.frequency);
    final gastosQ =
        expenses.fold<double>(0, (sum, e) => sum + _toQuincena(e.amount, e.frequency));

    final colchonQ = emergency.mode == EmergencyMode.percent
        ? ingresoQ * (emergency.value / 100.0)
        : emergency.value;

    final base = ingresoQ - gastosQ - colchonQ;
    final ahorroQ = base + (base > 0 ? base * (extraSavingPercent / 100.0) : 0);

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
