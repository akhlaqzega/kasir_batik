import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../states/app_state.dart';
import '../models/transaction.dart';
import '../app_theme.dart';

/// Halaman Riwayat Transaksi & Struk Digital.
/// Menampilkan catatan penjualan kronologis. Mengetuk item akan memunculkan struk digital
/// dengan opsi pembatalan nota (restorasi stok otomatis), cetak PDF, dan bagikan ke WhatsApp.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

          // Saring transaksi berdasarkan kata kunci pencarian (ID Nota)
          final filteredTrx = state.transactions.where((t) {
            return t.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.metodePembayaran.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Input Pencarian
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Cari nota berdasarkan ID Transaksi...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                // Daftar Riwayat
                Expanded(
                  child: filteredTrx.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada riwayat transaksi.',
                            style: TextStyle(color: AppTheme.mutedTextColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTrx.length,
                          itemBuilder: (context, index) {
                            final trx = filteredTrx[index];
                            return _buildTransactionCard(context, trx, state, currencyFormatter);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CARD LIST TRANSAKSI ---

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel trx,
    AppState state,
    NumberFormat formatter,
  ) {
    final isBatal = trx.status == 'Dibatalkan';
    final totalItems = trx.items.fold(0, (sum, i) => sum + i.kuantitas);

    return Card(
      child: ListTile(
        onTap: () => _showDigitalReceiptDialog(context, trx, state, formatter),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isBatal ? AppTheme.roseRed.withOpacity(0.1) : AppTheme.emeraldGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isBatal ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: isBatal ? AppTheme.roseRed : AppTheme.emeraldGreen,
            size: 24,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              trx.id,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: isBatal ? TextDecoration.lineThrough : null,
              ),
            ),
            Text(
              formatter.format(trx.total),
              style: TextStyle(
                color: isBatal ? AppTheme.mutedTextColor : AppTheme.lightGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(trx.waktu),
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              '$totalItems Pcs  |  ${trx.metodePembayaran}',
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedTextColor),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedTextColor),
      ),
    );
  }

  // --- DIGITAL RECEIPT DIALOG ---

  /// Dialog Struk Digital ala kertas POS.
  void _showDigitalReceiptDialog(
    BuildContext context,
    TransactionModel trx,
    AppState state,
    NumberFormat formatter,
  ) {
    final isBatal = trx.status == 'Dibatalkan';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 380,
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desain Struk POS Kertas
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'KASIR KOKO AL-HIJRAH',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                        ),
                        const Text(
                          'Busana Muslim & Batik Koko Premium',
                          style: TextStyle(fontSize: 10, color: AppTheme.mutedTextColor, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Jl. Al-Hijrah Raya No. 99, Jakarta',
                          style: TextStyle(fontSize: 9, color: AppTheme.mutedTextColor),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '===================================',
                          style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info Nota
                  Text('Nota ID  : ${trx.id}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  Text('Waktu    : ${DateFormat('dd/MM/yyyy HH:mm').format(trx.waktu)}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  Text('Kasir    : Admin POS', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  Row(
                    children: [
                      const Text('Status   : ', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                      Text(
                        trx.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: isBatal ? AppTheme.roseRed : AppTheme.emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                  const Center(
                    child: Text(
                      '===================================',
                      style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Daftar Item Belanja
                  const Text('Rincian Belanja:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGold)),
                  const SizedBox(height: 8),
                  ...trx.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.nama,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '  Size ${item.ukuran}  x${item.kuantitas}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.mutedTextColor),
                              ),
                              Text(
                                formatter.format(item.totalHarga),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const Center(
                    child: Text(
                      '-----------------------------------',
                      style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                    ),
                  ),

                  // Perhitungan Biaya
                  _buildReceiptRow('Subtotal', formatter.format(trx.subtotal)),
                  if (trx.diskonPersen > 0)
                    _buildReceiptRow(
                      'Diskon (${trx.diskonPersen.toStringAsFixed(0)}%)',
                      '- ${formatter.format(trx.subtotal * (trx.diskonPersen / 100))}',
                      valueColor: AppTheme.roseRed,
                    ),
                  _buildReceiptRow('PPN (11%)', formatter.format((trx.subtotal - (trx.subtotal * (trx.diskonPersen / 100))) * (trx.ppnPersen / 100))),
                  const Center(
                    child: Text(
                      '-----------------------------------',
                      style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                    ),
                  ),
                  _buildReceiptRow('TOTAL AKHIR', formatter.format(trx.total), isBold: true, labelColor: AppTheme.primaryGold, valueColor: AppTheme.lightGold),
                  const Center(
                    child: Text(
                      '===================================',
                      style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                    ),
                  ),

                  // Info Pembayaran
                  _buildReceiptRow('Metode Bayar', trx.metodePembayaran),
                  _buildReceiptRow('Uang Diterima', formatter.format(trx.jumlahBayar)),
                  _buildReceiptRow('Kembalian', formatter.format(trx.uangKembali), valueColor: AppTheme.emeraldGreen),

                  // Bukti Transfer QRIS (Jika Ada)
                  if (trx.metodePembayaran == 'QRIS' && trx.imagePath != null) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Bukti Transfer Non-Tunai:',
                        style: TextStyle(fontSize: 10, color: AppTheme.mutedTextColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        width: 140,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          File(trx.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Gambar bukti\ntidak ditemukan',
                                style: TextStyle(color: AppTheme.roseRed, fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Terima kasih atas kunjungan Anda!',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.mutedTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
          actions: [
            // Tombol Batal Nota (Kiri)
            if (!isBatal)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.roseRed,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  _showConfirmCancelTrxDialog(context, state, trx.id);
                },
                child: const Text('BATAL NOTA', style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('DIBATALKAN', style: TextStyle(color: AppTheme.roseRed, fontWeight: FontWeight.bold, fontSize: 12)),
              ),

            // Opsi Berbagi & Cetak (Kanan)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blueAccent),
                  tooltip: 'Bagikan ke WhatsApp',
                  onPressed: () => _bagikanKeWhatsApp(context, trx, formatter),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryGold),
                  tooltip: 'Cetak / Simpan PDF',
                  onPressed: () => _generateReceiptPdf(trx, formatter),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('TUTUP', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: labelColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA AKSI STRUK: BATAL, WHATSAPP, PDF ---

  /// Dialog konfirmasi batal nota transaksi.
  void _showConfirmCancelTrxDialog(BuildContext context, AppState state, String trxId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('KONFIRMASI BATAL NOTA'),
          content: const Text(
            'Apakah Anda yakin ingin membatalkan transaksi ini? '
            'Status nota akan berubah menjadi "Dibatalkan" dan jumlah stok pakaian akan dikembalikan secara otomatis ke katalog.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('KEMBALI'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
              onPressed: () async {
                await state.batalNota(trxId);
                Navigator.pop(context); // Tutup dialog konfirmasi
                Navigator.pop(context); // Tutup struk digital
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nota berhasil dibatalkan. Stok baju dikembalikan!'),
                    backgroundColor: AppTheme.roseRed,
                  ),
                );
              },
              child: const Text('YA, BATALKAN NOTA', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Membuat susunan teks struk digital dalam bentuk Markdown,
  /// kemudian menyalinnya ke Clipboard agar siap ditempel di mana pun
  /// dan menyarankan pengiriman langsung ke WhatsApp.
  void _bagikanKeWhatsApp(
    BuildContext context,
    TransactionModel trx,
    NumberFormat formatter,
  ) {
    final discountVal = trx.subtotal * (trx.diskonPersen / 100);
    final ppnVal = (trx.subtotal - discountVal) * (trx.ppnPersen / 100);

    String text = '*KASIR KOKO AL-HIJRAH BATIK*\n';
    text += '_Busana Muslim & Batik Koko Premium_\n';
    text += '====================================\n';
    text += '*ID Transaksi:* ${trx.id}\n';
    text += '*Waktu:* ${DateFormat('dd/MM/yyyy HH:mm').format(trx.waktu)}\n';
    text += '*Status:* ${trx.status.toUpperCase()}\n';
    text += '====================================\n\n';
    text += '*RINCIAN BELANJA:*\n';

    for (var item in trx.items) {
      text += '- ${item.product.nama}\n';
      text += '  Ukuran: ${item.ukuran}  x${item.kuantitas}  @${formatter.format(item.product.hargaJual)}\n';
      text += '  Total: ${formatter.format(item.totalHarga)}\n';
    }
    text += '\n------------------------------------\n';
    text += '*Subtotal:* ${formatter.format(trx.subtotal)}\n';
    if (trx.diskonPersen > 0) {
      text += '*Diskon (${trx.diskonPersen.toStringAsFixed(0)}%):* -${formatter.format(discountVal)}\n';
    }
    text += '*PPN (11%):* ${formatter.format(ppnVal)}\n';
    text += '*TOTAL AKHIR: ${formatter.format(trx.total)}*\n';
    text += '------------------------------------\n';
    text += '*Metode Bayar:* ${trx.metodePembayaran}\n';
    text += '*Uang Masuk:* ${formatter.format(trx.jumlahBayar)}\n';
    text += '*Kembalian:* ${formatter.format(trx.uangKembali)}\n';
    text += '====================================\n';
    text += '_Terima kasih atas kepercayaan Anda membeli Koko Batik Al-Hijrah!_';

    // 1. Salin ke clipboard
    Clipboard.setData(ClipboardData(text: text));

    // 2. Tampilkan SnackBar info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Teks Struk Markdown disalin ke Clipboard!'),
        backgroundColor: AppTheme.emeraldGreen,
        action: SnackBarAction(
          label: 'WhatsApp',
          textColor: Colors.black,
          onPressed: () {
            // Arahkan ke link WhatsApp Web/App sharing API
            final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
            // Sebagaimana standar, jika package url_launcher tidak wajib dipakai,
            // Clipboard menyalin teks adalah cara terbaik dan teraman. Namun mari kita coba
            // berikan aksi penyalinan link WhatsApp agar pengguna tahu.
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link WhatsApp disalin. Buka browser atau WhatsApp untuk share!'),
                backgroundColor: AppTheme.primaryGold,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Membuat file PDF struk belanja 58mm menggunakan library `pdf` & `printing`.
  Future<void> _generateReceiptPdf(TransactionModel trx, NumberFormat formatter) async {
    final doc = pw.Document();
    final discountVal = trx.subtotal * (trx.diskonPersen / 100);
    final ppnVal = (trx.subtotal - discountVal) * (trx.ppnPersen / 100);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'AL-HIJRAH BATIK',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Text(
                        'Kasir Koko Premium',
                        style: const pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
                      ),
                      pw.Text(
                        'Jl. Al-Hijrah Raya No. 99, Jakarta',
                        style: const pw.TextStyle(fontSize: 5),
                      ),
                      pw.Text(
                        '----------------------------------',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // Detail transaksi
                pw.Text('Nota: ${trx.id}', style: const pw.TextStyle(fontSize: 6)),
                pw.Text('Waktu: ${DateFormat('dd/MM/yyyy HH:mm').format(trx.waktu)}', style: const pw.TextStyle(fontSize: 6)),
                pw.Text(
                  'Status: ${trx.status.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '----------------------------------',
                  style: const pw.TextStyle(fontSize: 6),
                ),
                pw.SizedBox(height: 4),

                // Item Belanja
                pw.Text('Detail Belanja:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
                pw.SizedBox(height: 2),
                ...trx.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.product.nama, style: const pw.TextStyle(fontSize: 6)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(' Size ${item.ukuran} x${item.kuantitas}', style: const pw.TextStyle(fontSize: 5)),
                            pw.Text(formatter.format(item.totalHarga), style: const pw.TextStyle(fontSize: 5)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                pw.Text(
                  '----------------------------------',
                  style: const pw.TextStyle(fontSize: 6),
                ),

                // Kalkulasi Finansial
                _buildPdfRow('Subtotal', formatter.format(trx.subtotal)),
                if (trx.diskonPersen > 0)
                  _buildPdfRow('Diskon (${trx.diskonPersen.toStringAsFixed(0)}%)', '-${formatter.format(discountVal)}'),
                _buildPdfRow('PPN (11%)', formatter.format(ppnVal)),
                pw.Text(
                  '----------------------------------',
                  style: const pw.TextStyle(fontSize: 6),
                ),
                _buildPdfRow('TOTAL AKHIR', formatter.format(trx.total), isBold: true),
                pw.Text(
                  '==================================',
                  style: const pw.TextStyle(fontSize: 6),
                ),

                // Info Pembayaran
                _buildPdfRow('Metode Bayar', trx.metodePembayaran),
                _buildPdfRow('Diterima', formatter.format(trx.jumlahBayar)),
                _buildPdfRow('Kembalian', formatter.format(trx.uangKembali)),
                pw.SizedBox(height: 8),

                pw.Center(
                  child: pw.Text(
                    'Terima Kasih Atas Pembelian Anda',
                    style: const pw.TextStyle(fontSize: 5, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Memicu dialog cetak PDF sistem
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Struk_${trx.id}',
    );
  }

  pw.Widget _buildPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 5.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 5.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
