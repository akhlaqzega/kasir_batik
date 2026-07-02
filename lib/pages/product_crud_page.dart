import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../states/app_state.dart';
import '../models/product.dart';
import '../app_theme.dart';

/// Halaman CRUD Manajemen Katalog & Stok Ukuran.
/// Memungkinkan penambahan produk baru, pembuatan SKU acak berawalan 899,
/// pembaruan stok spesifik ukuran (M, L, XL, XXL), dan penghapusan produk.
class ProductCrudPage extends StatefulWidget {
  const ProductCrudPage({super.key});

  @override
  State<ProductCrudPage> createState() => _ProductCrudPageState();
}

class _ProductCrudPageState extends State<ProductCrudPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Bilah Pencarian & Tombol Tambah
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => state.setSearchQuery(val),
                        decoration: const InputDecoration(
                          hintText: 'Cari produk berdasarkan nama atau SKU...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Daftar Katalog
                Expanded(
                  child: state.filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'Katalog baju kosong.',
                            style: TextStyle(color: AppTheme.mutedTextColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = state.filteredProducts[index];
                            return _buildProductTile(context, product, state, currencyFormatter);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = Provider.of<AppState>(context, listen: false);
          _showProductFormDialog(context, state, null);
        },
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('TAMBAH PRODUK'),
      ),
    );
  }

  // --- WIDGET LIST TILE PRODUK ---

  Widget _buildProductTile(
    BuildContext context,
    Product product,
    AppState state,
    NumberFormat formatter,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Foto & Nama Produk & Tombol Aksi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO PRODUK
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: product.imagePath != null
                        ? Image.file(
                            File(product.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.broken_image, size: 24));
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryGold.withOpacity(0.08),
                                  AppTheme.lightGold.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.checkroom, color: AppTheme.primaryGold, size: 30),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // DETAIL PRODUK
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.nama,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.brightness == Brightness.dark
                                      ? AppTheme.lightGold
                                      : AppTheme.darkGold,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                tooltip: 'Ubah Data',
                                onPressed: () => _showProductFormDialog(context, state, product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.roseRed, size: 20),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                tooltip: 'Hapus Produk',
                                onPressed: () => _showConfirmDeleteDialog(context, state, product),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product.sku}  |  Kategori: ${product.kategori}',
                        style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Colors.white10),
            // Baris Tengah: Harga Modal & Harga Jual
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Harga Jual: ',
                      style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12.5),
                      children: [
                        TextSpan(
                          text: formatter.format(product.hargaJual),
                          style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Harga Modal: ',
                      style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12.5),
                      children: [
                        TextSpan(
                          text: formatter.format(product.hargaModal),
                          style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Baris Bawah: Rincian Stok Ukuran
            const Text(
              'Stok Per Ukuran:',
              style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['M', 'L', 'XL', 'XXL'].map((size) {
                final stock = product.stokUkuran[size] ?? 0;
                final isOutOfStock = stock == 0;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? AppTheme.roseRed.withOpacity(0.08) : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOutOfStock
                            ? AppTheme.roseRed.withOpacity(0.3)
                            : AppTheme.primaryGold.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          size,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? AppTheme.roseRed : AppTheme.textColor,
                          ),
                        ),
                        Text(
                          '$stock Pcs',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOutOfStock ? AppTheme.roseRed : AppTheme.mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- FORM DIALOG EDIT / ADD ---

  /// Dialog Form untuk Tambah atau Edit Produk.
  void _showProductFormDialog(BuildContext context, AppState state, Product? existingProduct) {
    final isEdit = existingProduct != null;

    final formKey = GlobalKey<FormState>();
    final skuController = TextEditingController(text: existingProduct?.sku ?? '');
    final nameController = TextEditingController(text: existingProduct?.nama ?? '');
    final categoryController = TextEditingController(text: existingProduct?.kategori ?? '');
    final costController = TextEditingController(
      text: existingProduct != null ? existingProduct.hargaModal.toStringAsFixed(0) : '',
    );
    final priceController = TextEditingController(
      text: existingProduct != null ? existingProduct.hargaJual.toStringAsFixed(0) : '',
    );

    // Controller untuk masing-masing ukuran
    final stockMController = TextEditingController(
      text: existingProduct != null ? (existingProduct.stokUkuran['M'] ?? 0).toString() : '0',
    );
    final stockLController = TextEditingController(
      text: existingProduct != null ? (existingProduct.stokUkuran['L'] ?? 0).toString() : '0',
    );
    final stockXLController = TextEditingController(
      text: existingProduct != null ? (existingProduct.stokUkuran['XL'] ?? 0).toString() : '0',
    );
    final stockXXLController = TextEditingController(
      text: existingProduct != null ? (existingProduct.stokUkuran['XXL'] ?? 0).toString() : '0',
    );

    showDialog(
      context: context,
      builder: (context) {
        String? selectedImagePath = existingProduct?.imagePath;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'UBAH DATA PRODUK' : 'TAMBAH PRODUK BARU',
                style: const TextStyle(color: AppTheme.primaryGold, letterSpacing: 1.0),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image Selector & Preview
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedImagePath = picked.path;
                                  });
                                }
                              } catch (e) {
                                debugPrint('Gagal memilih gambar: $e');
                              }
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: AppTheme.primaryGold.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: selectedImagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        File(selectedImagePath!),
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: AppTheme.roseRed,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Pilih Foto',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        // SKU & Tombol Acak Barcode
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: skuController,
                                keyboardType: TextInputType.number,
                                enabled: !isEdit, // SKU tidak boleh diubah jika mode edit
                                decoration: const InputDecoration(
                                  labelText: 'SKU / Barcode',
                                  prefixIcon: Icon(Icons.qr_code),
                                  hintText: '899...',
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'SKU wajib diisi';
                                  if (val.length < 5) return 'SKU minimal 5 karakter';
                                  return null;
                                },
                              ),
                            ),
                            if (!isEdit) ...[
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: InkWell(
                                  onTap: () {
                                    final randomSku = state.generateRandomSku();
                                    setDialogState(() {
                                      skuController.text = randomSku;
                                    });
                                  },
                                  child: Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGold.withOpacity(0.1),
                                      border: Border.all(color: AppTheme.primaryGold),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.cached, color: AppTheme.primaryGold),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Nama Produk
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk Baju Koko',
                            prefixIcon: Icon(Icons.shopping_bag),
                            hintText: 'e.g. Koko Batik Al-Hijrah Lengan Panjang...',
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        // Kategori
                        TextFormField(
                          controller: categoryController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Kategori Produk',
                            prefixIcon: Icon(Icons.category),
                            hintText: 'e.g. Lengan Panjang / Lengan Pendek / Kurta',
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Kategori wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        // Harga Modal & Harga Jual
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: costController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga Modal (Rp)',
                                  prefixText: 'Rp ',
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Harga modal wajib';
                                  if (double.tryParse(val) == null) return 'Harus angka';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga Jual (Rp)',
                                  prefixText: 'Rp ',
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Harga jual wajib';
                                  final cost = double.tryParse(costController.text) ?? 0.0;
                                  final price = double.tryParse(val) ?? 0.0;
                                  if (price == 0.0) return 'Harus angka';
                                  if (price < cost) return 'Jual < Modal (Rugi)';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Manajemen Stok Ukuran
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Inventaris Stok Per Ukuran:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildStockField('M', stockMController),
                            const SizedBox(width: 6),
                            _buildStockField('L', stockLController),
                            const SizedBox(width: 6),
                            _buildStockField('XL', stockXLController),
                            const SizedBox(width: 6),
                            _buildStockField('XXL', stockXXLController),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('BATAL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final sku = skuController.text.trim();
                      final nama = nameController.text.trim();
                      final kategori = categoryController.text.trim();
                      final modal = double.parse(costController.text);
                      final jual = double.parse(priceController.text);

                      final Map<String, int> stok = {
                        'M': int.tryParse(stockMController.text) ?? 0,
                        'L': int.tryParse(stockLController.text) ?? 0,
                        'XL': int.tryParse(stockXLController.text) ?? 0,
                        'XXL': int.tryParse(stockXXLController.text) ?? 0,
                      };

                      final product = Product(
                        sku: sku,
                        nama: nama,
                        kategori: kategori,
                        hargaModal: modal,
                        hargaJual: jual,
                        stokUkuran: stok,
                        imagePath: selectedImagePath,
                      );

                      if (isEdit) {
                        await state.updateProduk(product);
                      } else {
                        // Cek jika SKU sudah terpakai
                        final exists = state.products.any((p) => p.sku == sku);
                        if (exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SKU produk sudah terdaftar di katalog!'),
                              backgroundColor: AppTheme.roseRed,
                            ),
                          );
                          return;
                        }
                        await state.tambahProduk(product);
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Produk berhasil diperbarui!' : 'Produk berhasil ditambahkan!'),
                          backgroundColor: AppTheme.emeraldGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('SIMPAN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Membuat field input stok ukuran baju.
  Widget _buildStockField(String size, TextEditingController controller) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: 'Size $size',
          labelStyle: const TextStyle(fontSize: 10),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          fillColor: AppTheme.bgColor,
        ),
        validator: (val) {
          if (val == null || val.isEmpty) return 'Keterangan stok harus diisi';
          if (int.tryParse(val) == null) return 'Angka';
          return null;
        },
      ),
    );
  }

  // --- CONFIRM DELETE DIALOG ---

  /// Dialog konfirmasi sebelum menghapus produk dari katalog.
  void _showConfirmDeleteDialog(BuildContext context, AppState state, Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('HAPUS PRODUK KATALOG?'),
          content: Text('Apakah Anda yakin ingin menghapus "${product.nama}" secara permanen dari sistem?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
              onPressed: () async {
                await state.hapusProduk(product.sku);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produk berhasil dihapus!'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              },
              child: const Text('YA, HAPUS', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
