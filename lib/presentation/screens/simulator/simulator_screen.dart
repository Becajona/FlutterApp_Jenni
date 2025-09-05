import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../money/enums.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/services/budget_calculator.dart';
import '../../../money/utils/formatters.dart';
import '../../../domain/entities/emergency_config.dart'; // <-- FALTA ESTE IMPORT


class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  // sliders de simulación
  double? _overridePercent;     // para EmergencyMode.percent
  double? _overrideFixed;       // para EmergencyMode.fixed (monto quincenal)
  final Map<String, double> _flexCuts = {}; // id -> % reducción

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final base = ctrl.calculate();
    final income = ctrl.income;
    final emergency = ctrl.emergency ??
        const EmergencyConfig(mode: EmergencyMode.percent, value: 10, goalMonths: 3);
    final expenses = ctrl.expenses;

    if (income == null) {
      return const Scaffold(
        body: Center(child: Text('Primero configura tus ingresos')),
      );
    }

    // resultado simulado
    final sim = BudgetCalculator.simulate(
      income: income,
      emergency: emergency,
      expenses: expenses,
      extraSavingPercent: ctrl.settings.extraSavingPercent,
      rounding: ctrl.settings.rounding,
      overrideEmergencyPercent: emergency.mode == EmergencyMode.percent ? _overridePercent : null,
      overrideEmergencyFixed: emergency.mode == EmergencyMode.fixed ? _overrideFixed : null,
      flexibleCutsPct: _flexCuts.isEmpty ? null : _flexCuts,
    );

    // estimar meses para meta de fondo (goalMonths de gastos mensuales)
    // gastosMensuales = gastosQ * 2
    final gastosMensuales = sim.gastosQ * 2;
    final metaTotal = emergency.goalMonths * gastosMensuales;
    final ahorroMensual = sim.ahorroMensual;
    final mesesNecesarios = (ahorroMensual > 0) ? (metaTotal / ahorroMensual) : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Simulador')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colchón', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (emergency.mode == EmergencyMode.percent) ...[
                    Row(
                      children: [
                        const Expanded(child: Text('Porcentaje de colchón')),
                        Text('${(_overridePercent ?? emergency.value).toStringAsFixed(0)}%'),
                      ],
                    ),
                    Slider(
                      min: 0,
                      max: 50,
                      divisions: 50,
                      value: (_overridePercent ?? emergency.value).clamp(0, 50),
                      label: '${(_overridePercent ?? emergency.value).toStringAsFixed(0)}%',
                      onChanged: (v) => setState(() => _overridePercent = v),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Expanded(child: Text('Monto fijo de colchón (quincenal)')),
                        Text(MoneyFmt.mx((_overrideFixed ?? emergency.value))),
                      ],
                    ),
                    Slider(
                      min: 0,
                      max: (income.amount * 1.0),
                      divisions: 100,
                      value: (_overrideFixed ?? emergency.value).clamp(0, income.amount),
                      onChanged: (v) => setState(() => _overrideFixed = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recortes en categorías FLEXIBLES', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (expenses.where((e) => e.isFlexible).isEmpty)
                    const Text('No tienes gastos marcados como flexibles.'),
                  ...expenses.where((e) => e.isFlexible).map((e) {
                    final current = _flexCuts[e.id] ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${e.name} (${e.category})')),
                            Text('-${current.toStringAsFixed(0)}%'),
                          ],
                        ),
                        Slider(
                          value: current,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '-${current.toStringAsFixed(0)}%',
                          onChanged: (v) => setState(() => _flexCuts[e.id] = v),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ResultDelta(base: base, sim: sim, mesesNecesarios: mesesNecesarios.isFinite ? mesesNecesarios : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDelta extends StatelessWidget {
  final BudgetResult? base;
  final BudgetResult sim;
  final double? mesesNecesarios;
  const _ResultDelta({required this.base, required this.sim, required this.mesesNecesarios});

  @override
  Widget build(BuildContext context) {
    String f(num n) => MoneyFmt.mx(n);
    String d(num a, num b) {
      final diff = a - b;
      final sign = diff >= 0 ? '+' : '-';
      return '$sign${f(diff.abs())}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resultado simulado', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _row('Ingreso quincenal', f(sim.ingresoQ), base != null ? d(sim.ingresoQ, base!.ingresoQ) : ''),
        _row('Gastos fijos Q',     f(sim.gastosQ),  base != null ? d(base!.gastosQ, sim.gastosQ)  : ''),
        _row('Colchón Q',          f(sim.colchonQ), base != null ? d(base!.colchonQ, sim.colchonQ): ''),
        const Divider(),
        _row('Ahorro quincenal',   f(sim.ahorroQ),  base != null ? d(sim.ahorroQ, base!.ahorroQ)  : ''),
        _row('Ahorro mensual',     f(sim.ahorroMensual), base != null ? d(sim.ahorroMensual, base!.ahorroMensual) : ''),
        _row('Ahorro anual',       f(sim.ahorroAnual),   base != null ? d(sim.ahorroAnual, base!.ahorroAnual)     : ''),
        const SizedBox(height: 12),
        if (mesesNecesarios != null)
          Text(
            'Meses estimados para completar el fondo: ${mesesNecesarios!.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          const Text('No es posible estimar la fecha (ahorro mensual ≤ 0).'),
      ],
    );
  }

  Widget _row(String label, String value, String delta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (delta.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(delta, style: const TextStyle(color: Colors.blueGrey)),
          ]
        ],
      ),
    );
  }
}
