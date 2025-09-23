import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    // Cargar historial al entrar
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.download),
            onPressed: history.isEmpty ? null : () => _exportCsv(history),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const _EmptyHistory()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await context
                              .read<BudgetController>()
                              .deletePeriod(history[i].id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Quincena ${history[i].id} eliminada')),
                          );
                        }
                      },
                    ),
                  ),
                ),
    );
  }

  void _exportCsv(List<PeriodSnapshot> history) {
    // Construir CSV en memoria
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
      // WEB: descargar archivo
      WebDownload.downloadText(
        csv,
        filename: 'historial_quincenas.csv',
        mime: 'text/csv',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV generado (descarga iniciada)')),
      );
    } else {
      // MÓVIL/ESCRITORIO: mostrar diálogo para copiar/guardar manualmente
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

/// Tile de cada cierre
class _HistoryTile extends StatelessWidget {
  final PeriodSnapshot snap;
  final VoidCallback onDelete;

  const _HistoryTile({required this.snap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        title: Text('Quincena ${snap.id}'),
        subtitle: Text(
          'Cerrada: ${snap.createdAt.toLocal()}'
          '\nIngresoQ: ${MoneyFmt.mx(snap.ingresoQ)}  •  GastosQ: ${MoneyFmt.mx(snap.gastosQ)}'
          '\nColchónQ: ${MoneyFmt.mx(snap.colchonQ)}  •  AhorroQ: ${MoneyFmt.mx(snap.ahorroQ)}'
          '\nAhorro mensual: ${MoneyFmt.mx(snap.ahorroMensual)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Sin cierres registrados. Cierra una quincena desde Inicio.'),
    );
  }
}

/// Utilidad mínima para crear CSV sin dependencias
class ListToCsv {
  const ListToCsv();

  String convert(List<List<String>> rows) {
    return rows.map((r) => r.map(_escape).join(',')).join('\n');
    // si quieres ; como separador, cambia la coma por ';'
  }

  String _escape(String v) {
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    var out = v.replaceAll('"', '""');
    return needsQuotes ? '"$out"' : out;
  }
}
