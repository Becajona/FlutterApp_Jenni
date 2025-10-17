import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../money/utils/formatters.dart';
import '../../controllers/budget_controller.dart';
import '../../../domain/entities/period_snapshot.dart';

// Import condicional: en web usa la implementación real; en otras plataformas, un stub no-op
import 'download_helper_stub.dart'
  if (dart.library.html) 'download_helper_web.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await context.read<BudgetController>().loadHistory();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final history = ctrl.history;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Historial'),
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: history.isEmpty ? null : () => _exportCsv(history),
          ),
        ],
      ),
      // Fondo con gradiente suave
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface.withOpacity(0.98),
              cs.surfaceContainerHighest.withOpacity(0.90),
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : history.isEmpty
                ? const _EmptyHistory()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _HistoryTile(
                        snap: history[i],
                        onDelete: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar cierre'),
                              content: Text('¿Eliminar la quincena ${history[i].id}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await context.read<BudgetController>().deletePeriod(history[i].id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Quincena ${history[i].id} eliminada'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
      ),
    );
  }

  void _exportCsv(List<PeriodSnapshot> history) {
    final rows = <List<String>>[
      [
        'periodo',
        'fecha_cierre_iso',
        'ingreso_quincenal',
        'gastos_quincenales',
        'colchon_quincenal',
        'ahorro_quincenal',
        'ahorro_mensual',
        'extra_percent',
        'rounding',
      ],
      ...history.map((s) => [
            s.id,
            s.createdAt.toIso8601String(),
            s.ingresoQ.toStringAsFixed(2),
            s.gastosQ.toStringAsFixed(2),
            s.colchonQ.toStringAsFixed(2),
            s.ahorroQ.toStringAsFixed(2),
            s.ahorroMensual.toStringAsFixed(2),
            s.extraSavingPercent.toStringAsFixed(2),
            s.rounding.name,
          ]),
    ];
    final csv = const ListToCsv().convert(rows);

    if (kIsWeb) {
      WebDownload.downloadText(
        csv,
        filename: 'historial_quincenas.csv',
        mime: 'text/csv',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('CSV generado (descarga iniciada)'),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('CSV generado'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(child: SelectableText(csv)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      );
    }
  }
}

/// ======= Tarjeta de cada cierre (solo DISEÑO) =======
class _HistoryTile extends StatelessWidget {
  final PeriodSnapshot snap;
  final VoidCallback onDelete;

  const _HistoryTile({required this.snap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(snap.createdAt.toLocal());

    return PhysicalModel(
      color: Colors.transparent,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(22),
      shadowColor: cs.shadow.withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con icono y "pill" de estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.history, color: cs.onPrimaryContainer, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quincena ${snap.id}',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('Cerrada: $date',
                            style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  _StatusPill(
                    icon: Icons.sync_alt_rounded,
                    label: 'Actualizado',
                    bg: cs.secondaryContainer,
                    fg: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    tooltip: 'Eliminar',
                    icon: Icons.delete_outline,
                    onTap: onDelete,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),

              const SizedBox(height: 12),
              // Chips de métricas como en tu referencia
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                    icon: Icons.trending_up,
                    label: 'IngresoQ',
                    value: MoneyFmt.mx(snap.ingresoQ),
                    bg: cs.tertiaryContainer,
                    fg: cs.onTertiaryContainer,
                  ),
                  _MetricChip(
                    icon: Icons.trending_down,
                    label: 'GastosQ',
                    value: MoneyFmt.mx(snap.gastosQ),
                    bg: cs.surfaceContainerHigh,
                    fg: cs.onSurfaceVariant,
                    border: cs.outlineVariant,
                  ),
                  _MetricChip(
                    icon: Icons.savings_outlined,
                    label: 'ColchónQ',
                    value: MoneyFmt.mx(snap.colchonQ),
                    bg: cs.primaryContainer.withOpacity(.35),
                    fg: cs.onPrimaryContainer,
                    border: cs.primaryContainer,
                  ),
                  _MetricChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'AhorroQ',
                    value: MoneyFmt.mx(snap.ahorroQ),
                    bg: cs.secondaryContainer.withOpacity(.35),
                    fg: cs.onSecondaryContainer,
                    border: cs.secondaryContainer,
                  ),
                  _MetricChip(
                    icon: Icons.calendar_month_outlined,
                    label: 'Ahorro mensual',
                    value: MoneyFmt.mx(snap.ahorroMensual),
                    bg: cs.surfaceContainerHigh,
                    fg: cs.onSurfaceVariant,
                    border: cs.outlineVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        containedInkWell: true,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(icon, size: 20, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;
  final Color? border;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border ?? Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: fg.withOpacity(.85),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          Text(value, style: TextStyle(color: fg, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Sin cierres registrados',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Cierra una quincena desde Inicio para ver tu historial aquí.',
              style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Utilidad mínima para crear CSV sin dependencias
class ListToCsv {
  const ListToCsv();

  String convert(List<List<String>> rows) {
    return rows.map((r) => r.map(_escape).join(',')).join('\n');
  }

  String _escape(String v) {
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    var out = v.replaceAll('"', '""');
    return needsQuotes ? '"$out"' : out;
  }
}
