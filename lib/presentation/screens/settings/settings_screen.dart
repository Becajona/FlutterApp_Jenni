import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../money/enums.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final s = ctrl.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de ahorro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ahorro automático', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('% extra de ahorro')),
                      Text('${s.extraSavingPercent.toStringAsFixed(0)}%'),
                    ],
                  ),
                  Slider(
                    value: s.extraSavingPercent.clamp(0, 100),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: '${s.extraSavingPercent.toStringAsFixed(0)}%',
                    onChanged: (v) => context.read<BudgetController>().setExtraPercent(v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RoundingMode>(
                    value: s.rounding,
                    decoration: const InputDecoration(labelText: 'Redondeo del ahorro quincenal'),
                    items: const [
                      DropdownMenuItem(value: RoundingMode.none,  child: Text('Sin redondeo')),
                      DropdownMenuItem(value: RoundingMode.up10,  child: Text('Al múltiplo de \$10')),
                      DropdownMenuItem(value: RoundingMode.up50,  child: Text('Al múltiplo de \$50')),
                      DropdownMenuItem(value: RoundingMode.up100, child: Text('Al múltiplo de \$100')),
                    ],
                    onChanged: (m) => context.read<BudgetController>().setRounding(m ?? RoundingMode.none),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Se aplica solo si el ahorro es positivo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
