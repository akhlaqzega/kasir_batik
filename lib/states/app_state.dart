import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

/// Provider pusat untuk pengatur logika aplikasi Kasir Batik.
/// Mengatur keranjang belanja, integrasi kamera (ImagePicker),
/// perhitungan keuangan, pengurangan & pengembalian stok, serta CRUD produk.
class AppState extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _currentUser;
  List<Product> _products = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  // Manajemen Filter & Pencarian
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  // State Keranjang Belanja
  final List<CartItem> _cartItems = [];

  // State Transaksi Berjalan (Checkout)
  String _metodePembayaran = 'Tunai'; // 'Tunai' atau 'QRIS'
  double _diskonPersen = 0.0;
  double _ppnPersen = 11.0; // Bawaan Pajak PPN 11%
  double _jumlahBayar = 0.0;
  String? _buktiTransferPath;
  bool _isDarkMode = true;

  // State Monitoring Sinkronisasi Firestore
  bool _firestoreError = false;
  String? _lastFirestoreError;

  // Getters
  List<Product> get products => _products;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<CartItem> get cartItems => _cartItems;
  String get metodePembayaran => _metodePembayaran;
  double get diskonPersen => _diskonPersen;
  double get ppnPersen => _ppnPersen;
  double get jumlahBayar => _jumlahBayar;
  String? get buktiTransferPath => _buktiTransferPath;
  bool get isDarkMode => _isDarkMode;
  User? get currentUser => _currentUser;
  bool get firestoreError => _firestoreError;
  String? get lastFirestoreError => _lastFirestoreError;

  /// Kategori unik dari produk yang terdaftar
  List<String> get categories {
    final list = _products.map((p) => p.kategori).toSet().toList();
    list.sort();
    return ['Semua', ...list];
  }

  /// Produk yang disaring berdasarkan kategori dan pencarian kata kunci
  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Semua' || 
          product.kategori.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = product.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.sku.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Konstruktor - langsung memuat data
  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _isDarkMode = await _storageService.getThemeMode();

    if (_currentUser != null) {
      try {
        final uid = _currentUser!.uid;
        _products = await _firestoreService.getProducts(uid);
        if (_products.isEmpty) {
          // Pertama kali masuk, semai Firestore dengan data produk awal agar tidak kosong
          final localSeed = await _storageService.getProducts();
          for (var p in localSeed) {
            await _firestoreService.saveProduct(uid, p);
          }
          _products = localSeed;
        }
        _transactions = await _firestoreService.getTransactions(uid);
        _firestoreError = false;
        _lastFirestoreError = null;
      } catch (e) {
        debugPrint('Gagal memuat data dari Firestore: $e');
        _firestoreError = true;
        _lastFirestoreError = e.toString();
        _products = await _storageService.getProducts();
        _transactions = await _storageService.getTransactions();
      }
    } else {
      _products = await _storageService.getProducts();
      _transactions = await _storageService.getTransactions();
      _firestoreError = false;
      _lastFirestoreError = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Memperbarui pengguna aktif dan memuat ulang datanya secara reaktif
  void updateUser(User? user) {
    if (_currentUser?.uid != user?.uid) {
      _currentUser = user;
      loadData();
    }
  }

  /// Mengubah tema aplikasi antara Terang & Gelap
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  // --- LOGIKA FILTER ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // --- LOGIKA KERANJANG BELANJA (POS CANVAS) ---

  /// Menambahkan produk ke keranjang dengan validasi stok real-time
  bool addToCart(Product product, String ukuran, int kuantitas) {
    // Cari sisa stok di katalog
    final productInList = _products.firstWhere((p) => p.sku == product.sku);
    final availableStock = productInList.stokUkuran[ukuran] ?? 0;

    // Cari kuantitas yang sudah ada di keranjang untuk produk dan ukuran ini
    int currentInCart = 0;
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.sku == product.sku && item.ukuran == ukuran
    );
    if (existingIndex != -1) {
      currentInCart = _cartItems[existingIndex].kuantitas;
    }

    // Validasi stok
    if (currentInCart + kuantitas > availableStock) {
      return false; // Stok tidak cukup
    }

    if (existingIndex != -1) {
      _cartItems[existingIndex].kuantitas += kuantitas;
    } else {
      _cartItems.add(CartItem(
        product: product,
        ukuran: ukuran,
        kuantitas: kuantitas,
      ));
    }
    notifyListeners();
    return true;
  }

  /// Memperbarui kuantitas item keranjang dengan validasi stok
  bool updateCartItemQty(CartItem item, int delta) {
    final index = _cartItems.indexOf(item);
    if (index == -1) return false;

    final targetQty = item.kuantitas + delta;
    if (targetQty <= 0) {
      _cartItems.removeAt(index);
      notifyListeners();
      return true;
    }

    // Validasi ke stok produk asli di katalog
    final productInList = _products.firstWhere((p) => p.sku == item.product.sku);
    final availableStock = productInList.stokUkuran[item.ukuran] ?? 0;

    if (targetQty > availableStock) {
      return false; // Melebihi stok
    }

    _cartItems[index].kuantitas = targetQty;
    notifyListeners();
    return true;
  }

  /// Menghapus item dari keranjang
  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  /// Mengosongkan keranjang belanja
  void clearCart() {
    _cartItems.clear();
    resetPaymentStates();
    notifyListeners();
  }

  // --- LOGIKA KALKULASI FINANSIAL KASIR ---
  double get cartSubtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalHarga);
  }

  double get cartDiscountAmount {
    return cartSubtotal * (_diskonPersen / 100);
  }

  double get cartTaxAmount {
    return (cartSubtotal - cartDiscountAmount) * (_ppnPersen / 100);
  }

  double get cartTotal {
    return (cartSubtotal - cartDiscountAmount) + cartTaxAmount;
  }

  double get uangKembali {
    if (_metodePembayaran == 'QRIS') return 0.0;
    final selisih = _jumlahBayar - cartTotal;
    return selisih >= 0 ? selisih : 0.0;
  }

  bool get isBayarKurang {
    if (_metodePembayaran == 'QRIS') return false;
    return _jumlahBayar < cartTotal;
  }

  // --- LOGIKA PENGATURAN PEMBAYARAN & KAMERA ---
  void setMetodePembayaran(String metode) {
    _metodePembayaran = metode;
    if (metode == 'QRIS') {
      _jumlahBayar = cartTotal; // QRIS selalu pas
    } else {
      _jumlahBayar = 0.0; // Reset nominal cash
    }
    notifyListeners();
  }

  void setDiskonPersen(double diskon) {
    _diskonPersen = diskon;
    if (_metodePembayaran == 'QRIS') {
      _jumlahBayar = cartTotal;
    }
    notifyListeners();
  }

  void setPpnPersen(double ppn) {
    _ppnPersen = ppn;
    if (_metodePembayaran == 'QRIS') {
      _jumlahBayar = cartTotal;
    }
    notifyListeners();
  }

  void setJumlahBayar(double nominal) {
    _jumlahBayar = nominal;
    notifyListeners();
  }

  void setBuktiTransferPath(String? path) {
    _buktiTransferPath = path;
    notifyListeners();
  }

  /// Membuka kamera menggunakan package `image_picker` untuk mengambil foto bukti transfer
  Future<bool> ambilFotoBuktiTransfer() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60, // Kompres gambar agar tidak memakan memori besar
      );
      if (pickedFile != null) {
        _buktiTransferPath = pickedFile.path;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Gagal mengambil foto bukti transfer: $e');
      return false;
    }
  }

  /// Mereset data kasir setelah checkout atau pembatalan
  void resetPaymentStates() {
    _metodePembayaran = 'Tunai';
    _diskonPersen = 0.0;
    _ppnPersen = 11.0;
    _jumlahBayar = 0.0;
    _buktiTransferPath = null;
  }

  // --- LOGIKA CHECKOUT TRANSAKSI ---

  /// Menyelesaikan transaksi pembelian, mengurangi stok produk, dan menyimpan riwayat
  Future<TransactionModel?> checkout() async {
    if (_cartItems.isEmpty) return null;
    if (_metodePembayaran == 'Tunai' && isBayarKurang) return null;
    if (_metodePembayaran == 'QRIS' && _buktiTransferPath == null) return null;

    final now = DateTime.now();
    final trxId = 'TRX-${now.millisecondsSinceEpoch}';

    // 1. Kurangi stok produk secara permanen dari katalog
    for (var cartItem in _cartItems) {
      final prodIndex = _products.indexWhere((p) => p.sku == cartItem.product.sku);
      if (prodIndex != -1) {
        final product = _products[prodIndex];
        final currentStock = product.stokUkuran[cartItem.ukuran] ?? 0;
        final updatedStock = Map<String, int>.from(product.stokUkuran);
        updatedStock[cartItem.ukuran] = max(0, currentStock - cartItem.kuantitas);

        _products[prodIndex] = product.copyWith(stokUkuran: updatedStock);
      }
    }

    // 2. Buat objek transaksi baru
    final newTrx = TransactionModel(
      id: trxId,
      waktu: now,
      items: List<CartItem>.from(_cartItems),
      subtotal: cartSubtotal,
      diskonPersen: _diskonPersen,
      ppnPersen: _ppnPersen,
      total: cartTotal,
      metodePembayaran: _metodePembayaran,
      jumlahBayar: _metodePembayaran == 'QRIS' ? cartTotal : _jumlahBayar,
      uangKembali: _metodePembayaran == 'QRIS' ? 0.0 : uangKembali,
      imagePath: _buktiTransferPath,
      status: 'Sukses',
    );

    // 3. Tambahkan ke daftar riwayat (transaksi terbaru di atas)
    _transactions.insert(0, newTrx);

    // 4. Simpan ke database lokal & Firestore jika login
    await _storageService.saveProducts(_products);
    await _storageService.saveTransactions(_transactions);

    if (_currentUser != null) {
      final uid = _currentUser!.uid;
      try {
        await _firestoreService.saveTransaction(uid, newTrx);
        for (var cartItem in _cartItems) {
          final prodIndex = _products.indexWhere((p) => p.sku == cartItem.product.sku);
          if (prodIndex != -1) {
            await _firestoreService.saveProduct(uid, _products[prodIndex]);
          }
        }
        _firestoreError = false;
        _lastFirestoreError = null;
      } catch (e) {
        debugPrint('Gagal menyimpan transaksi ke Firestore: $e');
        _firestoreError = true;
        _lastFirestoreError = e.toString();
      }
    }

    // 5. Bersihkan keranjang
    _cartItems.clear();
    resetPaymentStates();

    notifyListeners();
    return newTrx;
  }

  /// Membatalkan nota transaksi lama, mengembalikan status menjadi "Dibatalkan",
  /// dan mengembalikan stok ukuran produk secara otomatis & akurat.
  Future<void> batalNota(String trxId) async {
    final trxIndex = _transactions.indexWhere((t) => t.id == trxId);
    if (trxIndex == -1) return;
    
    final transaction = _transactions[trxIndex];
    if (transaction.status == 'Dibatalkan') return;

    // 1. Ubah status transaksi
    transaction.status = 'Dibatalkan';

    // 2. Kembalikan stok untuk setiap item baju koko batik dalam transaksi tersebut
    for (var cartItem in transaction.items) {
      final prodIndex = _products.indexWhere((p) => p.sku == cartItem.product.sku);
      if (prodIndex != -1) {
        final product = _products[prodIndex];
        final currentStock = product.stokUkuran[cartItem.ukuran] ?? 0;
        final updatedStock = Map<String, int>.from(product.stokUkuran);
        
        // Tambahkan kembali stok yang terjual
        updatedStock[cartItem.ukuran] = currentStock + cartItem.kuantitas;
        _products[prodIndex] = product.copyWith(stokUkuran: updatedStock);
      }
    }

    // 3. Simpan perubahan ke penyimpanan lokal & Firestore jika login
    await _storageService.saveProducts(_products);
    await _storageService.saveTransactions(_transactions);

    if (_currentUser != null) {
      final uid = _currentUser!.uid;
      try {
        await _firestoreService.updateTransactionStatus(uid, trxId, 'Dibatalkan');
        for (var cartItem in transaction.items) {
          final prodIndex = _products.indexWhere((p) => p.sku == cartItem.product.sku);
          if (prodIndex != -1) {
            await _firestoreService.saveProduct(uid, _products[prodIndex]);
          }
        }
        _firestoreError = false;
        _lastFirestoreError = null;
      } catch (e) {
        debugPrint('Gagal membatalkan transaksi di Firestore: $e');
        _firestoreError = true;
        _lastFirestoreError = e.toString();
      }
    }

    notifyListeners();
  }

  // --- LOGIKA CRUD MANAJEMEN KATALOG & STOK ---

  /// Menambah produk baru ke katalog
  Future<void> tambahProduk(Product product) async {
    _products.add(product);
    await _storageService.saveProducts(_products);
    if (_currentUser != null) {
      try {
        await _firestoreService.saveProduct(_currentUser!.uid, product);
        _firestoreError = false;
        _lastFirestoreError = null;
      } catch (e) {
        debugPrint('Gagal tambah produk ke Firestore: $e');
        _firestoreError = true;
        _lastFirestoreError = e.toString();
      }
    }
    notifyListeners();
  }

  /// Memperbarui informasi produk yang sudah ada di katalog
  Future<void> updateProduk(Product product) async {
    final index = _products.indexWhere((p) => p.sku == product.sku);
    if (index != -1) {
      _products[index] = product;
      await _storageService.saveProducts(_products);
      if (_currentUser != null) {
        try {
          await _firestoreService.saveProduct(_currentUser!.uid, product);
          _firestoreError = false;
          _lastFirestoreError = null;
        } catch (e) {
          debugPrint('Gagal perbarui produk ke Firestore: $e');
          _firestoreError = true;
          _lastFirestoreError = e.toString();
        }
      }
      notifyListeners();
    }
  }

  /// Menghapus produk secara permanen dari katalog
  Future<void> hapusProduk(String sku) async {
    _products.removeWhere((p) => p.sku == sku);
    await _storageService.saveProducts(_products);
    if (_currentUser != null) {
      try {
        await _firestoreService.deleteProduct(_currentUser!.uid, sku);
        _firestoreError = false;
        _lastFirestoreError = null;
      } catch (e) {
        debugPrint('Gagal hapus produk dari Firestore: $e');
        _firestoreError = true;
        _lastFirestoreError = e.toString();
      }
    }
    notifyListeners();
  }

  /// Mereset seluruh data lokal & cloud ke keadaan awal dengan hanya 1 produk default
  Future<void> resetAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Hapus Firestore jika terhubung
      if (_currentUser != null) {
        final uid = _currentUser!.uid;
        await _firestoreService.clearAllUserData(uid);
      }

      // 2. Bersihkan SharedPreferences dengan menulis ulang data kosong
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kasir_batik_products');
      await prefs.remove('kasir_batik_transactions');

      // 3. Muat kembali data (ini akan memicu seeding ulang dengan 1 produk saja)
      await loadData();
    } catch (e) {
      debugPrint('Error saat reset data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Membuat kode barcode acak standar Indonesia berawalan 899 (13 digit)
  String generateRandomSku() {
    final random = Random();
    String sku = '899'; // Barcode prefix Indonesia
    for (int i = 0; i < 10; i++) {
      sku += random.nextInt(10).toString();
    }
    return sku;
  }
}
