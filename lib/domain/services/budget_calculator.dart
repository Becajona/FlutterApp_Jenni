import '../../money/enums.dart';                 // Frequency, EmergencyMode, RoundingMode
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
    if (value <= 0) return value; // no redondear negativos o cero
    switch (mode) {
      case RoundingMode.none:  return value;
      case RoundingMode.up10:  return (value / 10).ceil() * 10;
      case RoundingMode.up50:  return (value / 50).ceil() * 50;
      case RoundingMode.up100: return (value / 100).ceil() * 100;
    }
  }

  // ---- CÁLCULO NORMAL (usa estado actual) -----------------------------------
  static BudgetResult calculate({
    required IncomeConfig income,
    required EmergencyConfig emergency,
    required List<Expense> expenses,
    double extraSavingPercent = 0,           // 0–100
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

  // ---- SIMULADOR (no modifica estado; aplica overrides temporales) ----------
  static BudgetResult simulate({
    required IncomeConfig income,
    required EmergencyConfig emergency,
    required List<Expense> expenses,
    double extraSavingPercent = 0,           // 0–100
    RoundingMode rounding = RoundingMode.none,

    // Overrides de simulación:
    double? overrideEmergencyPercent,        // si emergency.mode == percent
    double? overrideEmergencyFixed,          // si emergency.mode == fixed (monto quincenal)
    Map<String, double>? flexibleCutsPct,    // {expenseId: 0..100} reducción %
  }) {
    // 1) Copiar gastos aplicando recortes a los flexibles
    final adjExpenses = expenses.map((e) {
      final cut = (flexibleCutsPct ?? const {})[e.id] ?? 0;
      if (cut <= 0) return e;
      final factor = (100 - cut) / 100.0;
      return Expense(
        id: e.id,
        name: e.name,
        amount: e.amount * factor,
        frequency: e.frequency,
        category: e.category,
        note: e.note,
        isFlexible: e.isFlexible,
      );
    }).toList();

    // 2) Override del colchón (si corresponde)
    final emer =
        (emergency.mode == EmergencyMode.percent && overrideEmergencyPercent != null)
            ? EmergencyConfig(
                mode: EmergencyMode.percent,
                value: overrideEmergencyPercent,
                goalMonths: emergency.goalMonths,
              )
            : (emergency.mode == EmergencyMode.fixed && overrideEmergencyFixed != null)
                ? EmergencyConfig(
                    mode: EmergencyMode.fixed,
                    value: overrideEmergencyFixed,
                    goalMonths: emergency.goalMonths,
                  )
                : emergency;

    // 3) Reusar el cálculo normal con los ajustes simulados
    return calculate(
      income: income,
      emergency: emer,
      expenses: adjExpenses,
      extraSavingPercent: extraSavingPercent,
      rounding: rounding,
    );
  }
}
