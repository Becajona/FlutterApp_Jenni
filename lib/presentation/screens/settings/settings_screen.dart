import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../money/enums.dart';
import '../../../money/utils/formatters.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/settings.dart';
import '../../../notifications/notification_service.dart'; // ✅ para programar/cancelar recordatorios

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final s = ctrl.settings;
    final result = ctrl.calculate();

    // Valores base (si no hay cálculo aún, usa 0)
    final ahorroQBase = (result?.ahorroQ ?? 0).toDouble();

    // Helpers locales para la vista previa
    double _applyExtra(double base, double pct) => base + (base * (pct / 100.0));
    double _roundByMode(double n, RoundingMode m) {
      switch (m) {
        case RoundingMode.none:
          return n;
        case RoundingMode.up10:
          return _roundUpTo(n, 10);
        case RoundingMode.up50:
          return _roundUpTo(n, 50);
        case RoundingMode.up100:
          return _roundUpTo(n, 100);
      }
    }

    final ahorroTrasExtra = _applyExtra(ahorroQBase, s.extraSavingPercent);
    final ahorroRedondeadoQ = _roundByMode(ahorroTrasExtra, s.rounding);
    final ahorroMensualEstimado = ahorroRedondeadoQ * 2; // quincenal → mensual

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de ahorro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ahorro automático',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Añade un porcentaje extra a tu ahorro y opcionalmente redondéalo hacia arriba.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(.75),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // % extra de ahorro
                      Row(
                        children: [
                          Expanded(
                            child: Text('% extra de ahorro',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Text(
                            '${s.extraSavingPercent.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.extraSavingPercent.clamp(0, 100).toDouble(),
                        min: 0,
                        max: 50,
                        divisions: 50,
                        label: '${s.extraSavingPercent.toStringAsFixed(0)}%',
                        onChanged: (v) => context.read<BudgetController>().setExtraPercent(v),
                      ),

                      const SizedBox(height: 8),

                      // Redondeo
                      Text('Redondeo del ahorro quincenal',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _RoundChip(
                            label: 'Sin redondeo',
                            selected: s.rounding == RoundingMode.none,
                            onTap: () => context.read<BudgetController>().setRounding(RoundingMode.none),
                          ),
                          _RoundChip(
                            label: 'Múltiplo de \$10',
                            selected: s.rounding == RoundingMode.up10,
                            onTap: () => context.read<BudgetController>().setRounding(RoundingMode.up10),
                          ),
                          _RoundChip(
                            label: 'Múltiplo de \$50',
                            selected: s.rounding == RoundingMode.up50,
                            onTap: () => context.read<BudgetController>().setRounding(RoundingMode.up50),
                          ),
                          _RoundChip(
                            label: 'Múltiplo de \$100',
                            selected: s.rounding == RoundingMode.up100,
                            onTap: () => context.read<BudgetController>().setRounding(RoundingMode.up100),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Se aplica solo si el ahorro es positivo.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Vista previa
                      _PreviewPanel(
                        ahorroBaseQ: ahorroQBase,
                        ahorroTrasExtraQ: ahorroTrasExtra,
                        ahorroRedondeadoQ: ahorroRedondeadoQ,
                        ahorroMensual: ahorroMensualEstimado,
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),

                      // ====== ✅ Recordatorios quincenales ======
                      Text('Recordatorios',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),

                      SwitchListTile(
                        title: const Text('Recordatorios quincenales'),
                        subtitle: const Text('Se programan el día 1 y 16 de cada mes.'),
                        value: s.remindersEnabled,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) async {
                          await ctrl.setSettings(s.copyWith(remindersEnabled: v));
                          await NotificationService.init();
                          if (v) {
                            await NotificationService.scheduleQuincenal(
                              hour: s.reminderHour,
                              minute: s.reminderMinute,
                            );
                          } else {
                            await NotificationService.cancelAll();
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? 'Recordatorios activados'
                                  : 'Recordatorios desactivados'),
                            ),
                          );
                        },
                      ),

                      ListTile(
                        title: const Text('Hora de recordatorio'),
                        subtitle: Text(
                          '${s.reminderHour.toString().padLeft(2, '0')}:${s.reminderMinute.toString().padLeft(2, '0')}',
                        ),
                        contentPadding: EdgeInsets.zero,
                        enabled: s.remindersEnabled,
                        onTap: !s.remindersEnabled
                            ? null
                            : () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: s.reminderHour,
                                    minute: s.reminderMinute,
                                  ),
                                );
                                if (picked != null) {
                                  final ns = s.copyWith(
                                    reminderHour: picked.hour,
                                    reminderMinute: picked.minute,
                                  );
                                  await ctrl.setSettings(ns);
                                  await NotificationService.init();
                                  await NotificationService.scheduleQuincenal(
                                    hour: ns.reminderHour,
                                    minute: ns.reminderMinute,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hora de recordatorio actualizada'),
                                    ),
                                  );
                                }
                              },
                        trailing: const Icon(Icons.schedule),
                      ),

                      const SizedBox(height: 16),

                      // Botones
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.restore),
                            label: const Text('Restablecer'),
                            onPressed: () async {
                              final r = context.read<BudgetController>();
                              // restablecer ahorro y redondeo
                              r.setExtraPercent(0);
                              r.setRounding(RoundingMode.none);
                              // desactivar recordatorios y hora por defecto
                              final ns = s.copyWith(
                                remindersEnabled: false,
                                reminderHour: 9,
                                reminderMinute: 0,
                              );
                              await r.setSettings(ns);
                              await NotificationService.cancelAll();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ajustes restablecidos')),
                              );
                            },
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Hecho'),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
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

/// Chip de selección con estilo suave
class _RoundChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoundChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? cs.onPrimaryContainer : cs.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// Panel de vista previa con filas de monto
class _PreviewPanel extends StatelessWidget {
  final double ahorroBaseQ;
  final double ahorroTrasExtraQ;
  final double ahorroRedondeadoQ;
  final double ahorroMensual;

  const _PreviewPanel({
    required this.ahorroBaseQ,
    required this.ahorroTrasExtraQ,
    required this.ahorroRedondeadoQ,
    required this.ahorroMensual,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Row _row(String t, String v, {bool strong = false, Color? color}) => Row(
          children: [
            Expanded(child: Text(t)),
            Text(
              v,
              style: strong
                  ? theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: color)
                  : theme.textTheme.bodyMedium,
            ),
          ],
        );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vista previa',
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _row('Ahorro base quincenal', MoneyFmt.mx(ahorroBaseQ)),
          _row('Con % extra', MoneyFmt.mx(ahorroTrasExtraQ)),
          _row('Aplicando redondeo', MoneyFmt.mx(ahorroRedondeadoQ)),
          const Divider(height: 14),
          _row('Ahorro final QUINCENAL', MoneyFmt.mx(ahorroRedondeadoQ),
              strong: true, color: Colors.green.shade700),
          _row('Ahorro MENSUAL estimado', MoneyFmt.mx(ahorroMensual), strong: true),
        ],
      ),
    );
  }
}

/// Redondeo hacia arriba al múltiplo indicado (10, 50, 100)
double _roundUpTo(double n, int step) {
  if (step <= 0) return n;
  final m = (n / step).ceil();
  return m * step.toDouble();
}
