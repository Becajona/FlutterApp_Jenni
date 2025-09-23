import '../../money/enums.dart';

class PeriodSnapshot {
  final String id;            // ej. 2025-03-1  (AAAA-MM-{1|2})
  final DateTime createdAt;
  // resúmenes
  final double ingresoQ;
  final double gastosQ;
  final double colchonQ;
  final double ahorroQ;
  final double ahorroMensual;

  // opcional: guardar contexto usado
  final double extraSavingPercent;
  final RoundingMode rounding;

  const PeriodSnapshot({
    required this.id,
    required this.createdAt,
    required this.ingresoQ,
    required this.gastosQ,
    required this.colchonQ,
    required this.ahorroQ,
    required this.ahorroMensual,
    required this.extraSavingPercent,
    required this.rounding,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'ingresoQ': ingresoQ,
        'gastosQ': gastosQ,
        'colchonQ': colchonQ,
        'ahorroQ': ahorroQ,
        'ahorroMensual': ahorroMensual,
        'extraSavingPercent': extraSavingPercent,
        'rounding': rounding.name,
      };

  factory PeriodSnapshot.fromMap(Map<String, dynamic> m) => PeriodSnapshot(
        id: m['id'] as String,
        createdAt: DateTime.tryParse(m['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
        ingresoQ: (m['ingresoQ'] ?? 0).toDouble(),
        gastosQ: (m['gastosQ'] ?? 0).toDouble(),
        colchonQ: (m['colchonQ'] ?? 0).toDouble(),
        ahorroQ: (m['ahorroQ'] ?? 0).toDouble(),
        ahorroMensual: (m['ahorroMensual'] ?? 0).toDouble(),
        extraSavingPercent: (m['extraSavingPercent'] ?? 0).toDouble(),
        rounding: RoundingMode.values.firstWhere(
          (r) => r.name == (m['rounding'] ?? RoundingMode.none.name),
        ),
      );
}
