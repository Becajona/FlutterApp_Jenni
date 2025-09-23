import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../../notifications/notification_service.dart';

class DebugNotiBar extends StatefulWidget {
  const DebugNotiBar({super.key});

  @override
  State<DebugNotiBar> createState() => _DebugNotiBarState();
}

class _DebugNotiBarState extends State<DebugNotiBar> {
  final _minCtrl = TextEditingController(text: '1');
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar en release automáticamente.
    if (kReleaseMode) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('🔔 Debug notificaciones',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            // Fila: prueba inmediata + programar en N minutos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Prueba inmediata'),
                  onPressed: () async {
                    await NotificationService.showTestNow();
                    if (!mounted) return;
                    _toast(context, 'Notificación enviada (inmediata)');
                  },
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                      isDense: true,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('Programar en N min'),
                  onPressed: () async {
                    final m = int.tryParse(_minCtrl.text.trim());
                    if (m == null || m <= 0) {
                      _toast(context, 'Pon un número de minutos (>0)');
                      return;
                    }
                    await NotificationService.scheduleTestInMinutes(m);
                    if (!mounted) return;
                    _toast(context, 'Programada en ~$m minuto(s)');
                  },
                ),
              ],
            ),

            const Divider(height: 16),

            // Fila: quincenal a la hora elegida
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text('Hora: ${_time.format(context)}'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked != null) setState(() => _time = picked);
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.event_repeat),
                  label: const Text('Programar 1 y 16'),
                  onPressed: () async {
                    await NotificationService.scheduleQuincenal(
                      hour: _time.hour,
                      minute: _time.minute,
                    );
                    if (!mounted) return;
                    _toast(context,
                        'Programadas para el 1 y 16 a las ${_time.format(context)}');
                  },
                ),
              ],
            ),

            const Divider(height: 16),

            // Fila: ver pendientes / cancelar todas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text('Pendientes'),
                  onPressed: () async {
                    final p = await NotificationService.pending();
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Pendientes'),
                        content: SizedBox(
                          width: 420,
                          child: SingleChildScrollView(
                            child: Text(
                              p.isEmpty
                                  ? 'No hay notificaciones pendientes.'
                                  : p
                                      .map((e) =>
                                          '• id=${e.id}  title=${e.title ?? "-"}')
                                      .join('\n'),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_schedule_send),
                  label: const Text('Cancelar todas'),
                  onPressed: () async {
                    await NotificationService.cancelAll();
                    if (!mounted) return;
                    _toast(context, 'Todas canceladas');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
