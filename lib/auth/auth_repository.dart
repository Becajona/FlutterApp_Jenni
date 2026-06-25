import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthRepository extends ChangeNotifier {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  // Google (Android/iOS)
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get user => _fa.currentUser;
  String? get uid => _fa.currentUser?.uid;
  bool get isLoggedIn => _fa.currentUser != null;

  Stream<User?> get authStateChanges => _fa.authStateChanges();

  /* =====================================================
     EMAIL / PASSWORD
  ====================================================== */

  Future<void> signIn(String email, String password) async {
    await _fa.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    await _fa.createUserWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  /* =====================================================
     LOGOUT
  ====================================================== */
  Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
    try { await FacebookAuth.instance.logOut(); } catch (_) {}
    await _fa.signOut();
    notifyListeners();
  }

  /* =====================================================
     GOOGLE SIGN-IN
  ====================================================== */
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _fa.signInWithPopup(provider);
      } else {
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

  /* =====================================================
     FACEBOOK SIGN-IN
  ====================================================== */

  Future<UserCredential> signInWithFacebook() async {
    try {
      // 1) Login con Facebook (token)
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw 'Inicio de sesión cancelado';
      }

      if (result.status == LoginStatus.failed) {
        throw 'Error en Facebook: ${result.message}';
      }

      final accessToken = result.accessToken;
      if (accessToken == null) {
        throw 'No se recibió el token de acceso de Facebook';
      }

      // 2) Convertir token a credencial Firebase
      final credential = FacebookAuthProvider.credential(accessToken.token);

      // 3) Iniciar sesión con Firebase
      final cred = await _fa.signInWithCredential(credential);

      notifyListeners();
      return cred;
    } catch (e) {
      throw 'Error al iniciar sesión con Facebook: $e';
    }
  }
}
