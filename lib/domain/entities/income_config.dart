import 'package:equatable/equatable.dart';
import '../../money/enums.dart';

class IncomeConfig extends Equatable {
  final double amount;
  final Frequency frequency;

  const IncomeConfig({required this.amount, required this.frequency});

  IncomeConfig copyWith({double? amount, Frequency? frequency}) =>
      IncomeConfig(amount: amount ?? this.amount, frequency: frequency ?? this.frequency);

  @override
  List<Object?> get props => [amount, frequency];
}
