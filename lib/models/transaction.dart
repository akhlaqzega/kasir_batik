import 'cart_item.dart';

/// Model data untuk transaksi penjualan yang berhasil diproses.
/// Menyimpan informasi waktu transaksi, daftar item belanja, perhitungan biaya,
/// metode pembayaran, bukti transfer non-tunai, serta status transaksi.
class TransactionModel {
  final String id;
  final DateTime waktu;
  final List<CartItem> items;
  final double subtotal;
  final double diskonPersen;
  final double ppnPersen; // Bawaan disetel 11%
  final double total;
  final String metodePembayaran; // 'Tunai' atau 'QRIS'
  final double jumlahBayar;
  final double uangKembali;
  
  /// Path lokal untuk gambar foto bukti transfer (jika pembayaran QRIS/Non-Tunai).
  final String? imagePath;
  
  /// Status transaksi, bernilai 'Sukses' atau 'Dibatalkan'.
  String status;

  TransactionModel({
    required this.id,
    required this.waktu,
    required this.items,
    required this.subtotal,
    required this.diskonPersen,
    required this.ppnPersen,
    required this.total,
    required this.metodePembayaran,
    required this.jumlahBayar,
    required this.uangKembali,
    this.imagePath,
    this.status = 'Sukses',
  });

  /// Mengonversi objek TransactionModel menjadi format Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waktu': waktu.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'diskonPersen': diskonPersen,
      'ppnPersen': ppnPersen,
      'total': total,
      'metodePembayaran': metodePembayaran,
      'jumlahBayar': jumlahBayar,
      'uangKembali': uangKembali,
      'imagePath': imagePath,
      'status': status,
    };
  }

  /// Membuat objek TransactionModel dari data Map JSON.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      waktu: DateTime.parse(json['waktu'] as String),
      items: (json['items'] as List)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      diskonPersen: (json['diskonPersen'] as num).toDouble(),
      ppnPersen: (json['ppnPersen'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      metodePembayaran: json['metodePembayaran'] as String,
      jumlahBayar: (json['jumlahBayar'] as num).toDouble(),
      uangKembali: (json['uangKembali'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
      status: json['status'] as String? ?? 'Sukses',
    );
  }
}
