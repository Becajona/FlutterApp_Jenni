import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository extends ChangeNotifier {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  // En Android/iOS: NO pasar clientId web aquí.
  // En iOS podrías pasar el clientId de iOS si lo registras.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    // En móvil también cerramos Google
    try { await _googleSignIn.signOut(); } catch (_) {}
    await _fa.signOut();
    notifyListeners();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // WEB: usa el clientId Web declarado en index.html + popup
        final provider = GoogleAuthProvider();
        return await _fa.signInWithPopup(provider);
      } else {
        // ANDROID / iOS
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw 'Se canceló el inicio de sesión con Google';
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await _fa.signInWithCredential(credential);
        notifyListeners();
        return cred;
      }
    } catch (e) {
      throw 'Error al iniciar sesión con Google: $e';
    }
  }
}
