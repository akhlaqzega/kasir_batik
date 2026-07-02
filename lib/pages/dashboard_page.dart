import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../states/app_state.dart';
import '../models/transaction.dart';
import '../app_theme.dart';

/// Halaman Dasbor Analitik & Grafik Keuangan.
/// Menampilkan ringkasan KPI (Omset, Modal, Laba), grafik tren penjualan harian (Line Chart),
/// dan distribusi ukuran pakaian terjual (Pie Chart) secara dinamis menggunakan package fl_chart.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            );
          }

          // 1. Kalkulasi Data KPI (Abaikan transaksi berstatus 'Dibatalkan')
          double totalOmset = 0.0;
          double totalModal = 0.0;
          final activeTransactions = state.transactions
              .where((t) => t.status != 'Dibatalkan')
              .toList();

          for (var trx in activeTransactions) {
            totalOmset += trx.total;
            for (var item in trx.items) {
              totalModal += item.totalModal;
            }
          }
          double labaBersih = totalOmset - totalModal;

          // 2. Siapkan Data Grafik Tren 7 Hari Terakhir
          final dailyTrendSpots = _generateDailyTrendSpots(activeTransactions);

          // 3. Siapkan Data Distribusi Ukuran Baju
          final sizeDistribution = _calculateSizeDistribution(activeTransactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salam Pembuka & Nama Toko
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang, Admin!',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kasir Koko Al-Hijrah Batik',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppTheme.primaryGold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ringkasan KPI Finansial
                _buildKpiSection(context, currencyFormatter, totalOmset, totalModal, labaBersih),
                const SizedBox(height: 24),

                // Baris Grafik
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isLarge = constraints.maxWidth >= 900;
                    if (isLarge) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildLineChartCard(dailyTrendSpots, currencyFormatter),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildPieChartCard(sizeDistribution),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildLineChartCard(dailyTrendSpots, currencyFormatter),
                          const SizedBox(height: 16),
                          _buildPieChartCard(sizeDistribution),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDER ---

  /// Membuat panel kartu KPI finansial dengan warna gradasi premium.
  Widget _buildKpiSection(
    BuildContext context,
    NumberFormat formatter,
    double omset,
    double modal,
    double laba,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final isLarge = constraints.maxWidth >= 600;
      final spacing = isLarge ? 12.0 : 8.0;

      return GridView.count(
        crossAxisCount: isLarge ? 3 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: isLarge ? 1.6 : 3.0,
        children: [
          // Omset (Hijau Zamrud)
          _buildKpiCard(
            context: context,
            title: 'TOTAL OMSET',
            value: formatter.format(omset),
            icon: Icons.payments_outlined,
            gradientColors: isDark
                ? [
                    const Color(0xFF064E3B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFD1FAE5),
                    const Color(0xFFA7F3D0),
                  ],
            accentColor: AppTheme.emeraldGreen,
          ),
          // Modal Terpakai
          _buildKpiCard(
            context: context,
            title: 'MODAL TERPAKAI',
            value: formatter.format(modal),
            icon: Icons.shopping_bag_outlined,
            gradientColors: isDark
                ? [
                    const Color(0xFF334155),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ],
            accentColor: isDark ? AppTheme.lightGold : AppTheme.darkGold,
          ),
          // Laba Bersih
          _buildKpiCard(
            context: context,
            title: 'LABA BERSIH RIIL',
            value: formatter.format(laba),
            icon: Icons.account_balance_wallet_outlined,
            gradientColors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFFFEF3C7),
                    const Color(0xFFFDE68A),
                  ],
            accentColor: isDark ? AppTheme.primaryGold : AppTheme.darkGold,
            borderColor: isDark ? AppTheme.primaryGold : AppTheme.darkGold,
          ),
        ],
      );
    });
  }

  /// Membuat item kartu KPI tunggal dengan ikon dan desain elegan.
  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor ?? accentColor.withOpacity(0.2),
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppTheme.mutedTextColor : const Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isDark ? AppTheme.textColor : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat visual grafik tren harian menggunakan fl_chart.
  Widget _buildLineChartCard(List<FlSpot> spots, NumberFormat formatter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Tren Pendapatan Harian (7 Hari Terakhir)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
                Icon(
                  Icons.trending_up,
                  color: AppTheme.emeraldGreen.withOpacity(0.8),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: spots.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada data transaksi',
                        style: TextStyle(color: AppTheme.mutedTextColor),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();
                                // Persingkat nominal besar (e.g. 500k)
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    color: AppTheme.mutedTextColor,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final now = DateTime.now();
                                final date = now.subtract(Duration(days: 6 - value.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('dd/MM').format(date),
                                    style: const TextStyle(
                                      color: AppTheme.mutedTextColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                              interval: 1,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.mutedTextColor.withOpacity(0.2)),
                            left: BorderSide(color: AppTheme.mutedTextColor.withOpacity(0.2)),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primaryGold,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.lightGold,
                                strokeWidth: 1,
                                strokeColor: AppTheme.bgColor,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryGold.withOpacity(0.12),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (spot) => AppTheme.surfaceColor,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  formatter.format(spot.y),
                                  const TextStyle(
                                    color: AppTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuat visual grafik lingkaran (Pie Chart) untuk ukuran pakaian terpopuler.
  Widget _buildPieChartCard(Map<String, int> distribution) {
    final colors = {
      'M': const Color(0xFF60A5FA),  // Biru
      'L': const Color(0xFF34D399),  // Hijau
      'XL': const Color(0xFFFBBF24), // Emas
      'XXL': const Color(0xFFF87171),// Merah Mawar
    };

    final totalSold = distribution.values.fold(0, (sum, val) => sum + val);

    final sections = distribution.entries.map((e) {
      final size = e.key;
      final count = e.value;
      final percentage = totalSold == 0 ? 0.0 : (count / totalSold) * 100;

      return PieChartSectionData(
        color: colors[size] ?? Colors.grey,
        value: count.toDouble(),
        title: count > 0 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribusi Ukuran Baju Terjual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            if (totalSold == 0)
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'Belum ada transaksi baju terjual',
                    style: TextStyle(color: AppTheme.mutedTextColor),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: distribution.keys.map((size) {
                      final count = distribution[size] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[size],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Size $size ($count Pcs)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA BANTU DATA GRAPH ---

  /// Membuat data koordinat FlSpot untuk grafik LineChart.
  /// Memetakan pendapatan selama 7 hari terakhir secara urut kronologis.
  List<FlSpot> _generateDailyTrendSpots(List<TransactionModel> activeTransactions) {
    final now = DateTime.now();
    final Map<int, double> dailyTotals = {};

    // Inisialisasi 7 hari terakhir dengan nominal 0.0
    for (int i = 0; i < 7; i++) {
      dailyTotals[i] = 0.0;
    }

    for (var trx in activeTransactions) {
      final daysAgo = now.difference(trx.waktu).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        // Indeks untuk fl_chart, hari terlama (6 hari lalu) berada di koordinat x=0, hari ini x=6
        final xIndex = 6 - daysAgo;
        dailyTotals[xIndex] = (dailyTotals[xIndex] ?? 0) + trx.total;
      }
    }

    return dailyTotals.entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();
  }

  /// Menghitung total kuantitas pakaian terjual berdasarkan ukuran (M, L, XL, XXL).
  Map<String, int> _calculateSizeDistribution(List<TransactionModel> activeTransactions) {
    final Map<String, int> dist = {'M': 0, 'L': 0, 'XL': 0, 'XXL': 0};
    for (var trx in activeTransactions) {
      for (var item in trx.items) {
        final size = item.ukuran;
        if (dist.containsKey(size)) {
          dist[size] = dist[size]! + item.kuantitas;
        }
      }
    }
    return dist;
  }
}
