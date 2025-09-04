// lib/auth/auth_repository.dart
import 'package:flutter/foundation.dart';

class AuthRepository extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    notifyListeners();
  }

  // NUEVO: registro (mock). Reemplázalo luego por tu backend/Firebase.
  Future<void> signUp(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoggedIn = true; // tras registrarse lo dejamos logueado
    notifyListeners();
  }
}
