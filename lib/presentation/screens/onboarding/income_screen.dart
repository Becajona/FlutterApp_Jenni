import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../money/enums.dart';
import '../../controllers/budget_controller.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});
  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _form = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  Frequency _freq = Frequency.quincenal;
  bool _loading = false;

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final budget = context.read<BudgetController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Configura tus ingresos', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixText: '\$ ',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                          if (n == null || n <= 0) return 'Ingresa un monto válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Frequency>(
                        value: _freq,
                        decoration: const InputDecoration(labelText: 'Frecuencia'),
                        items: const [
                          DropdownMenuItem(value: Frequency.quincenal, child: Text('Quincenal')),
                          DropdownMenuItem(value: Frequency.mensual, child: Text('Mensual')),
                          DropdownMenuItem(value: Frequency.anual, child: Text('Anual')),
                        ],
                        onChanged: (v) => setState(() => _freq = v ?? Frequency.quincenal),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : () {
                          if (!_form.currentState!.validate()) return;
                          setState(() => _loading = true);
                          final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
                          budget.setIncome(amount, _freq);
                          setState(() => _loading = false);
                          context.go('/onb/emergency'); 
                        },
                        child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Guardar y continuar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
