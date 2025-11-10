// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_repository.dart';
import '../presentation/controllers/budget_controller.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';

// Panel extra (frase + conversión USD)
import '../presentation/widgets/dashboard_extra_panel.dart';

// Paquete para abrir la pantalla de ajustes de la app
import 'package:app_settings/app_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showPermissionCard = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final budget = context.watch<BudgetController>();
    final result = budget.calculate();
    // Tomamos el ahorro base (ajusta si tu modelo usa otro campo)
    final ahorroTotalLocal = (result?.ahorroQ ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Gastos fijos',
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.push('/expenses'),
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: 'Simulador',
            icon: const Icon(Icons.auto_graph),
            onPressed: () => context.push('/simulator'),
          ),
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            tooltip: 'Cerrar quincena',
            icon: const Icon(Icons.task_alt),
            onPressed: () async {
              final ctrl = context.read<BudgetController>();
              final pid = await ctrl.closeCurrentPeriod();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    pid == null ? 'No se pudo cerrar' : 'Quincena $pid cerrada',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showPermissionCard)
            _PermissionHelpCard(onClose: () {
              setState(() => _showPermissionCard = false);
            }),

          // 🔥 NUEVO: panel con frase motivacional + ahorro convertido a USD
          // Pásale el total de ahorro estimado en tu moneda local (ej. MXN)
         
          // Tu dashboard de siempre
          const Expanded(child: DashboardScreen()),
        ],
      ),
    );
  }
}

class _PermissionHelpCard extends StatelessWidget {
  final VoidCallback onClose;
  const _PermissionHelpCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Para recibir recordatorios, habilita notificaciones y quita restricciones de batería.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Abrir ajustes de la app'),
              onPressed: () async {
                try {
                  await AppSettings.openAppSettings();
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }
}
