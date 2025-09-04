// lib/presentation/screens/expenses/expenses_crud_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../money/enums.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/expense.dart';

class ExpensesCrudScreen extends StatelessWidget {
  const ExpensesCrudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final expenses = ctrl.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos fijos'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                'Total Q: \$${ctrl.totalExpensesQuincena.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<Expense>(
            context: context,
            builder: (_) => ExpenseDialog(),
          );
          if (created != null) {
            context.read<BudgetController>().addExpense(created);
          }
        },
        label: const Text('Agregar'),
        icon: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = expenses[i];
          final q = _toQuincena(e.amount, e.frequency);
          return ListTile(
            leading: Icon(e.isFlexible ? Icons.tune : Icons.lock),
            title: Text(e.name),
            subtitle: Text(
              '${e.category} • ${_frecText(e.frequency)} • '
              'Base: \$${e.amount.toStringAsFixed(2)} | Q: \$${q.toStringAsFixed(2)}'
              '${e.note != null && e.note!.isNotEmpty ? '\n${e.note}' : ''}',
            ),
            isThreeLine: e.note != null && e.note!.isNotEmpty,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updated = await showDialog<Expense>(
                      context: context,
                      builder: (_) => ExpenseDialog(expense: e),
                    );
                    if (updated != null) {
                      context.read<BudgetController>().updateExpense(updated);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, e.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static double _toQuincena(double amount, Frequency f) {
    switch (f) {
      case Frequency.quincenal: return amount;
      case Frequency.mensual:   return amount / 2;
      case Frequency.anual:     return amount / 24;
    }
  }

  static String _frecText(Frequency f) {
    switch (f) {
      case Frequency.quincenal: return 'Quincenal';
      case Frequency.mensual:   return 'Mensual';
      case Frequency.anual:     return 'Anual';
    }
  }

  void _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: const Text('¿Seguro que quieres eliminar este gasto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      context.read<BudgetController>().removeExpense(id);
    }
  }
}

class ExpenseDialog extends StatefulWidget {
  final Expense? expense;
  ExpenseDialog({super.key, this.expense});

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  Frequency _freq = Frequency.mensual;
  bool _flexible = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _name.text = e.name;
      _amount.text = e.amount.toStringAsFixed(2);
      _category.text = e.category;
      _note.text = e.note ?? '';
      _freq = e.frequency;
      _flexible = e.isFlexible;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? 'Nuevo gasto' : 'Editar gasto'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. Renta, Luz, Internet)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto'),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Frequency>(
                  value: _freq,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: const [
                    DropdownMenuItem(value: Frequency.quincenal, child: Text('Quincenal')),
                    DropdownMenuItem(value: Frequency.mensual, child: Text('Mensual')),
                    DropdownMenuItem(value: Frequency.anual, child: Text('Anual')),
                  ],
                  onChanged: (v) => setState(() => _freq = v ?? Frequency.mensual),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _flexible,
                  onChanged: (v) => setState(() => _flexible = v),
                  title: const Text('Flexible (se puede recortar en modo prioridades)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final id = widget.expense?.id ?? const Uuid().v4();
            final e = Expense(
              id: id,
              name: _name.text.trim(),
              amount: double.parse(_amount.text.replaceAll(',', '.')),
              frequency: _freq,
              category: _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              isFlexible: _flexible,
            );
            Navigator.pop(context, e);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
