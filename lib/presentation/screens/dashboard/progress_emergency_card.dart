// lib/presentation/screens/dashboard/progress_emergency_card.dart
import 'package:flutter/material.dart';
import '../../../money/utils/formatters.dart';

class ProgressEmergencyCard extends StatefulWidget {
  final double gastosMensuales; // gastos fijos convertidos a mensual
  final double colchonActual;   // saldo actual destinado a emergencias
  final int mesesObjetivoInicial; // ej. 3 o 6

  const ProgressEmergencyCard({
    super.key,
    required this.gastosMensuales,
    required this.colchonActual,
    this.mesesObjetivoInicial = 3,
  });

  @override
  State<ProgressEmergencyCard> createState() => _ProgressEmergencyCardState();
}

class _ProgressEmergencyCardState extends State<ProgressEmergencyCard> {
  late int _mesesObjetivo;

  @override
  void initState() {
    super.initState();
    _mesesObjetivo = widget.mesesObjetivoInicial.clamp(1, 12);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.gastosMensuales * _mesesObjetivo;
    final progreso = target <= 0
        ? 0.0
        : (widget.colchonActual / target).clamp(0, 1).toDouble();
    final restante = (target - widget.colchonActual).clamp(0, target);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ------- CABECERA RESPONSIVA -------
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 340;

                if (isNarrow) {
                  // En pantallas angostas: título arriba, stepper abajo
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.health_and_safety_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fondo de emergencia',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _Stepper(
                          value: _mesesObjetivo,
                          onChanged: (v) =>
                              setState(() => _mesesObjetivo = v.clamp(1, 12)),
                        ),
                      ),
                    ],
                  );
                }

                // En pantallas normales: todo en una sola fila
                return Row(
                  children: [
                    const Icon(Icons.health_and_safety_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fondo de emergencia',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Stepper(
                      value: _mesesObjetivo,
                      onChanged: (v) =>
                          setState(() => _mesesObjetivo = v.clamp(1, 12)),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),
            Text(
              'Objetivo: $_mesesObjetivo ${_mesesObjetivo == 1 ? 'mes' : 'meses'} de gastos '
              '(${MoneyFmt.mx(target)})',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 12,
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Acumulado: ${MoneyFmt.mx(widget.colchonActual)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  restante > 0
                      ? 'Faltan ${MoneyFmt.mx(restante)}'
                      : '¡Meta alcanzada!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: restante > 0
                        ? theme.colorScheme.onSurface.withOpacity(.7)
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // IconButtons compactos para ocupar menos ancho
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Menos meses',
          onPressed: () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ),
        const SizedBox(width: 4),
        Text('$value'),
        const SizedBox(width: 4),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Más meses',
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, size: 20),
        ),
      ],
    );
  }
}
