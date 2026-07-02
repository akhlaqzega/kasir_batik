import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:kasir_batik/main.dart';
import 'package:kasir_batik/states/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Aplikasi Kasir Batik smoke test', (WidgetTester tester) async {
    // Inisialisasi mock SharedPreferences sebelum menjalankan widget
    SharedPreferences.setMockInitialValues({});

    // Bangun aplikasi dengan provider terpasang dan picu frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const KasirBatikApp(),
      ),
    );

    // Lakukan pemompaan frame secara parsial guna menghindari timeout dari animasi 
    // berputar tak terhingga (CircularProgressIndicator) saat pemuatan data asinkron.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi bahwa halaman login berhasil dimuat dengan judul branding "AL-HIJRAH BATIK".
    expect(find.text('AL-HIJRAH BATIK'), findsOneWidget);
    expect(find.text('MASUK KASIR'), findsOneWidget);
  });
}
