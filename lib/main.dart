import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth/auth_repository.dart';
import 'presentation/controllers/budget_controller.dart';
import 'data/firestore_service.dart';
import 'app_router.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        Provider(create: (_) => FirestoreService()),
        // Creamos el BudgetController vacío y luego lo "bind-eamos" con auth+store
        ChangeNotifierProxyProvider2<AuthRepository, FirestoreService, BudgetController>(
          create: (_) => BudgetController(),
          update: (_, auth, store, ctrl) {
            final c = ctrl ?? BudgetController();
            c.bind(auth: auth, store: store);
            return c;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Suscribirnos a cambios de auth y cargar/limpiar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthRepository>();
      final budget = context.read<BudgetController>();
      auth.authStateChanges.listen((user) async {
        if (user != null) {
          await budget.loadFromCloud();
        } else {
          budget.resetLocal();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final budget = context.read<BudgetController>();
    final router = createRouter(auth, budget);

    return MaterialApp.router(
      title: 'Ahorraton',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
