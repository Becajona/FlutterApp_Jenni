import 'package:flutter/foundation.dart';

import '../../money/enums.dart';
import '../../domain/entities/income_config.dart';
import '../../domain/entities/emergency_config.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/settings.dart';
import '../../domain/services/budget_calculator.dart';

// Firebase (auth + store)
import '../../auth/auth_repository.dart';
import '../../data/firestore_service.dart';

// Historial de quincenas
import '../../domain/entities/period_snapshot.dart';

/// Helper para id de quincena (1 = 1–15, 2 = resto)
String currentPeriodId(DateTime now) {
  final q = now.day <= 15 ? 1 : 2;
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  return '$y-$m-$q';
}

class BudgetController extends ChangeNotifier {
  // ---------- Inyección de dependencias (Auth + Firestore) ----------
  late AuthRepository auth;
  late FirestoreService store;

  BudgetController({AuthRepository? auth, FirestoreService? store}) {
    if (auth != null && store != null) {
      bind(auth: auth, store: store);
    }
  }

  /// Llamado desde main.dart (ProxyProvider.update)
  void bind({required AuthRepository auth, required FirestoreService store}) {
    this.auth = auth;
    this.store = store;
  }

  // ------------------ Estado principal ------------------
  IncomeConfig? _income;
  EmergencyConfig? _emergency;
  final List<Expense> _expenses = [];
  Settings _settings = const Settings();

  // Historial en memoria (cache simple)
  List<PeriodSnapshot> _history = [];
  List<PeriodSnapshot> get history => List.unmodifiable(_history);

  // Getters
  IncomeConfig? get income => _income;
  EmergencyConfig? get emergency => _emergency;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  Settings get settings => _settings;

  // 👇 ESTE getter lo usa el router
  bool get hasMinimumSetup => _income != null;
  bool get isFullyConfigured => _income != null && _emergency != null;

  // ------------------ Carga desde la nube / Reset local ------------------
  Future<void> loadFromCloud() async {
    final uid = auth.uid;
    if (uid == null) return;

    _income = await store.loadIncome(uid);
    _emergency = await store.loadEmergency(uid);
    _settings = (await store.loadSettings(uid)) ?? const Settings();

    _expenses
      ..clear()
      ..addAll(await store.loadExpenses(uid));

    // cargar historial
    _history = await store.listSnapshots(uid);

    notifyListeners();
  }

  void resetLocal() {
    _income = null;
    _emergency = null;
    _settings = const Settings();
    _expenses.clear();
    _history = [];
    notifyListeners();
  }

  // ------------------ Setters / acciones (con persistencia) ------------------
  Future<void> setIncome(double amount, Frequency frequency) async {
    _income = IncomeConfig(amount: amount, frequency: frequency);
    notifyListeners();

    final uid = auth.uid;
    if (uid != null) await store.saveIncome(uid, _income!);
  }

  Future<void> setEmergency(EmergencyConfig cfg) async {
    _emergency = cfg;
    notifyListeners();

    final uid = auth.uid;
    if (uid != null) await store.saveEmergency(uid, cfg);
  }

  Future<void> setSettings(Settings s) async {
    _settings = s;
    notifyListeners();

    final uid = auth.uid;
    if (uid != null) await store.saveSettings(uid, s);
  }

  void setExtraPercent(double p) =>
      setSettings(_settings.copyWith(extraSavingPercent: p));

  void setRounding(RoundingMode mode) =>
      setSettings(_settings.copyWith(rounding: mode));

  // ------------------ CRUD de gastos (con persistencia) ------------------
  Future<void> addExpense(Expense e) async {
    _expenses.add(e);
    notifyListeners();

    final uid = auth.uid;
    if (uid != null) await store.addExpense(uid, e);
  }

  Future<void> updateExpense(Expense e) async {
    final i = _expenses.indexWhere((x) => x.id == e.id);
    if (i != -1) {
      _expenses[i] = e;
      notifyListeners();

      final uid = auth.uid;
      if (uid != null) await store.updateExpense(uid, e);
    }
  }

  Future<void> removeExpense(String id) async {
    _expenses.removeWhere((x) => x.id == id);
    notifyListeners();

    final uid = auth.uid;
    if (uid != null) await store.deleteExpense(uid, id);
  }

  // ------------------ Utilidades ------------------
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
      extraSavingPercent: _settings.extraSavingPercent,
      rounding: _settings.rounding,
    );
  }

  // ------------------ Historial (cierres de quincena) ------------------
  /// Cierra la quincena actual y guarda snapshot en Firestore.
  /// Devuelve el id del periodo cerrado.
  Future<String?> closeCurrentPeriod() async {
    final uid = auth.uid;
    if (uid == null) return null;

    final res = calculate();
    if (res == null) return null;

    final pid = currentPeriodId(DateTime.now());
    final exists = await store.periodExists(uid, pid);
    if (exists) return pid; // ya cerrado

    final snap = PeriodSnapshot(
      id: pid,
      createdAt: DateTime.now(),
      ingresoQ: res.ingresoQ,
      gastosQ: res.gastosQ,
      colchonQ: res.colchonQ,
      ahorroQ: res.ahorroQ,
      ahorroMensual: res.ahorroMensual,
      extraSavingPercent: _settings.extraSavingPercent,
      rounding: _settings.rounding,
    );

    await store.savePeriodSnapshot(uid, snap);
    await loadHistory();
    return pid;
  }

  Future<void> loadHistory() async {
    final uid = auth.uid;
    if (uid == null) return;
    _history = await store.listSnapshots(uid);
    notifyListeners();
  }

  Future<void> deletePeriod(String periodId) async {
    final uid = auth.uid;
    if (uid == null) return;
    await store.deleteSnapshot(uid, periodId);
    await loadHistory();
  }
}
