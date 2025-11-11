// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_repository.dart';
import '../presentation/controllers/budget_controller.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';

// Abrir ajustes de la app (notificaciones/batería)
import 'package:app_settings/app_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showPermissionCard = true;

  /// Índice del BottomNav (Inicio = 0)
  int _currentIndex = 0;

  /// Navegar según el tab seleccionado.
  /// - Inicio usa go() para evitar apilar rutas.
  /// - Otras pestañas usan push() para que el botón Atrás regrese a Inicio.
  void _onBottomTap(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);

    switch (i) {
      case 0:
        context.go('/home');       // reemplaza la ruta → no apila
        break;
      case 1:
        context.push('/simulator'); // apila → BackButton regresa a /home
        break;
      case 2:
        context.push('/history');
        break;
      case 3:
        context.push('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final ctrl = context.read<BudgetController>();

    return Scaffold(
      // APP BAR
      appBar: AppBar(
        title: const Text('Ahorratón'),
      ),

      // DRAWER
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Cabecera opcional con logo/usuario aquí

              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Gastos fijos'),
                onTap: () {
                  Navigator.of(context).pop(); // cierra drawer
                  context.push('/expenses');
                },
              ),
              ListTile(
                leading: const Icon(Icons.task_alt_outlined),
                title: const Text('Quincena Cerrada'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pid = await ctrl.closeCurrentPeriod();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        pid == null ? 'No se pudo cerrar' : 'Quincena $pid cerrada',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await auth.signOut();
                },
              ),
            ],
          ),
        ),
      ),

      // BODY (Inicio)
      body: Column(
        children: [
          if (_showPermissionCard)
            _PermissionHelpCard(onClose: () {
              setState(() => _showPermissionCard = false);
            }),

          // Tu dashboard de siempre
          const Expanded(child: DashboardScreen()),
        ],
      ),

      // BOTTOM NAV
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onBottomTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: 'Simulador',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes de ahorro',
          ),
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
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
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
