import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/budget_controller.dart';
import '../../../money/utils/formatters.dart';

class AnnualProjection extends StatelessWidget {
  const AnnualProjection({super.key});

  @override
  Widget build(BuildContext context) {
    final res = context.watch<BudgetController>().calculate();
    if (res == null) return const SizedBox();

    // ahorro mensual constante -> 12 barras
    final monthly = res.ahorroMensual;
    final bars = List.generate(12, (i) => BarChartGroupData(
      x: i,
      barRods: [BarChartRodData(toY: monthly)],
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proyección anual de ahorro', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            barGroups: bars,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                getTitlesWidget: (v, _) => Text(MoneyFmt.mx(v), style: const TextStyle(fontSize: 10)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                getTitlesWidget: (v, _) => Text(['E','F','M','A','M','J','J','A','S','O','N','D'][v.toInt()%12]),
              )),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          )),
        ),
      ],
    );
  }
}
