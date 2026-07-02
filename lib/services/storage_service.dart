import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/transaction.dart';

/// Layanan penyimpanan lokal menggunakan SharedPreferences.
/// Layanan ini bertanggung jawab untuk menyimpan, mengambil, dan
/// menyemai (seeding) data awal produk serta riwayat transaksi.
class StorageService {
  static const String _keyProducts = 'kasir_batik_products';
  static const String _keyTransactions = 'kasir_batik_transactions';

  /// Mendapatkan daftar produk dari penyimpanan lokal.
  /// Jika kosong, maka akan memanggil fungsi untuk menyemai data produk awal.
  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProducts);
    if (jsonStr == null) {
      final defaultProducts = _getSeedProducts();
      await saveProducts(defaultProducts);
      return defaultProducts;
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      // Jika terjadi error parsing, kembalikan data awal
      return _getSeedProducts();
    }
  }

  /// Menyimpan daftar produk secara permanen ke penyimpanan lokal.
  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_keyProducts, jsonStr);
  }

  /// Mendapatkan riwayat transaksi dari penyimpanan lokal.
  /// Jika kosong, maka akan menyemai data transaksi 7 hari terakhir agar dashboard terlihat indah.
  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyTransactions);
    if (jsonStr == null) {
      final seedTransactions = _getSeedTransactions();
      await saveTransactions(seedTransactions);
      return seedTransactions;
    }
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Menyimpan riwayat transaksi secara permanen ke penyimpanan lokal.
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTransactions, jsonStr);
  }

  /// Data produk simulasi bawaan untuk butik batik premium Koko Al-Hijrah.
  List<Product> _getSeedProducts() {
    return [
      Product(
        sku: '8991001230010',
        nama: 'Koko Al-Hijrah Batik Safir Navy Lengan Pendek',
        kategori: 'Lengan Pendek',
        hargaModal: 120000.0,
        hargaJual: 245000.0,
        stokUkuran: {'M': 10, 'L': 12, 'XL': 8, 'XXL': 3},
        imagePath: 'assets/images/koko_navy.jpg',
      ),
      Product(
        sku: '8991001230027',
        nama: 'Koko Al-Hijrah Batik Onyx Grey Lengan Pendek',
        kategori: 'Lengan Pendek',
        hargaModal: 125000.0,
        hargaJual: 255000.0,
        stokUkuran: {'M': 8, 'L': 15, 'XL': 10, 'XXL': 2},
        imagePath: 'assets/images/koko_grey.jpg',
      ),
      Product(
        sku: '8991001230034',
        nama: 'Koko Kurta Signature White Gold Lengan Panjang',
        kategori: 'Lengan Panjang',
        hargaModal: 135000.0,
        hargaJual: 275000.0,
        stokUkuran: {'M': 12, 'L': 10, 'XL': 6, 'XXL': 4},
        imagePath: 'assets/images/koko_white_gold.png',
      ),
      Product(
        sku: '8991001230041',
        nama: 'Koko Batik Symmetrical Onyx White Lengan Panjang',
        kategori: 'Lengan Panjang',
        hargaModal: 145000.0,
        hargaJual: 295000.0,
        stokUkuran: {'M': 6, 'L': 8, 'XL': 4, 'XXL': 1},
        imagePath: 'assets/images/koko_white_black.png',
      ),
    ];
  }

  /// Data riwayat transaksi simulasi (dikosongkan atas permintaan pengguna).
  List<TransactionModel> _getSeedTransactions() {
    return [];
  }

  static const String _keyThemeMode = 'kasir_batik_theme_mode';

  /// Membaca pilihan tema dari memori lokal (bawaan true = Gelap)
  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThemeMode) ?? true;
  }

  /// Menyimpan pilihan tema ke memori lokal
  Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, isDark);
  }
}
