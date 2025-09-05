import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository extends ChangeNotifier {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  User? get user => _fa.currentUser;
  String? get uid => _fa.currentUser?.uid;
  bool get isLoggedIn => _fa.currentUser != null;

  Stream<User?> get authStateChanges => _fa.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _fa.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    await _fa.createUserWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _fa.signOut();
    notifyListeners();
  }
}
