import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../states/app_state.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../app_theme.dart';

/// Halaman Kanvas POS (Point of Sale) & Keranjang Belanja.
/// Layout responsif mendukung desktop/tablet (sidebar keranjang) dan mobile (keranjang geser bawah).
/// Dilengkapi Size Picker, kalkulator kembalian/kekurangan tunai, dan kamera bukti transfer QRIS.
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _cashController.dispose();
    _discountController.dispose();
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth >= 900;

              if (isLargeScreen) {
                // Tampilan Desktop/Tablet (Katalog Kiri, Keranjang Kanan)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildCatalogSection(context, state, currencyFormatter),
                    ),
                    const VerticalDivider(width: 1, thickness: 1, color: AppTheme.bgColor),
                    Expanded(
                      flex: 3,
                      child: _buildCartSidebar(context, state, currencyFormatter),
                    ),
                  ],
                );
              } else {
                // Tampilan Mobile (Katalog Penuh, Floating Button Keranjang di Bawah)
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 70.0),
                      child: _buildCatalogSection(context, state, currencyFormatter),
                    ),
                    if (state.cartItems.isNotEmpty)
                      _buildMobileCartFloatingButton(context, state, currencyFormatter),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  // --- BAGIAN KATALOG ---

  Widget _buildCatalogSection(
    BuildContext context,
    AppState state,
    NumberFormat formatter,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Baris Pencarian
          TextField(
            controller: _searchController,
            onChanged: (val) => state.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Cari nama produk koko...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        state.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Baris Filter Kategori Horizontal
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final isSelected = state.selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      state.setSelectedCategory(category);
                    },
                    selectedColor: AppTheme.primaryGold.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryGold,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryGold : AppTheme.textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryGold : AppTheme.mutedTextColor.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Grid Katalog Produk
          Expanded(
            child: state.filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Produk tidak ditemukan.',
                      style: TextStyle(color: AppTheme.mutedTextColor),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: state.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = state.filteredProducts[index];
                      return _buildProductCard(context, product, state, formatter);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Membuat visual kartu produk dengan indikator level stok.
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    AppState state,
    NumberFormat formatter,
  ) {
    // Hitung total stok baju koko di semua ukuran
    final totalStock = product.stokUkuran.values.fold(0, (sum, val) => sum + val);

    // Warna indikator stok
    Color stockColor;
    String stockStatusText;
    if (totalStock == 0) {
      stockColor = AppTheme.roseRed;
      stockStatusText = 'Habis';
    } else if (totalStock <= 5) {
      stockColor = Colors.orange;
      stockStatusText = 'Stok Menipis';
    } else {
      stockColor = AppTheme.emeraldGreen;
      stockStatusText = 'Tersedia';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: totalStock > 0 ? () => _showSizePickerSheet(context, product, state) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar/Icon batik placeholder di atas kartu
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [AppTheme.bgColor, AppTheme.cardColor]
                        : [Colors.grey.shade100, Colors.grey.shade200],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: product.imagePath != null
                    ? GestureDetector(
                        onTap: () => AppTheme.showZoomedImage(context, product.imagePath),
                        child: Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: AppTheme.roseRed),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.checkroom,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
            // Info Produk
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lencana Kategori
                  Text(
                    product.kategori.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nama Produk
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Harga
                  Text(
                    formatter.format(product.hargaJual),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Baris Status Stok
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$stockStatusText ($totalStock Pcs)',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: stockColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIZE PICKER BOTTOM SHEET ---

  /// Dialog pemilihan ukuran sebelum barang masuk keranjang.
  void _showSizePickerSheet(BuildContext context, Product product, AppState state) {
    String selectedSize = 'M';
    int selectedQty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableStock = product.stokUkuran[selectedSize] ?? 0;
            
            // Periksa jika barang sudah ada di keranjang untuk ukuran terpilih
            int alreadyInCart = 0;
            final cartIndex = state.cartItems.indexWhere(
              (i) => i.product.sku == product.sku && i.ukuran == selectedSize
            );
            if (cartIndex != -1) {
              alreadyInCart = state.cartItems[cartIndex].kuantitas;
            }

            final maxAllowedAdd = availableStock - alreadyInCart;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul & Nama Baju
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PILIH UKURAN KOKO',
                        style: TextStyle(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pemilihan Ukuran Baju
                  const Text(
                    'Ukuran Tersedia:',
                    style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['M', 'L', 'XL', 'XXL'].map((size) {
                      final stock = product.stokUkuran[size] ?? 0;
                      final isSelected = selectedSize == size;
                      final isOutOfStock = stock == 0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: isOutOfStock
                                ? null
                                : () {
                                    setModalState(() {
                                      selectedSize = size;
                                      selectedQty = 1; // Reset qty ke 1
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryGold
                                    : isOutOfStock
                                        ? (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white10
                                            : Colors.grey.shade200)
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? AppTheme.cardColor
                                            : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryGold
                                      : isOutOfStock
                                          ? Colors.transparent
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white10
                                              : Colors.grey.shade300),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    size,
                                    style: TextStyle(
                                      color: isOutOfStock
                                          ? (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white24
                                              : Colors.grey.shade400)
                                          : isSelected
                                              ? Colors.black
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOutOfStock ? 'Habis' : '$stock Pcs',
                                    style: TextStyle(
                                      color: isOutOfStock
                                          ? AppTheme.roseRed.withOpacity(0.6)
                                          : isSelected
                                              ? Colors.black54
                                              : AppTheme.mutedTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Pemilihan Jumlah Kuantitas Belanja
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kuantitas Pembelian:',
                            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Divalidasi dengan sisa stok',
                            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: selectedQty > 1
                                ? () => setModalState(() => selectedQty--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.lightGold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$selectedQty',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: selectedQty < maxAllowedAdd
                                ? () => setModalState(() => selectedQty++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.lightGold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tombol Konfirmasi Masuk Keranjang
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: maxAllowedAdd <= 0
                          ? null
                          : () {
                              final success = state.addToCart(product, selectedSize, selectedQty);
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dimasukkan: ${product.nama} ($selectedSize) x$selectedQty'),
                                    backgroundColor: AppTheme.emeraldGreen,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                      child: Text(
                        maxAllowedAdd <= 0
                            ? 'STOK DI KERANJANG SUDAH MAKSIMAL'
                            : 'TAMBAHKAN KE KERANJANG',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- BAGIAN KERANJANG BELANJA SIDEBAR (DESKTOP) ---

  Widget _buildCartSidebar(
    BuildContext context,
    AppState state,
    NumberFormat formatter,
  ) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          // Header Keranjang
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppTheme.cardColor.withOpacity(0.5),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppTheme.primaryGold),
                const SizedBox(width: 10),
                const Text(
                  'KERANJANG BELANJA',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.cartItems.length} Item',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // List Item Keranjang
          Expanded(
            child: state.cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.mutedTextColor),
                        SizedBox(height: 12),
                        Text(
                          'Keranjang masih kosong',
                          style: TextStyle(color: AppTheme.mutedTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = state.cartItems[index];
                      return _buildCartItemTile(context, item, state, formatter);
                    },
                  ),
          ),
          const Divider(height: 1, color: AppTheme.bgColor),
          // Perhitungan & Tombol Checkout
          if (state.cartItems.isNotEmpty)
            _buildCalculatorSection(context, state, formatter),
        ],
      ),
    );
  }

  /// Membuat visual tile list item keranjang.
  Widget _buildCartItemTile(
    BuildContext context,
    CartItem item,
    AppState state,
    NumberFormat formatter,
  ) {
    return Dismissible(
      key: Key('${item.product.sku}-${item.ukuran}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.roseRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        state.removeFromCart(item);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: item.product.imagePath != null
                ? GestureDetector(
                    onTap: () => AppTheme.showZoomedImage(context, item.product.imagePath),
                    child: Image.file(
                      File(item.product.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.white),
                    ),
                  )
                : Container(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    child: const Icon(Icons.checkroom, color: AppTheme.primaryGold, size: 20),
                  ),
          ),
        ),
        title: Text(
          item.product.nama,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.lightGold),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Size ${item.ukuran}',
                style: const TextStyle(color: AppTheme.lightGold, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatter.format(item.product.hargaJual)} / Pcs',
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedTextColor),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.lightGold, size: 20),
              onPressed: () => state.updateCartItemQty(item, -1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                '${item.kuantitas}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.lightGold, size: 20),
              onPressed: () {
                final ok = state.updateCartItemQty(item, 1);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stok produk di katalog tidak mencukupi!'),
                      backgroundColor: AppTheme.roseRed,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Membuat panel perhitungan diskon, PPN, dan checkout.
  Widget _buildCalculatorSection(
    BuildContext context,
    AppState state,
    NumberFormat formatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          // Subtotal
          _buildCalcRow('Subtotal', formatter.format(state.cartSubtotal)),
          const SizedBox(height: 6),
          // PPN (11%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PPN (11%)', style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13)),
              Text(formatter.format(state.cartTaxAmount), style: const TextStyle(color: AppTheme.textColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          // Tombol Input Diskon Kustom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Diskon (%)', style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showDiscountDialog(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryGold),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${state.diskonPersen.toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '- ${formatter.format(state.cartDiscountAmount)}',
                style: const TextStyle(color: AppTheme.roseRed, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.bgColor),
          // Total Akhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL AKHIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGold)),
              Text(
                formatter.format(state.cartTotal),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.lightGold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tombol Proses Pembayaran / Checkout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaymentDrawer(context, state, formatter),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('PROSES CHECKOUT & BAYAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textColor, fontSize: 13)),
      ],
    );
  }

  // --- DRAWER/BOTTOM SHEET PEMBAYARAN GANDA ---

  /// Membuka lembar pilihan pembayaran Tunai vs Non-Tunai.
  void _showPaymentDrawer(BuildContext context, AppState state, NumberFormat formatter) {
    // Sinkronkan text controller jika nominal cash berubah
    _cashController.text = state.jumlahBayar > 0 ? state.jumlahBayar.toStringAsFixed(0) : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isTunai = state.metodePembayaran == 'Tunai';
            final isMerchantDetailsMissing = !isTunai &&
                (state.merchantPaymentType == 'QRIS'
                    ? state.merchantQrisPath == null
                    : state.merchantAccountNo.isEmpty);
            final isProofOk = !isTunai && !isMerchantDetailsMissing && state.buktiTransferPath != null;
            final isCashOk = isTunai && !state.isBayarKurang;
            final canCheckout = isCashOk || isProofOk;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'METODE PEMBAYARAN GANDA',
                          style: TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rangkuman Nominal Belanja
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Wajib Bayar:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            formatter.format(state.cartTotal),
                            style: const TextStyle(color: AppTheme.lightGold, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pilihan Tipe Pembayaran (Tunai vs QRIS)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                state.setMetodePembayaran('Tunai');
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isTunai ? AppTheme.primaryGold.withOpacity(0.2) : AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isTunai ? AppTheme.primaryGold : Colors.white10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.money, color: isTunai ? AppTheme.primaryGold : AppTheme.mutedTextColor),
                                  const SizedBox(width: 8),
                                  Text('TUNAI', style: TextStyle(fontWeight: FontWeight.bold, color: isTunai ? AppTheme.textColor : AppTheme.mutedTextColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                state.setMetodePembayaran('QRIS');
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isTunai ? AppTheme.primaryGold.withOpacity(0.2) : AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: !isTunai ? AppTheme.primaryGold : Colors.white10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner, color: !isTunai ? AppTheme.primaryGold : AppTheme.mutedTextColor),
                                  const SizedBox(width: 8),
                                  Text('QRIS / TRANSFER', style: TextStyle(fontWeight: FontWeight.bold, color: !isTunai ? AppTheme.textColor : AppTheme.mutedTextColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- LAYOUT KONDISIONAL METODE PEMBAYARAN ---
                    if (isTunai) ...[
                      // Input Nominal Tunai
                      TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.lightGold),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Uang Tunai Diterima',
                          prefixIcon: Icon(Icons.payments),
                          hintText: 'Masukkan jumlah uang tunai...',
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            final parsed = double.tryParse(val) ?? 0.0;
                            state.setJumlahBayar(parsed);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Tombol Pintas Pecahan Uang
                      const Text('Pecahan Pintas:', style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCashShortcutBtn('Uang Pas', state.cartTotal, state, setModalState),
                          _buildCashShortcutBtn('Rp 50.000', 50000.0, state, setModalState),
                          _buildCashShortcutBtn('Rp 100.000', 100000.0, state, setModalState),
                          _buildCashShortcutBtn('Rp 200.000', 200000.0, state, setModalState),
                          _buildCashShortcutBtn('Rp 500.000', 500000.0, state, setModalState),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Indikator Kembalian / Kekurangan Tunai
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.isBayarKurang ? 'Kekurangan Bayar:' : 'Uang Kembalian:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: state.isBayarKurang ? AppTheme.roseRed : AppTheme.emeraldGreen,
                              ),
                            ),
                            Text(
                              state.isBayarKurang
                                  ? formatter.format(state.cartTotal - state.jumlahBayar)
                                  : formatter.format(state.uangKembali),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: state.isBayarKurang ? AppTheme.roseRed : AppTheme.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Tampilan Rekening & Barcode Kustom QRIS
                      Center(
                        child: Column(
                          children: [
                            if (isMerchantDetailsMissing) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.roseRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.roseRed.withOpacity(0.3)),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppTheme.roseRed, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Silakan buat dulu / import QRIS Anda!',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.roseRed, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Pengaturan pembayaran non-tunai kosong. Silakan atur Rekening atau QRIS Anda di menu "Pengaturan Pembayaran".',
                                      style: TextStyle(fontSize: 11, color: AppTheme.mutedTextColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                            if (state.merchantPaymentType == 'QRIS') ...[
                              if (state.merchantQrisPath != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                                  ),
                                  child: GestureDetector(
                                    onTap: () => AppTheme.showZoomedImage(context, state.merchantQrisPath),
                                    child: Image.file(
                                      File(state.merchantQrisPath!),
                                      height: 180,
                                      width: 180,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const SizedBox(
                                          height: 100,
                                          child: Center(
                                            child: Icon(Icons.broken_image, color: AppTheme.roseRed, size: 40),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ] else ...[
                              if (state.merchantAccountNo.isNotEmpty) ...[
                                Text(
                                  'TRANSFER BANK',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.brightness == Brightness.dark
                                        ? AppTheme.primaryGold
                                        : AppTheme.darkGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.merchantBankName} - ${state.merchantAccountNo}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                                ),
                                Text(
                                  'a.n. ${state.merchantAccountOwner}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor),
                                ),
                              ],
                            ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Tombol Foto Bukti Transfer (image_picker)
                      const Text('Unggah Bukti Transfer (Wajib):', style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await state.ambilFotoBuktiTransfer();
                                setModalState(() {});
                                if (picked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Foto bukti transfer berhasil diambil!'),
                                      backgroundColor: AppTheme.emeraldGreen,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('AMBIL FOTO BUKTI'),
                            ),
                          ),
                          if (state.buktiTransferPath != null) ...[
                            const SizedBox(width: 12),
                            // Thumbnail Preview
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: GestureDetector(
                                    onTap: () => AppTheme.showZoomedImage(context, state.buktiTransferPath),
                                    child: Image.file(
                                      File(state.buktiTransferPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        state.setBuktiTransferPath(null);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.roseRed,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Tombol Konfirmasi Akhir (Checkout)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canCheckout
                            ? () async {
                                final trx = await state.checkout();
                                if (trx != null) {
                                  Navigator.pop(context); // Tutup lembar bayar
                                  _showCheckoutSuccessDialog(context, trx);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCheckout ? AppTheme.primaryGold : Colors.grey[800],
                        ),
                        child: const Text('KONFIRMASI DAN PROSES NOTA'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Membuat tombol pintasan nominal cash.
  Widget _buildCashShortcutBtn(
    String label,
    double value,
    AppState state,
    StateSetter setModalState,
  ) {
    return InkWell(
      onTap: () {
        setModalState(() {
          state.setJumlahBayar(value);
          _cashController.text = value.toStringAsFixed(0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: state.jumlahBayar == value ? AppTheme.primaryGold : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: state.jumlahBayar == value ? AppTheme.primaryGold : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: state.jumlahBayar == value ? Colors.black : AppTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --- CONFIRMATION & DIALOGS ---

  /// Pop-up dialog setelah berhasil memproses transaksi kasir.
  void _showCheckoutSuccessDialog(BuildContext context, dynamic transaction) {
    final state = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 28),
              SizedBox(width: 10),
              Text(
                'TRANSAKSI SUKSES',
                style: TextStyle(color: AppTheme.emeraldGreen, letterSpacing: 1.0, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nota pembayaran telah diterbitkan secara lokal.'),
              const SizedBox(height: 12),
              Text(
                'Nota ID: ${transaction.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.lightGold),
              ),
              Text(
                'Total Bayar: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transaction.total)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('TUTUP'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog sukses
                state.setTab(3); // Pindah ke tab riwayat transaksi
              },
              child: const Text('LIHAT RIWAYAT'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog input persentase diskon.
  void _showDiscountDialog(BuildContext context, AppState state) {
    _discountController.text = state.diskonPersen > 0 ? state.diskonPersen.toStringAsFixed(0) : '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('INPUT DISKON TRANSAKSI'),
          content: TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Persentase Diskon (%)',
              suffixText: '%',
              hintText: 'Masukkan nilai diskon...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            ElevatedButton(
              onPressed: () {
                final double disc = double.tryParse(_discountController.text) ?? 0.0;
                if (disc >= 0 && disc <= 100) {
                  state.setDiskonPersen(disc);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan nilai diskon yang valid (0-100)%!'),
                      backgroundColor: AppTheme.roseRed,
                    ),
                  );
                }
              },
              child: const Text('TERAPKAN'),
            ),
          ],
        );
      },
    );
  }


  // --- FLOATING CART BUTTON UNTUK SCREEN HP (MOBILE) ---

  Widget _buildMobileCartFloatingButton(
    BuildContext context,
    AppState state,
    NumberFormat formatter,
  ) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              AppTheme.primaryGold,
              AppTheme.lightGold,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Di mobile, tampilkan sliding sheet yang berisi daftar belanja dan kalkulator
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return FractionallySizedBox(
                    heightFactor: 0.85,
                    child: Consumer<AppState>(
                      builder: (context, mobileState, child) {
                        return _buildCartSidebar(context, mobileState, formatter);
                      },
                    ),
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.black, size: 26),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${state.cartItems.fold(0, (sum, i) => sum + i.kuantitas)} Pcs Koko Batik',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text(
                        'Geser ke atas untuk bayar',
                        style: TextStyle(color: Colors.black54, fontSize: 10.5, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    formatter.format(state.cartTotal),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
