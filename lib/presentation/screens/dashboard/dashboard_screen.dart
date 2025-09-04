import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/services/budget_calculator.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final result = ctrl.calculate();

    return Scaffold(
      appBar: AppBar(title: const Text('Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryCard(resultText: _formatResult(result)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String> _formatResult(BudgetResult? result) {
    if (result == null) {
      return {
        'Ingreso quincenal': '--',
        'Gastos fijos': '--',
        'Colchón': '--',
        'Ahorro sobrante': '--',
        'Ahorro mensual': '--',
        'Ahorro anual': '--',
      };
    }

    String f(num n) => '\$ ${n.toStringAsFixed(2)}';

    return {
      'Ingreso quincenal': f(result.ingresoQ),
      'Gastos fijos': f(result.gastosQ),
      'Colchón': f(result.colchonQ),
      'Ahorro sobrante': f(result.ahorroQ),
      'Ahorro mensual': f(result.ahorroMensual),
      'Ahorro anual': f(result.ahorroAnual),
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, String> resultText;
  const _SummaryCard({required this.resultText});

  @override
  Widget build(BuildContext context) {
    final items = resultText.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumen de quincena',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...items.map((e) => _RowItem(label: e.key, value: e.value)),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isAhorro = label.toLowerCase().contains('ahorro sobrante');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isAhorro ? FontWeight.bold : FontWeight.normal,
              color: isAhorro ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }
}
