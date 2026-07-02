import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Layanan untuk mengelola autentikasi pengguna menggunakan Firebase.
/// Mendukung masuk dengan Email & Sandi, Pendaftaran, dan masuk dengan Akun Google (v7.x+).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Mendapatkan user yang sedang aktif saat ini
  User? get currentUser => _auth.currentUser;

  /// Mengalirkan status autentikasi secara reaktif
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Masuk menggunakan Email dan Kata Sandi
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error sign in email: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error sign in email umum: $e');
      rethrow;
    }
  }

  /// Mendaftar akun baru menggunakan Email dan Kata Sandi
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error sign up email: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error sign up email umum: $e');
      rethrow;
    }
  }

  /// Masuk menggunakan akun Google (Google Sign-In dengan API v7.x+)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Pemicu proses masuk akun Google menggunakan API authenticate() baru
      final googleUser = await _googleSignIn.authenticate();

      // 2. Mendapatkan detail autentikasi (Synchronous di v7.x+)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Membuat kredensial baru untuk Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase menggunakan kredensial tersebut
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error Google Sign-in Firebase: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error Google Sign-in umum: $e');
      rethrow;
    }
  }

  /// Keluar akun (Sign Out) dari Firebase dan Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          debugPrint('Google Sign-out diabaikan/gagal: $e');
        }
      }
    } catch (e) {
      debugPrint('Gagal keluar akun: $e');
      rethrow;
    }
  }
}
