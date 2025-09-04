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
import '../presentation/screens/onboarding/emergency_screen.dart'; // nuevo
import '../presentation/screens/expenses/expenses_crud_screen.dart'; // nuevo


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

  ],
  redirect: (context, state) {
    final loggedIn = auth.isLoggedIn;
    final loc = state.matchedLocation;
    final isAuth = loc == '/login' || loc == '/register';

    // Splash → decide por auth
    if (loc == '/splash') return loggedIn ? '/home' : '/login';

    // Sin login → solo permitir pantallas de auth
    if (!loggedIn) return isAuth ? null : '/login';

    // Con login → si falta mínima config, ir a onboarding
    if (loggedIn && !budget.hasMinimumSetup && !loc.startsWith('/onb/')) {
      return '/onb/start';
    }
    // Si está en onboarding y ya tiene lo mínimo, permitir ir a home
    if (loggedIn && budget.hasMinimumSetup && loc.startsWith('/onb/')) {
      return '/home';
    }
    return null;
  },
);
