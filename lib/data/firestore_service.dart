// lib/data/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../money/enums.dart';
import '../domain/entities/income_config.dart';
import '../domain/entities/emergency_config.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/settings.dart' as app; // <<--- alias para evitar conflicto

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  // ----- SAVE -----
  Future<void> saveIncome(String uid, IncomeConfig income) async {
    await _userRef(uid).collection('core').doc('income').set({
      'amount': income.amount,
      'frequency': income.frequency.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveEmergency(String uid, EmergencyConfig e) async {
    await _userRef(uid).collection('core').doc('emergency').set({
      'mode': e.mode.name,
      'value': e.value,
      'goalMonths': e.goalMonths,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveSettings(String uid, app.Settings s) async {
    await _userRef(uid).collection('core').doc('settings').set({
      'extraSavingPercent': s.extraSavingPercent,
      'rounding': s.rounding.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addExpense(String uid, Expense e) async {
    await _userRef(uid).collection('expenses').doc(e.id).set({
      'name': e.name,
      'amount': e.amount,
      'frequency': e.frequency.name,
      'category': e.category,
      'note': e.note,
      'isFlexible': e.isFlexible,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense(String uid, Expense e) async => addExpense(uid, e);

  Future<void> deleteExpense(String uid, String id) async {
    await _userRef(uid).collection('expenses').doc(id).delete();
  }

  // ----- LOAD -----
  Future<IncomeConfig?> loadIncome(String uid) async {
    final doc = await _userRef(uid).collection('core').doc('income').get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return IncomeConfig(
      amount: (d['amount'] ?? 0).toDouble(),
      frequency: Frequency.values.firstWhere((f) => f.name == d['frequency']),
    );
  }

  Future<EmergencyConfig?> loadEmergency(String uid) async {
    final doc = await _userRef(uid).collection('core').doc('emergency').get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return EmergencyConfig(
      mode: EmergencyMode.values.firstWhere((m) => m.name == d['mode']),
      value: (d['value'] ?? 0).toDouble(),
      goalMonths: (d['goalMonths'] ?? 3) as int,
    );
  }

  Future<app.Settings?> loadSettings(String uid) async {
    final doc = await _userRef(uid).collection('core').doc('settings').get();
    if (!doc.exists) return const app.Settings();
    final d = doc.data()!;
    return app.Settings(
      extraSavingPercent: (d['extraSavingPercent'] ?? 0).toDouble(),
      rounding: RoundingMode.values.firstWhere(
        (r) => r.name == (d['rounding'] ?? RoundingMode.none.name),
      ),
    );
  }

  Future<List<Expense>> loadExpenses(String uid) async {
    final q = await _userRef(uid)
        .collection('expenses')
        .orderBy('updatedAt', descending: true)
        .get();
    return q.docs.map((doc) {
      final d = doc.data();
      return Expense(
        id: doc.id,
        name: d['name'] ?? '',
        amount: (d['amount'] ?? 0).toDouble(),
        frequency: Frequency.values.firstWhere((f) => f.name == d['frequency']),
        category: d['category'] ?? 'General',
        note: d['note'],
        isFlexible: (d['isFlexible'] ?? false) as bool,
      );
    }).toList();
  }
}
