import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../controllers/budget_controller.dart';
import '../../../domain/services/budget_calculator.dart';
import '../../../money/utils/formatters.dart';

import 'progress_emergency_card.dart';
import 'projection_card.dart';

import '../../widgets/charts/category_pie.dart';
import '../../widgets/charts/emergency_progress.dart';
import '../../widgets/charts/annual_projection.dart';

// 👇 Servicios para frase del día y conversión
import '../../../data/api_exchange_service.dart';
import '../../../data/api_quotes_service.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BudgetController>();
    final result = ctrl.calculate();

    return Scaffold(
      appBar: AppBar(title: const Text('Panel')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: _DashboardContent(result: result),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================== CONTENIDO DEL DASHBOARD ================== */
class _DashboardContent extends StatefulWidget {
  final BudgetResult? result;
  const _DashboardContent({required this.result});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  // --------- Estado para "Frase del día" + Conversión ---------
  final List<String> _monedas = const ['USD', 'EUR', 'JPY', 'MXN'];
  String _destCurrency = 'USD';
  static const String _baseCurrency = 'MXN'; // cambia si tu base no es MXN

  bool _loadingFrase = true;
  String? _fraseEs;
  double? _ahorroConvertido;
  String? _errorFrase;

  @override
  void initState() {
    super.initState();
    _loadQuoteAndRates();
  }

  Future<void> _loadQuoteAndRates() async {
    setState(() {
      _loadingFrase = true;
      _errorFrase = null;
    });

    try {
      // 1) Frase del día (tu servicio ya la devuelve en español)
      final frase = await QuotesService.getRandomQuote();

      // 2) Conversión del ahorro quincenal (ajústalo si quieres otro monto)
      final ahorroLocal = widget.result?.ahorroQ ?? 0.0;
      final converted = await ExchangeService.convert(
        ahorroLocal,
        _baseCurrency,
        _destCurrency,
      );

      setState(() {
        _fraseEs = frase;
        _ahorroConvertido = converted; // puede venir null si falla la API
        _loadingFrase = false;
      });
    } catch (e) {
      setState(() {
        _errorFrase = 'No se pudo cargar la información.';
        _loadingFrase = false;
      });
    }
  }

  String _formatMonto(double v, String currency) {
    return '${v.toStringAsFixed(2)} $currency';
  }

  // ------- Tarjeta integrada (antes estaba en DashboardExtraPanel) -------
  Widget _buildQuoteCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 8),
                Text('Frase del día',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadingFrase ? null : _loadQuoteAndRates,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Frase / estados
            if (_loadingFrase) ...[
              const SizedBox(height: 6),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else if (_errorFrase != null) ...[
              Text(
                _errorFrase!,
                style: TextStyle(color: cs.error),
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                onPressed: _loadQuoteAndRates,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ] else ...[
              Text(
                _fraseEs ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),

            // Fila: selector de moneda + título
            Row(
              children: [
                Text(
                  'Tu ahorro en:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _destCurrency,
                  items: _monedas
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (m) async {
                    if (m == null) return;
                    setState(() => _destCurrency = m);
                    await _loadQuoteAndRates();
                  },
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Resultado / loading
            if (_loadingFrase) ...[
              const SizedBox(height: 4),
              Text(
                'Calculando...',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_ahorroConvertido == null) ...[
              const Text(
                'No disponible por ahora',
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                onPressed: _loadQuoteAndRates,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ] else ...[
              Text(
                _formatMonto(_ahorroConvertido!, _destCurrency),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------- UI principal ---------------------
  @override
  Widget build(BuildContext context) {
    if (widget.result == null) return const _EmptyState();

    // 👉 Dispara el aviso tras el frame, no durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeNotifyGoalReached(context);
    });

    final data = _formatResult(widget.result!);
    final ahorroRate = _safeDiv(widget.result!.ahorroQ, widget.result!.ingresoQ);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderResumen(
          ingresoQ: widget.result!.ingresoQ,
          ahorroQ: widget.result!.ahorroQ,
          ahorroRate: ahorroRate,
        ),
        const SizedBox(height: 16),

        // 👇 NUEVA tarjeta integrada (frase + conversión)
        _buildQuoteCard(context),

        const SizedBox(height: 16),

        _KpiGrid(
          items: [
            KpiItem(
              label: 'Ingreso quincenal',
              value: MoneyFmt.mx(widget.result!.ingresoQ),
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.indigo,
              emphasis: KpiEmphasis.primary,
            ),
            KpiItem(
              label: 'Gastos fijos',
              value: MoneyFmt.mx(widget.result!.gastosQ),
              icon: Icons.receipt_long_rounded,
              color: Colors.deepOrange,
            ),
            KpiItem(
              label: 'Colchón',
              value: MoneyFmt.mx(widget.result!.colchonQ),
              icon: Icons.savings_rounded,
              color: Colors.teal,
            ),
            KpiItem(
              label: 'Ahorro sobrante',
              value: MoneyFmt.mx(widget.result!.ahorroQ),
              icon: Icons.trending_up_rounded,
              color: Colors.green,
              emphasis: KpiEmphasis.positive,
            ),
            KpiItem(
              label: 'Ahorro mensual',
              value: MoneyFmt.mx(widget.result!.ahorroMensual),
              icon: Icons.calendar_month_rounded,
              color: Colors.blueGrey,
            ),
            KpiItem(
              label: 'Ahorro anual',
              value: MoneyFmt.mx(widget.result!.ahorroAnual),
              icon: Icons.timeline_rounded,
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),

        _BreakdownCard(map: {
          'Ingreso quincenal': data['Ingreso quincenal']!,
          'Gastos fijos': data['Gastos fijos']!,
          'Colchón': data['Colchón']!,
          'Ahorro sobrante': data['Ahorro sobrante']!,
          'Ahorro mensual': data['Ahorro mensual']!,
          'Ahorro anual': data['Ahorro anual']!,
        }),
        const SizedBox(height: 16),

        // ---- tus tarjetas existentes (las mantenemos) ----
        LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth >= 900;
          final gastosMensuales = widget.result!.gastosQ * 2; // quincenal → mensual
          final colchonActual = widget.result!.colchonQ;

          final emergency = ProgressEmergencyCard(
            gastosMensuales: gastosMensuales,
            colchonActual: colchonActual,
            mesesObjetivoInicial: 3,
          );

          final projection = ProjectionCard(
            ahorroMensual: widget.result!.ahorroMensual,
            saldoInicial: colchonActual,
            mesesIniciales: 12,
          );

          return isWide
              ? Row(
                  children: [
                    Expanded(child: emergency),
                    const SizedBox(width: 16),
                    Expanded(child: projection),
                  ],
                )
              : Column(
                  children: [
                    emergency,
                    const SizedBox(height: 16),
                    projection,
                  ],
                );
        }),

        // ---- GRÁFICAS ----
        const SizedBox(height: 16),
        const EmergencyProgress(),
        const SizedBox(height: 16),
        const CategoryPie(),
        const SizedBox(height: 16),
        const AnnualProjection(),
      ],
    );
  }
}

/* ================== HELPERS / WIDGETS AL NIVEL SUPERIOR ================== */

Map<String, String> _formatResult(BudgetResult r) {
  String f(num n) => MoneyFmt.mx(n);
  return {
    'Ingreso quincenal': f(r.ingresoQ),
    'Gastos fijos': f(r.gastosQ),
    'Colchón': f(r.colchonQ),
    'Ahorro sobrante': f(r.ahorroQ),
    'Ahorro mensual': f(r.ahorroMensual),
    'Ahorro anual': f(r.ahorroAnual),
  };
}

double _safeDiv(num a, num b) {
  if (b == 0) return 0;
  final v = a / b;
  return v.isNaN || v.isInfinite ? 0 : v.toDouble();
}

/// Encabezado con resumen y barra de progreso
class _HeaderResumen extends StatelessWidget {
  final num ingresoQ;
  final num ahorroQ;
  final double ahorroRate;

  const _HeaderResumen({
    required this.ingresoQ,
    required this.ahorroQ,
    required this.ahorroRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    final valueStyle =
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 620;
            final blocks = [
              _HeaderBlock(
                'Ingreso quincenal',
                MoneyFmt.mx(ingresoQ),
                Icons.account_balance_wallet_rounded,
                titleStyle,
                valueStyle,
              ),
              _HeaderBlock(
                'Ahorro sobrante',
                MoneyFmt.mx(ahorroQ),
                Icons.trending_up_rounded,
                titleStyle,
                valueStyle?.copyWith(color: Colors.green.shade700),
              ),
            ];
            final progress = _AhorroProgress(ahorroRate: ahorroRate);
            return isWide
                ? Row(children: [
                    Expanded(child: blocks[0]),
                    const SizedBox(width: 20),
                    Expanded(child: blocks[1]),
                    const SizedBox(width: 24),
                    Expanded(child: progress),
                  ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      blocks[0],
                      const SizedBox(height: 14),
                      blocks[1],
                      const SizedBox(height: 16),
                      progress,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  const _HeaderBlock(
    this.title,
    this.value,
    this.icon,
    this.titleStyle,
    this.valueStyle, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 4),
              Text(value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _AhorroProgress extends StatelessWidget {
  final double ahorroRate; // 0..1
  const _AhorroProgress({required this.ahorroRate});

  @override
  Widget build(BuildContext context) {
    final pct = (ahorroRate * 100).clamp(0, 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tasa de ahorro',
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ahorroRate.clamp(0, 1),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text('$pct% de tu ingreso quincenal'),
      ],
    );
  }
}

/// Grid responsivo de KPIs (no scroll propio)
class _KpiGrid extends StatelessWidget {
  final List<KpiItem> items;
  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      int cross = 1;
      if (w >= 520 && w < 820) cross = 2;
      if (w >= 820) cross = 3;

      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          mainAxisExtent: 120,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => _KpiCard(item: items[i]),
      );
    });
  }
}

enum KpiEmphasis { normal, primary, positive }

class KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final KpiEmphasis emphasis;
  KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.emphasis = KpiEmphasis.normal,
  });
}

class _KpiCard extends StatelessWidget {
  final KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surface;
    final tint = item.color.withOpacity(0.08);

    final titleStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.8),
      letterSpacing: .2,
    );

    TextStyle valueStyle = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w800,
    );

    if (item.emphasis == KpiEmphasis.primary) {
      valueStyle = valueStyle.copyWith(color: theme.colorScheme.primary);
    } else if (item.emphasis == KpiEmphasis.positive) {
      valueStyle = valueStyle.copyWith(color: Colors.green.shade700);
    }

    return Card(
      elevation: 0,
      color: Color.alphaBlend(tint, base),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SoftIcon(item.icon, item.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: titleStyle),
                  const SizedBox(height: 6),
                  Text(item.value, style: valueStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SoftIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final bg = color.withOpacity(0.12);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

/// Desglose en filas
class _BreakdownCard extends StatelessWidget {
  final Map<String, String> map;
  const _BreakdownCard({required this.map});

  @override
  Widget build(BuildContext context) {
    final items = map.entries.toList();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Desglose detallado',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...items.map((e) {
              final isAhorro = e.key.toLowerCase().contains('ahorro sobrante');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(.85),
                        ),
                      ),
                    ),
                    Text(
                      e.value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isAhorro ? FontWeight.w800 : FontWeight.w600,
                        color: isAhorro ? Colors.green.shade700 : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              'Aún no hay datos para mostrar',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Configura tu ingreso y gastos para ver tu panel con métricas y progreso de ahorro.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.8)),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- Aviso de meta de fondo alcanzada ---------- */
void _maybeNotifyGoalReached(BuildContext context) {
  final ctrl = context.read<BudgetController>();
  final res = ctrl.calculate();
  final emer = ctrl.emergency;
  if (res == null || emer == null) return;

  // Meta = meses objetivo * gastos mensuales (gastos quincenales * 2)
  final gastosMensuales = res.gastosQ * 2;
  final meta = emer.goalMonths * gastosMensuales;

  // Criterio simple: si el ahorro mensual ≥ meta (placeholder hasta tener saldo acumulado real)
  if (res.ahorroMensual >= meta) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 ¡Meta del fondo de emergencia alcanzada!')),
    );
  }
}
