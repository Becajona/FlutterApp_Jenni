// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';

import '../../../money/enums.dart';
import '../../../money/utils/formatters.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/settings.dart';
import '../../../notifications/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final s = ctrl.settings;
    final result = ctrl.calculate();

    final ahorroQBase = (result?.ahorroQ ?? 0).toDouble();

    double _applyExtra(double base, double pct) =>
        base + (base * (pct / 100.0));
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
    final ahorroMensualEstimado = ahorroRedondeadoQ * 2;

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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _SettingsForm(
                    current: s,
                    ahorroBaseQ: ahorroQBase,
                    ahorroTrasExtraQ: ahorroTrasExtra,
                    ahorroRedondeadoQ: ahorroRedondeadoQ,
                    ahorroMensual: ahorroMensualEstimado,
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

class _SettingsForm extends StatefulWidget {
  final Settings current;
  final double ahorroBaseQ;
  final double ahorroTrasExtraQ;
  final double ahorroRedondeadoQ;
  final double ahorroMensual;

  const _SettingsForm({
    required this.current,
    required this.ahorroBaseQ,
    required this.ahorroTrasExtraQ,
    required this.ahorroRedondeadoQ,
    required this.ahorroMensual,
  });

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late Settings s;

  @override
  void initState() {
    super.initState();
    s = widget.current;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
    );
    if (time != null) {
      setState(() => s = s.copyWith(reminderHour: time.hour, reminderMinute: time.minute));
    }
  }

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ahorro automático',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    'Añade % extra y redondeo al ahorro. También puedes activar recordatorios.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // % extra
        Row(
          children: [
            Expanded(child: Text('% extra de ahorro', style: Theme.of(context).textTheme.bodyMedium)),
            Text('${s.extraSavingPercent.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        Slider(
          value: s.extraSavingPercent.clamp(0, 100).toDouble(),
          min: 0,
          max: 50,
          divisions: 50,
          label: '${s.extraSavingPercent.toStringAsFixed(0)}%',
          onChanged: (v) => setState(() => s = s.copyWith(extraSavingPercent: v)),
        ),
        const SizedBox(height: 8),

        // Redondeo chips
        Text('Redondeo del ahorro quincenal', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _RoundChip(
              label: 'Sin redondeo',
              selected: s.rounding == RoundingMode.none,
              onTap: () => setState(() => s = s.copyWith(rounding: RoundingMode.none)),
            ),
            _RoundChip(
              label: 'Múltiplo de \$10',
              selected: s.rounding == RoundingMode.up10,
              onTap: () => setState(() => s = s.copyWith(rounding: RoundingMode.up10)),
            ),
            _RoundChip(
              label: 'Múltiplo de \$50',
              selected: s.rounding == RoundingMode.up50,
              onTap: () => setState(() => s = s.copyWith(rounding: RoundingMode.up50)),
            ),
            _RoundChip(
              label: 'Múltiplo de \$100',
              selected: s.rounding == RoundingMode.up100,
              onTap: () => setState(() => s = s.copyWith(rounding: RoundingMode.up100)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Recordatorios
        Row(
          children: [
            Expanded(child: Text('Recordatorios quincenales', style: Theme.of(context).textTheme.bodyMedium)),
            Switch(
              value: s.remindersEnabled,
              onChanged: (v) => setState(() => s = s.copyWith(remindersEnabled: v)),
            ),
          ],
        ),
        if (s.remindersEnabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Hora de recordatorio')),
              TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text('${s.reminderHour.toString().padLeft(2,'0')}:${s.reminderMinute.toString().padLeft(2,'0')}'),
                onPressed: _pickTime,
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se programarán recordatorios los días 1 y 16 a la hora seleccionada.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],

        const SizedBox(height: 18),

        // Preview
        _PreviewPanel(
          ahorroBaseQ: widget.ahorroBaseQ,
          ahorroTrasExtraQ: widget.ahorroTrasExtraQ,
          ahorroRedondeadoQ: widget.ahorroRedondeadoQ,
          ahorroMensual: widget.ahorroMensual,
        ),

        const SizedBox(height: 16),

        // Botones
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restablecer'),
              onPressed: () => setState(() => s = const Settings()),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
              onPressed: () async {
                final ctrl = context.read<BudgetController>();
                try {
                  // Guardar en controller (y en Firestore si hay uid)
                  await ctrl.setSettings(s);

                  // Programar / cancelar recordatorios ahora mismo
                  if (s.remindersEnabled) {
                    await NotificationService.scheduleQuincenal(
                      hour: s.reminderHour,
                      minute: s.reminderMinute,
                    );
                  } else {
                    await NotificationService.cancelAll();
                  }

                  if (!mounted) return;

                  // Mostrar diálogo de éxito con opción de abrir ajustes de notificaciones si corresponde
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Ajustes guardados'),
                      content: Text(
                        s.remindersEnabled
                            ? 'Tus ajustes y recordatorios fueron guardados. Si no ves las notificaciones, revisa los permisos de notificaciones del sistema.'
                            : 'Tus ajustes fueron guardados correctamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Aceptar'),
                        ),
                        if (s.remindersEnabled)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // Abrir ajustes de notificaciones de la app para que el usuario otorgue permisos
                              
                            },
                            child: const Text('Abrir ajustes de notificaciones'),
                          ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _row('Ahorro base quincenal', MoneyFmt.mx(ahorroBaseQ)),
          _row('Con % extra', MoneyFmt.mx(ahorroTrasExtraQ)),
          _row('Aplicando redondeo', MoneyFmt.mx(ahorroRedondeadoQ)),
          const Divider(height: 14),
          _row('Ahorro final QUINCENAL', MoneyFmt.mx(ahorroRedondeadoQ),
              strong: true, color: Colors.green.shade700),
          _row('Ahorro MENSUAL estimado', MoneyFmt.mx(ahorroMensual),
              strong: true),
        ],
      ),
    );
  }
}

double _roundUpTo(double n, int step) {
  if (step <= 0) return n;
  final m = (n / step).ceil();
  return m * step.toDouble();
}
