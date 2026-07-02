/// Model data untuk produk Koko Batik.
/// Menyimpan informasi katalog serta stok yang spesifik berdasarkan ukuran.
class Product {
  final String sku;
  final String nama;
  final String kategori;
  final double hargaModal;
  final double hargaJual;
  
  /// Peta stok berdasarkan ukuran. Kunci yang valid adalah: 'M', 'L', 'XL', 'XXL'.
  final Map<String, int> stokUkuran;

  /// Jalur file lokal untuk foto produk
  final String? imagePath;

  Product({
    required this.sku,
    required this.nama,
    required this.kategori,
    required this.hargaModal,
    required this.hargaJual,
    required this.stokUkuran,
    this.imagePath,
  });

  /// Menggandakan objek dengan perubahan nilai tertentu.
  Product copyWith({
    String? sku,
    String? nama,
    String? kategori,
    double? hargaModal,
    double? hargaJual,
    Map<String, int>? stokUkuran,
    String? imagePath,
  }) {
    return Product(
      sku: sku ?? this.sku,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      hargaModal: hargaModal ?? this.hargaModal,
      hargaJual: hargaJual ?? this.hargaJual,
      stokUkuran: stokUkuran ?? Map<String, int>.from(this.stokUkuran),
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Mengonversi objek Product menjadi format Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'nama': nama,
      'kategori': kategori,
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
      'stokUkuran': stokUkuran,
      'imagePath': imagePath,
    };
  }

  /// Membuat objek Product dari data Map JSON.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      sku: json['sku'] as String,
      nama: json['nama'] as String,
      kategori: json['kategori'] as String,
      hargaModal: (json['hargaModal'] as num).toDouble(),
      hargaJual: (json['hargaJual'] as num).toDouble(),
      stokUkuran: Map<String, int>.from(json['stokUkuran'] as Map),
      imagePath: json['imagePath'] as String?,
    );
  }
}
