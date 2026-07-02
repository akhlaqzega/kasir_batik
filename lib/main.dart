import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'states/app_state.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'pages/main_shell.dart';
import 'pages/login_page.dart';

void main() async {
  // Pastikan binding Flutter diinisialisasi sebelum Firebase & SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi GoogleSignIn untuk v7.x+
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint('Gagal menginisialisasi GoogleSignIn: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const KasirBatikApp(),
    ),
  );
}

class KasirBatikApp extends StatelessWidget {
  const KasirBatikApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'Kasir Koko Al-Hijrah Batik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainAppShell(),
    );
  }
}

/// Pembungkus reaktif untuk memantau status login pengguna menggunakan StreamBuilder.
class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            ),
          );
        }

        final user = snapshot.data;

        // Perbarui pengguna aktif di AppState setelah frame selesai dibangun
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.updateUser(user);
        });

        if (user != null) {
          return const MainShell();
        }
        return const LoginPage();
      },
    );
  }
}
