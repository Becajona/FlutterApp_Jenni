// lib/presentation/screens/dashboard/projection_card.dart
import 'package:flutter/material.dart';
import '../../../money/utils/formatters.dart';

class ProjectionCard extends StatefulWidget {
  final double ahorroMensual; // del cálculo actual
  final double saldoInicial; // p.ej. colchonActual
  final int mesesIniciales;

  const ProjectionCard({
    super.key,
    required this.ahorroMensual,
    required this.saldoInicial,
    this.mesesIniciales = 12,
  });

  @override
  State<ProjectionCard> createState() => _ProjectionCardState();
}

class _ProjectionCardState extends State<ProjectionCard> {
  late int _meses;

  @override
  void initState() {
    super.initState();
    _meses = widget.mesesIniciales.clamp(1, 24);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proyeccion = widget.saldoInicial + widget.ahorroMensual * _meses;

    // Serie simple para sparkline
    final List<double> serie = List.generate(
      _meses + 1,
      (i) => widget.saldoInicial + widget.ahorroMensual * i,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded),
              const SizedBox(width: 8),
              Text('Proyección de ahorro',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$_meses m'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _SparklinePainter(
                  serie: serie, color: theme.colorScheme.primary),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _meses.toDouble(),
            min: 1,
            max: 24,
            divisions: 23,
            label: '$_meses meses',
            onChanged: (v) => setState(() => _meses = v.round()),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child:
                    Text('Saldo inicial: ${MoneyFmt.mx(widget.saldoInicial)}'),
              ),
              Text('Proyección: ${MoneyFmt.mx(proyeccion)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> serie;
  final Color color;

  _SparklinePainter({required this.serie, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (serie.length < 2) return;

    final minV = serie.reduce((a, b) => a < b ? a : b);
    final maxV = serie.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < serie.length; i++) {
      final x = i * (size.width / (serie.length - 1));
      final y = size.height - ((serie[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.serie != serie || oldDelegate.color != color;
  }
}
