import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnbStartScreen extends StatelessWidget {
  const OnbStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar tu app')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Vamos a configurar tus ingresos primero. Esto nos permitirá calcular tus quincenas y el ahorro.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/onb/income'),
              child: const Text('Configurar ingresos'),
            ),
          ],
        ),
      ),
    );
  }
}
