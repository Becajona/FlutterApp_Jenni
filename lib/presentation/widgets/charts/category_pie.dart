import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../money/utils/formatters.dart';
import '../../controllers/budget_controller.dart';
import 'package:provider/provider.dart';
import '../../../money/enums.dart';
import '../../../domain/entities/expense.dart';

class CategoryPie extends StatelessWidget {
  const CategoryPie({super.key});

  static double _toQ(Expense e) {
    switch (e.frequency) {
      case Frequency.quincenal: return e.amount;
      case Frequency.mensual:   return e.amount / 2;
      case Frequency.anual:     return e.amount / 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<BudgetController>().expenses;

    final Map<String, double> byCat = {};
    for (final e in expenses) {
      byCat[e.category] = (byCat[e.category] ?? 0) + _toQ(e);
    }
    final total = byCat.values.fold<double>(0, (a, b) => a + b);

    if (total == 0) {
      return const Center(child: Text('Sin gastos para graficar'));
    }

    final colors = Theme.of(context).colorScheme;
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      sections.add(
        PieChartSectionData(
          value: e.value,
          title: '${(e.value / total * 100).toStringAsFixed(0)}%',
          radius: 70,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          color: Colors.primaries[i % Colors.primaries.length],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gastos por categoría (Q)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 24)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (int i = 0; i < entries.length; i++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, color: Colors.primaries[i % Colors.primaries.length]),
                const SizedBox(width: 6),
                Text('${entries[i].key}: ${MoneyFmt.mx(entries[i].value)}'),
              ]),
          ],
        ),
      ],
    );
  }
}
