import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../money/enums.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/emergency_config.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _form = GlobalKey<FormState>();
  EmergencyMode _mode = EmergencyMode.percent;
  final _valueCtrl = TextEditingController(text: '10'); 
  final _goalCtrl  = TextEditingController(text: '3');  
  bool _loading = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.read<BudgetController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Colchón (Fondo de emergencia)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Configura tu colchón',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    SegmentedButton<EmergencyMode>(
                      segments: const [
                        ButtonSegment(
                          value: EmergencyMode.percent,
                          label: Text('Porcentaje'),
                          icon: Icon(Icons.percent),
                        ),
                        ButtonSegment(
                          value: EmergencyMode.fixed,
                          label: Text('Monto fijo (quincenal)'),
                          icon: Icon(Icons.attach_money),
                        ),
                      ],
                      selected: <EmergencyMode>{_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _mode == EmergencyMode.percent
                            ? 'Porcentaje de ingreso'
                            : 'Monto fijo por quincena',
                        suffixText:
                            _mode == EmergencyMode.percent ? '%' : 'MXN',
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Valor inválido';
                        if (_mode == EmergencyMode.percent && (n > 100)) {
                          return 'El porcentaje debe ser ≤ 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _goalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Meta de meses de gastos (3–6 recomendado)',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingresa un entero válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (!_form.currentState!.validate()) return;
                              setState(() => _loading = true);

                              final value =
                                  double.parse(_valueCtrl.text.replaceAll(',', '.'));
                              final goal = int.parse(_goalCtrl.text);
                              budget.setEmergency(EmergencyConfig(
                                mode: _mode,
                                value: value,
                                goalMonths: goal,
                              ));

                              setState(() => _loading = false);
                             
                              context.go('/home');
                            },
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Guardar y continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
