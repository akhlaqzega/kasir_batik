import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/transaction.dart';

/// Layanan untuk menyinkronkan data dengan Firebase Cloud Firestore.
/// Setiap data disimpan secara privat per pengguna (`users/{uid}/...`).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- LOGIKA MANAJEMEN KATALOG PRODUK ---

  /// Mengambil semua produk dari Cloud Firestore milik pengguna
  Future<List<Product>> getProducts(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).collection('products').get();
      if (snapshot.docs.isEmpty) {
        return [];
      }
      return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Gagal mengambil produk dari Firestore: $e');
      rethrow;
    }
  }

  /// Menambah atau memperbarui produk di Cloud Firestore
  Future<void> saveProduct(String uid, Product product) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('products')
          .doc(product.sku)
          .set(product.toJson());
    } catch (e) {
      debugPrint('Gagal menyimpan produk ke Firestore: $e');
      rethrow;
    }
  }

  /// Menghapus produk secara permanen dari Cloud Firestore
  Future<void> deleteProduct(String uid, String sku) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('products')
          .doc(sku)
          .delete();
    } catch (e) {
      debugPrint('Gagal menghapus produk dari Firestore: $e');
      rethrow;
    }
  }

  // --- LOGIKA RIWAYAT TRANSAKSI ---

  /// Mengambil semua riwayat transaksi milik pengguna (urut waktu terbaru)
  Future<List<TransactionModel>> getTransactions(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .orderBy('waktu', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Gagal mengambil transaksi dari Firestore: $e');
      rethrow;
    }
  }

  /// Menyimpan transaksi baru ke Cloud Firestore
  Future<void> saveTransaction(String uid, TransactionModel transaction) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Gagal menyimpan transaksi ke Firestore: $e');
      rethrow;
    }
  }

  /// Memperbarui status transaksi (misal: Batal Nota) ke Cloud Firestore
  Future<void> updateTransactionStatus(String uid, String trxId, String status) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(trxId)
          .update({'status': status});
    } catch (e) {
      debugPrint('Gagal memperbarui status transaksi di Firestore: $e');
      rethrow;
    }
  }

  /// Menghapus seluruh data produk dan transaksi milik pengguna dari Firestore secara rekursif
  Future<void> clearAllUserData(String uid) async {
    try {
      // 1. Ambil semua produk milik user
      final productsSnapshot = await _db.collection('users').doc(uid).collection('products').get();
      for (var doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // 2. Ambil semua transaksi milik user
      final transactionsSnapshot = await _db.collection('users').doc(uid).collection('transactions').get();
      for (var doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Gagal menghapus data user di Firestore: $e');
      rethrow;
    }
  }
}
