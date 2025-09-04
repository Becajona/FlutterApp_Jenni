import 'package:equatable/equatable.dart';
import '../../money/enums.dart';

class EmergencyConfig extends Equatable {
  final EmergencyMode mode; // percent | fixed
  final double value;       // % o monto quincenal
  final int goalMonths;     // meta: 3–6 meses de gastos

  const EmergencyConfig({
    required this.mode,
    required this.value,
    required this.goalMonths,
  });

  @override
  List<Object?> get props => [mode, value, goalMonths];
}
