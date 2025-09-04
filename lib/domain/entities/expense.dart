import 'package:equatable/equatable.dart';
import '../../money/enums.dart';

class Expense extends Equatable {
  final String id;
  final String name;
  final double amount;
  final Frequency frequency;
  final String category;
  final String? note;
  final bool isFlexible;

  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.category,
    this.note,
    this.isFlexible = false,
  });

  @override
  List<Object?> get props => [id, name, amount, frequency, category, note, isFlexible];
}
