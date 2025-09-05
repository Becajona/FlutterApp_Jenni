import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();

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
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: const DashboardScreen(), 
    );
  }
}
