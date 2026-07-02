import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../states/app_state.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'pos_page.dart';
import 'product_crud_page.dart';
import 'history_page.dart';

/// Cangkang navigasi responsif (Responsive Navigation Shell).
/// Menampilkan Sidebar untuk layar lebar (Tablet/Desktop) dan Navigation Drawer
/// di pojok kiri atas untuk layar HP (Mobile). Menggunakan IndexedStack untuk menjaga status data.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Daftar judul halaman sesuai tab
  final List<String> _titles = const [
    'DASBOR ANALITIK',
    'KANVAS POS KASIR',
    'KELOLA KATALOG & STOK',
    'RIWAYAT TRANSAKSI',
  ];

  // Daftar halaman anak
  final List<Widget> _pages = const [
    DashboardPage(),
    PosPage(),
    ProductCrudPage(),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Gunakan LayoutBuilder untuk deteksi ukuran layar secara dinamis
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 800;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: TextStyle(
                color: theme.colorScheme.brightness == Brightness.dark
                    ? AppTheme.lightGold
                    : AppTheme.darkGold,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            elevation: 0,
            centerTitle: true,
            leading: isLargeScreen
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            actions: [
              // Tombol Toggle Tema Ganda
              IconButton(
                icon: Icon(
                  state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: state.isDarkMode ? AppTheme.primaryGold : AppTheme.darkGold,
                ),
                tooltip: state.isDarkMode ? 'Ubah ke Mode Terang' : 'Ubah ke Mode Gelap',
                onPressed: () => state.toggleTheme(),
              ),
              // Tombol Aksi POS Kasir jika halaman POS aktif
              if (_selectedIndex == 1)
                IconButton(
                  icon: const Icon(Icons.cleaning_services_outlined, color: AppTheme.roseRed),
                  tooltip: 'Bersihkan Keranjang',
                  onPressed: () {
                    if (state.cartItems.isNotEmpty) {
                      _showConfirmClearCartDialog(context, state);
                    }
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: isLargeScreen ? null : _buildDrawer(context, state),
          body: isLargeScreen
              ? Row(
                  children: [
                    // Sidebar Kustom untuk Layar Lebar
                    _buildSidebar(context, state),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.colorScheme.brightness == Brightness.dark
                          ? AppTheme.primaryGold.withOpacity(0.3)
                          : AppTheme.darkGold.withOpacity(0.2),
                    ),
                    // Konten Utama
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
        );
      },
    );
  }

  /// Membuat widget Navigation Drawer untuk tampilan HP (Mobile).
  Widget _buildDrawer(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final goldColor = theme.colorScheme.brightness == Brightness.dark
        ? AppTheme.primaryGold
        : AppTheme.darkGold;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header Drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: goldColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor, width: 1.5),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AL-HIJRAH',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'BATIK',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kasir Premium',
                        style: TextStyle(
                          color: theme.colorScheme.brightness == Brightness.dark
                              ? AppTheme.mutedTextColor
                              : Colors.grey.shade600,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Daftar Menu Navigasi
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerMenuItem(
                  context: context,
                  index: 0,
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  title: 'Dasbor Analitik',
                ),
                _buildDrawerMenuItem(
                  context: context,
                  index: 1,
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  title: 'Kasir POS (Kanvas)',
                ),
                _buildDrawerMenuItem(
                  context: context,
                  index: 2,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  title: 'Kelola Produk',
                ),
                _buildDrawerMenuItem(
                  context: context,
                  index: 3,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  title: 'Riwayat Transaksi',
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.roseRed),
                  title: const Text(
                    'Keluar Akun',
                    style: TextStyle(color: AppTheme.roseRed, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer
                    _showConfirmLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0 Premium',
              style: TextStyle(
                color: theme.colorScheme.brightness == Brightness.dark
                    ? AppTheme.mutedTextColor
                    : Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat item menu untuk Navigation Drawer.
  Widget _buildDrawerMenuItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }) {
    final isActive = _selectedIndex == index;
    final theme = Theme.of(context);
    final goldColor = theme.colorScheme.brightness == Brightness.dark
        ? AppTheme.primaryGold
        : AppTheme.darkGold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Tutup drawer setelah memilih
        },
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? goldColor : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? goldColor : theme.textTheme.bodyLarge?.color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: isActive,
        selectedTileColor: goldColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Membuat widget Sidebar premium untuk tampilan Desktop/Tablet.
  Widget _buildSidebar(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final goldColor = theme.colorScheme.brightness == Brightness.dark
        ? AppTheme.primaryGold
        : AppTheme.darkGold;

    return Container(
      width: 250,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header Logo & Branding
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor, width: 2),
                    color: theme.scaffoldBackgroundColor,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AL-HIJRAH BATIK',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Kasir Koko Premium',
                  style: TextStyle(
                    color: theme.colorScheme.brightness == Brightness.dark
                        ? AppTheme.mutedTextColor
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Divider(
            color: theme.scaffoldBackgroundColor,
            thickness: 2,
          ),
          const SizedBox(height: 10),
          // Daftar Menu Navigasi
          Expanded(
            child: ListView(
              children: [
                _buildSidebarMenuItem(
                  context: context,
                  index: 0,
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  title: 'Dasbor Analitik',
                ),
                _buildSidebarMenuItem(
                  context: context,
                  index: 1,
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  title: 'Kasir POS (Kanvas)',
                ),
                _buildSidebarMenuItem(
                  context: context,
                  index: 2,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  title: 'Kelola Produk',
                ),
                _buildSidebarMenuItem(
                  context: context,
                  index: 3,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  title: 'Riwayat Transaksi',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.roseRed),
            title: const Text(
              'Keluar Akun',
              style: TextStyle(color: AppTheme.roseRed, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showConfirmLogoutDialog(context),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0 Premium',
              style: TextStyle(
                color: theme.colorScheme.brightness == Brightness.dark
                    ? AppTheme.mutedTextColor
                    : Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membantu pembuatan item menu Sidebar dengan status aktif yang indah.
  Widget _buildSidebarMenuItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }) {
    final isActive = _selectedIndex == index;
    final theme = Theme.of(context);
    final goldColor = theme.colorScheme.brightness == Brightness.dark
        ? AppTheme.primaryGold
        : AppTheme.darkGold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isActive ? goldColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: goldColor.withOpacity(0.4), width: 1)
                : null,
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? goldColor : Colors.grey,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isActive ? theme.textTheme.titleLarge?.color : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog konfirmasi untuk membersihkan keranjang belanja.
  void _showConfirmClearCartDialog(BuildContext context, AppState state) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bersihkan Keranjang?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus seluruh item di dalam keranjang belanja?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: theme.colorScheme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                state.clearCart();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keranjang belanja berhasil dikosongkan.'),
                    backgroundColor: AppTheme.roseRed,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.roseRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Bersihkan'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog konfirmasi sebelum melakukan logout akun
  void _showConfirmLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar dari Akun?'),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Anda harus masuk kembali untuk mengelola kasir dan melakukan sinkronisasi data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: theme.colorScheme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await AuthService().signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal keluar akun: $e'),
                        backgroundColor: AppTheme.roseRed,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.roseRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}
