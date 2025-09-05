import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_repository.dart';
import 'presentation/controllers/budget_controller.dart'; 
import 'app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(create: (_) => BudgetController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final budget = context.read<BudgetController>();
    final router = createRouter(auth, budget);

    return MaterialApp.router(
      title: 'Ahorro Quincenal',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
