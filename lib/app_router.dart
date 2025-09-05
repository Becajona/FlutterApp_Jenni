import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_repository.dart';
import '../presentation/controllers/budget_controller.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../presentation/screens/onboarding/start_screen.dart';
import '../presentation/screens/onboarding/income_screen.dart';
import '../presentation/screens/onboarding/emergency_screen.dart'; 
import '../presentation/screens/expenses/expenses_crud_screen.dart'; 
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/simulator/simulator_screen.dart';



Listenable _mergeListenable(List<Listenable> list) => Listenable.merge(list);

GoRouter createRouter(AuthRepository auth, BudgetController budget) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: _mergeListenable([auth, budget]),
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    // Onboarding
    GoRoute(path: '/onb/start', builder: (c, s) => const OnbStartScreen()),
    GoRoute(path: '/onb/income', builder: (c, s) => const IncomeScreen()),
    // Home
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/onb/emergency', builder: (c, s) => const EmergencyScreen()),
    GoRoute(path: '/expenses', builder: (c, s) => const ExpensesCrudScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    GoRoute(path: '/simulator', builder: (c, s) => const SimulatorScreen()),


  ],
  redirect: (context, state) {
    final loggedIn = auth.isLoggedIn;
    final loc = state.matchedLocation;
    final isAuth = loc == '/login' || loc == '/register';

    if (loc == '/splash') return loggedIn ? '/home' : '/login';

    if (!loggedIn) return isAuth ? null : '/login';

    if (loggedIn && !budget.hasMinimumSetup && !loc.startsWith('/onb/')) {
      return '/onb/start';
    }
    if (loggedIn && budget.hasMinimumSetup && loc.startsWith('/onb/')) {
      return '/home';
    }
    return null;
  },
);
