import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─── Stream auth state: null = belum login, User = sudah login ───────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─── Provider service untuk aksi login/logout ────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '455419041525-ufn67lrd40ci21dkp5afqa91vd0mismf.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;

  /// Login sebagai Tamu (Guest Mode)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Daftar dengan Email & Password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    if (currentUser != null && currentUser!.isAnonymous) {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      return await currentUser!.linkWithCredential(credential);
    }
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Masuk dengan Email & Password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Kirim Email Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Login dengan Google (web: signInWithPopup, Android: credential)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: pakai Firebase popup langsung
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        if (currentUser != null && currentUser!.isAnonymous) {
          return await currentUser!.linkWithPopup(provider);
        }
        return await _auth.signInWithPopup(provider);
      } else {
        // Android: pakai google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User batal

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        if (currentUser != null && currentUser!.isAnonymous) {
          return await currentUser!.linkWithCredential(credential);
        }
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
