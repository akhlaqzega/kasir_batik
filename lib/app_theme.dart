import 'dart:io';
import 'package:flutter/material.dart';

/// Konfigurasi tema gelap mewah (Dark Premium Theme) untuk aplikasi
/// "Kasir Koko Al-Hijrah Batik" dengan dominasi warna Slate Navy dan Brushed Gold.
class AppTheme {
  // Latar belakang gelap Slate Navy
  static const Color bgColor = Color(0xFF020617);
  static const Color surfaceColor = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);

  // Emas sapuan (Brushed Gold) untuk elemen aktif dan border mewah
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFE2B659);
  static const Color darkGold = Color(0xFFAA8010);

  // Status Finansial
  static const Color emeraldGreen = Color(0xFF10B981); // Positif / Sukses / Omset
  static const Color roseRed = Color(0xFFF43F5E); // Peringatan / Kekurangan Uang / Batal

  // Teks
  static const Color textColor = Color(0xFFF8FAFC);
  static const Color mutedTextColor = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: darkGold, // warna emas gelap agar terbaca jelas
        secondary: primaryGold,
        surface: Colors.white,
        error: roseRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: darkGold),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: darkGold.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: darkGold,
            width: 1.5,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGold.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: roseRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIconColor: darkGold,
        suffixIconColor: darkGold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          shadowColor: primaryGold.withOpacity(0.4),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkGold,
          side: const BorderSide(color: darkGold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 22),
        titleLarge: TextStyle(color: darkGold, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 15),
        bodyMedium: TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: lightGold,
        surface: surfaceColor,
        error: roseRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: lightGold),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryGold.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: primaryGold,
            width: 1.5,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGold.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: roseRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: mutedTextColor),
        hintStyle: const TextStyle(color: mutedTextColor),
        prefixIconColor: lightGold,
        suffixIconColor: lightGold,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryGold,
        unselectedItemColor: mutedTextColor,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 10,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: IconThemeData(color: primaryGold, size: 30),
        unselectedIconTheme: IconThemeData(color: mutedTextColor, size: 24),
        selectedLabelTextStyle: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: mutedTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          shadowColor: primaryGold.withOpacity(0.4),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 28),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22),
        titleLarge: TextStyle(color: lightGold, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textColor, fontSize: 15),
        bodyMedium: TextStyle(color: mutedTextColor, fontSize: 13),
      ),
    );
  }

  /// Membuka dialog fullscreen untuk memperbesar gambar (zoom) produk atau QRIS.
  static void showZoomedImage(BuildContext context, String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imagePath.startsWith('assets/')
                      ? Image.asset(imagePath, fit: BoxFit.contain)
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
