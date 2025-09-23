import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/budget_controller.dart';
import '../../../money/utils/formatters.dart';
import '../../../domain/services/budget_calculator.dart';

import '../../../domain/entities/emergency_config.dart';
import '../../../money/enums.dart';

class EmergencyProgress extends StatelessWidget {
  const EmergencyProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final res = ctrl.calculate();
    if (res == null) {
      return const Center(child: Text('Configura ingresos para ver progreso'));
    }

    final emer = ctrl.emergency ??
        const EmergencyConfig(
          mode: EmergencyMode.percent,
          value: 10,
          goalMonths: 3,
        );

    final gastosMensuales = res.gastosQ * 2;
    final meta = emer.goalMonths * gastosMensuales;

    final ahorroMensual = res.ahorroMensual;
    final pct = meta > 0 ? (ahorroMensual / meta).clamp(0, 1).toDouble() : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progreso meta de emergencia',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: pct),
        const SizedBox(height: 6),
        Text(
          'Meta: ${MoneyFmt.mx(meta)}  •  Ahorro mensual: ${MoneyFmt.mx(ahorroMensual)}',
        ),
      ],
    );
  }
}
