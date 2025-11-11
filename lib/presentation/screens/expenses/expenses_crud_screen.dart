// lib/presentation/screens/expenses/expenses_crud_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../money/enums.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/expense.dart';
import '../../../money/utils/formatters.dart';

class ExpensesCrudScreen extends StatelessWidget {
  const ExpensesCrudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = context.watch<BudgetController>();
    final expenses = ctrl.expenses;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(),

        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Gastos fijos'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: _Pill(
                icon: Icons.account_balance_wallet_outlined,
                text: 'Total Q: ${MoneyFmt.mx(ctrl.totalExpensesQuincena)}',
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
        onPressed: () async {
          final created = await showDialog<Expense>(
            context: context,
            builder: (_) => const ExpenseDialog(),
          );
          if (created != null) {
            // lógica intacta
            // ignore: use_build_context_synchronously
            context.read<BudgetController>().addExpense(created);
          }
        },
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(.06), cs.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            child: expenses.isEmpty
                ? const _EmptyState()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SummaryCard(totalQ: ctrl.totalExpensesQuincena),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverList.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = expenses[i];
                          final q = _toQuincena(e.amount, e.frequency);
                          final leadingColor = e.isFlexible ? cs.tertiary : cs.primary;

                          return _ExpenseCard(
                            iconColor: leadingColor,
                            title: e.name,
                            category: e.category,
                            frequency: _frecText(e.frequency),
                            baseAmount: MoneyFmt.mx(e.amount),
                            quincenaAmount: MoneyFmt.mx(q),
                            note: e.note,
                            flexible: e.isFlexible,
                            onEdit: () async {
                              final updated = await showDialog<Expense>(
                                context: context,
                                builder: (_) => ExpenseDialog(expense: e),
                              );
                              if (updated != null) {
                                // ignore: use_build_context_synchronously
                                context.read<BudgetController>().updateExpense(updated);
                              }
                            },
                            onDelete: () => _confirmDelete(context, e.id),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ===== Helpers (lógica intacta)
  static double _toQuincena(double amount, Frequency f) {
    switch (f) {
      case Frequency.quincenal:
        return amount;
      case Frequency.mensual:
        return amount / 2;
      case Frequency.anual:
        return amount / 24;
    }
  }

  static String _frecText(Frequency f) {
    switch (f) {
      case Frequency.quincenal:
        return 'Quincenal';
      case Frequency.mensual:
        return 'Mensual';
      case Frequency.anual:
        return 'Anual';
    }
  }

  void _confirmDelete(BuildContext context, String id) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: cs.error),
            const SizedBox(width: 8),
            const Text('Eliminar gasto'),
          ],
        ),
        content: const Text('¿Seguro que quieres eliminar este gasto?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      // ignore: use_build_context_synchronously
      context.read<BudgetController>().removeExpense(id);
    }
  }
}

/* ───────────────────── UI Widgets ───────────────────── */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalQ});
  final double totalQ;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surfaceVariant.withOpacity(.28), cs.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.stacked_bar_chart_rounded, color: cs.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen por quincena',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.70),
                      )),
                  const SizedBox(height: 2),
                  Text(
                    MoneyFmt.mx(totalQ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                    ),
                  ),
                ],
              ),
            ),
            _Pill(
              icon: Icons.trending_flat_rounded,
              text: 'Actualizado',
              color: cs.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.iconColor,
    required this.title,
    required this.category,
    required this.frequency,
    required this.baseAmount,
    required this.quincenaAmount,
    required this.note,
    required this.flexible,
    required this.onEdit,
    required this.onDelete,
  });

  final Color iconColor;
  final String title;
  final String category;
  final String frequency;
  final String baseAmount;
  final String quincenaAmount;
  final String? note;
  final bool flexible;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surfaceVariant.withOpacity(.24), cs.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                flexible ? Icons.tune_rounded : Icons.lock_rounded,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y acciones
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      if (flexible) _SoftChip(text: 'Flexible', color: cs.tertiary),
                      const SizedBox(width: 6),
                      _IconBtn(icon: Icons.edit_rounded, tooltip: 'Editar', onTap: onEdit),
                      const SizedBox(width: 6),
                      _IconBtn(icon: Icons.delete_outline_rounded, tooltip: 'Eliminar', onTap: onDelete),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Chips de metadatos
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ChipMeta(icon: Icons.category_rounded, label: category, color: cs.secondary),
                      _ChipMeta(icon: Icons.schedule_rounded, label: frequency, color: cs.primary),
                      _ChipMeta(icon: Icons.payments_rounded, label: 'Base: $baseAmount', color: cs.tertiary),
                      _ChipMeta(icon: Icons.account_balance_wallet_outlined, label: 'Q: $quincenaAmount', color: cs.primary),
                    ],
                  ),

                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.72),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─────────────── Diálogo estilizado (misma lógica) ─────────────── */

class ExpenseDialog extends StatefulWidget {
  final Expense? expense;
  const ExpenseDialog({super.key, this.expense});

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    InputDecoration _dec(String label, {IconData? icon, String? hint, String? suffix}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.expense == null ? Icons.add_rounded : Icons.edit_rounded,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(widget.expense == null ? 'Nuevo gasto' : 'Editar gasto'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _SectionHeader(text: 'Datos básicos'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  decoration: _dec('Nombre', icon: Icons.receipt_long_rounded, hint: 'Renta, Luz, Internet'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Monto', icon: Icons.payments_rounded, suffix: 'MXN'),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n <= 0) return 'Monto inválido';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Frequency>(
                  value: _freq,
                  decoration: _dec('Frecuencia', icon: Icons.schedule_rounded),
                  items: const [
                    DropdownMenuItem(value: Frequency.quincenal, child: Text('Quincenal')),
                    DropdownMenuItem(value: Frequency.mensual, child: Text('Mensual')),
                    DropdownMenuItem(value: Frequency.anual, child: Text('Anual')),
                  ],
                  onChanged: (v) => setState(() => _freq = v ?? Frequency.mensual),
                ),
                const SizedBox(height: 16),
                _SectionHeader(text: 'Clasificación'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _category,
                  decoration: _dec('Categoría', icon: Icons.category_rounded, hint: 'Hogar, Servicios, Transporte…'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _note,
                  decoration: _dec('Nota (opcional)', icon: Icons.notes_rounded),
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  value: _flexible,
                  onChanged: (v) => setState(() => _flexible = v),
                  title: const Text('Flexible (se puede recortar en modo prioridades)'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    _flexible ? Icons.tune_rounded : Icons.lock_rounded,
                    color: _flexible ? cs.tertiary : cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
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

/* ──────────── Utilitarios de estilo ──────────── */

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: .1),
      ),
    );
  }
}

class _ChipMeta extends StatelessWidget {
  const _ChipMeta({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 40,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withOpacity(.20)),
        ),
        child: Text(
          text,
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: .1),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes gastos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega tus gastos fijos para ver su impacto por quincena.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.7),
                ),
          ),
        ],
      ),
    );
  }
}
