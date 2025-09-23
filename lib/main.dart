// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth/auth_repository.dart';
import 'presentation/controllers/budget_controller.dart';
import 'data/firestore_service.dart';
import 'app_router.dart';

// Notificaciones
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Inicializa notificaciones una sola vez, antes de runApp
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        Provider(create: (_) => FirestoreService()),
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

  // Solo programamos/cancelamos recordatorios según settings y cambios de auth
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // OJO: init() ya pidió permisos en Android 13+ internamente.
    // await NotificationService.requestAndroid13Permission();  // <-- quítalo

    final budget = context.read<BudgetController>();

    // Si ya hay settings en memoria, agenda/cancela
    final s0 = budget.settings;
    if (s0.remindersEnabled) {
      await NotificationService.scheduleQuincenal(
        hour: s0.reminderHour,
        minute: s0.reminderMinute,
      );
    } else {
      await NotificationService.cancelAll();
    }

    if (!mounted) return; // evita usar context si el widget ya no está montado

    // Suscripción a cambios de sesión para (re)cargar datos y ajustar recordatorios
    final auth = context.read<AuthRepository>();
    auth.authStateChanges.listen((user) async {
      if (user != null) {
        await budget.loadFromCloud();

        if (!mounted) return;

        final s = budget.settings;
        if (s.remindersEnabled) {
          await NotificationService.scheduleQuincenal(
            hour: s.reminderHour,
            minute: s.reminderMinute,
          );
        } else {
          await NotificationService.cancelAll();
        }
      } else {
        budget.resetLocal();
        await NotificationService.cancelAll();
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
