import 'product.dart';

/// Model data untuk item dalam keranjang belanja (POS Canvas).
/// Melacak produk yang dipilih, ukuran pakaian yang dipilih, dan jumlahnya.
class CartItem {
  final Product product;
  final String ukuran; // 'M', 'L', 'XL', 'XXL'
  int kuantitas;

  CartItem({
    required this.product,
    required this.ukuran,
    required this.kuantitas,
  });

  /// Menghitung total harga jual untuk item ini.
  double get totalHarga => product.hargaJual * kuantitas;

  /// Menghitung total biaya modal untuk item ini.
  double get totalModal => product.hargaModal * kuantitas;

  /// Mengonversi objek CartItem menjadi format Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'ukuran': ukuran,
      'kuantitas': kuantitas,
    };
  }

  /// Membuat objek CartItem dari data Map JSON.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      ukuran: json['ukuran'] as String,
      kuantitas: json['kuantitas'] as int,
    );
  }
}
