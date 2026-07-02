# Kasir Koko Al-Hijrah Batik 👕💼

Aplikasi Kasir (Point of Sale / POS) berbasis Flutter yang dirancang khusus untuk membantu merchant batik dalam mencatat penjualan, mengelola katalog produk, memantau stok ukuran secara real-time, serta melihat statistik pendapatan secara praktis dan modern.

Aplikasi ini sudah terintegrasi dengan **Firebase (Auth & Firestore)** untuk sinkronisasi data cloud secara aman per masing-masing pengguna.

---

## 🌟 Fitur Utama

1. **Autentikasi Pengguna**:
   - Pendaftaran & Login menggunakan Email & Password.
   - Login instan satu ketukan menggunakan **Google Sign-In**.
   
2. **Sistem Point of Sale (POS)**:
   - Pencarian produk dan penyaringan berdasarkan kategori produk.
   - Keranjang belanja dinamis dengan pemilihan ukuran pakaian (M, L, XL, XXL) yang didesain secara adaptif dengan **High Contrast** di Light/Dark Mode.
   - Validasi stok otomatis secara real-time untuk mencegah pembelian melebihi kapasitas stok.
   - Kalkulasi otomatis: Subtotal, diskon (persentase), Pajak PPN (11%), total tagihan, dan nominal kembalian.
   - Thumbnail gambar produk yang tampil rapi langsung di dalam list item keranjang belanja.

3. **Metode Pembayaran Non-Tunai Kustom (QRIS / Rekening Bank)**:
   - **Tunai**: Input jumlah uang bayar dengan kalkulator kembalian instan.
   - **Non-Tunai**: Pilihan dinamis antara menggunakan **QRIS (Gambar)** atau **Transfer Bank (Teks)** yang dikonfigurasi melalui menu Pengaturan Pembayaran.
   - Uploader Bukti Transfer: Terintegrasi dengan kamera perangkat (`image_picker`) untuk memotret bukti transfer sebagai syarat sah checkout.
   - Banner peringatan merah terang **"Silakan buat dulu / import QRIS Anda!"** (atau pesan rekening kosong) jika metode non-tunai belum dikonfigurasi oleh admin baru.

4. **Fitur Pinch-to-Zoom Gambar**:
   - Fitur dialog fullscreen zoom yang interaktif (`InteractiveViewer`) pada:
     - Foto produk pada katalog utama POS.
     - Gambar produk kecil pada list item keranjang belanja.
     - Barcode QRIS toko saat proses pembayaran.
     - Gambar foto bukti transfer yang diunggah oleh kasir.

5. **Manajemen Katalog Produk (CRUD) & SKU Otomatis**:
   - Tambah produk baru dengan detail nama, kategori, harga beli, harga jual, serta alokasi stok per ukuran.
   - **SKU Otomatis**: Bidang SKU disembunyikan dari form uploader produk dan digenerate secara otomatis oleh sistem di latar belakang menggunakan prefix standar Indonesia `899`.
   - Edit detail produk atau hapus produk dari katalog.
   - Data tersimpan dan tersinkronisasi di Firestore secara personal.

6. **Riwayat Penjualan, Void, & Redirect Navigasi**:
   - Melacak riwayat semua nota penjualan lengkap dengan detail item dan waktu transaksi.
   - Fitur **Batal Nota (Void)** yang secara otomatis mengembalikan stok barang yang terjual kembali ke katalog produk.
   - **Redirect Transaksi**: Sesaat setelah kasir menekan tombol **"LIHAT RIWAYAT"** di dialog sukses transaksi, navigasi tab langsung otomatis diarahkan ke halaman Riwayat Transaksi.

7. **Analisis & Grafik Keuangan**:
   - Ringkasan performa penjualan (Pendapatan Kotor, Laba Bersih, Produk Terlaris, Jumlah Transaksi).
   - Grafik penjualan mingguan yang interaktif didukung oleh package `fl_chart`.

8. **Cetak Struk PDF**:
   - Pembuatan invoice digital berformat PDF secara dinamis.
   - Integrasi cetak struk ke printer thermal/perangkat printer lainnya (`printing` & `pdf` packages).

9. **Tema Gelap & Terang (Dark/Light Mode)**:
   - Transisi tema yang mulus untuk kenyamanan mata pengguna dalam berbagai kondisi cahaya.
   - Menyimpan preferensi tema pengguna menggunakan penyimpanan lokal.

---

## 🛠️ Tech Stack & Packages

- **Core Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.12.0`)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database & Cloud**: 
  - [Firebase Core](https://pub.dev/packages/firebase_core)
  - [Firebase Auth](https://pub.dev/packages/firebase_auth) (Google & Email Auth)
  - [Cloud Firestore](https://pub.dev/packages/cloud_firestore)
  - [Google Sign In](https://pub.dev/packages/google_sign_in)
- **Penyimpanan Lokal (Cache)**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Desain & Grafik**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Media & Kamera**: [Image Picker](https://pub.dev/packages/image_picker) (mengambil foto bukti pembayaran)
- **Dokumen & Printer**: [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing)

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── models/             # Representasi data (Product, CartItem, TransactionModel)
├── pages/              # Antarmuka Pengguna (UI)
├── │   ├── dashboard_page.dart       # Grafik & statistik penjualan
├── │   ├── history_page.dart         # Riwayat nota & opsi Void
├── │   ├── login_page.dart           # Form masuk Firebase & Google Auth
├── │   ├── pos_page.dart             # Halaman kasir utama & keranjang belanja
├── │   ├── product_crud_page.dart    # Pengelolaan katalog produk & stok
├── │   └── main_shell.dart           # Kerangka navigasi (bottom bar)
├── services/           # Logika Firebase & Local Storage
├── │   ├── auth_service.dart         # Layanan Login/Register/Google Sign-in
├── │   ├── firestore_service.dart    # CRUD database cloud Firestore
├── │   └── storage_service.dart      # Fallback database lokal shared_preferences
├── states/             # Manajemen state aplikasi
├── │   └── app_state.dart            # Pengatur logika keranjang, transaksi, & tema
├── app_theme.dart      # Pengaturan skema warna Light & Dark Mode
├── firebase_options.dart # Konfigurasi platform Firebase
└── main.dart           # Titik masuk utama (Main entry point)
```

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat (Prerequisites)
Sebelum memulai, pastikan perangkat Anda telah terinstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi minimal 3.12.0)
- [Dart SDK](https://dart.dev/get-started)
- IDE seperti [VS Code](https://code.visualstudio.com/) atau [Android Studio](https://developer.android.com/studio)
- Git terinstal pada sistem Anda.

### 2. Kloning Repositori
Clone proyek ini ke penyimpanan lokal Anda:
```bash
git clone https://github.com/akhlaqzega/kasir_batik.git
cd kasir_batik
```

### 3. Mengunduh Dependencies
Jalankan perintah berikut di direktori proyek untuk mengambil semua package pendukung:
```bash
flutter pub get
```

### 4. Konfigurasi Firebase (Opsional / Jika ingin menggunakan Firebase sendiri)
Proyek ini dikonfigurasi menggunakan Firebase. Jika ingin menghubungkannya ke Firebase Console pribadi Anda:
1. Buat proyek baru di [Firebase Console](https://console.firebase.google.com/).
2. Aktifkan **Authentication** (Metode masuk: Email/Password dan Google).
3. Aktifkan **Cloud Firestore Database** dalam mode uji coba (test mode).
4. Instal [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) lalu jalankan:
   ```bash
   flutterfire configure
   ```
5. Ikuti petunjuk untuk menautkan aplikasi Android/iOS Anda. File `firebase_options.dart` baru akan otomatis dihasilkan di folder `lib/`.

### 5. Menjalankan Aplikasi
Hubungkan emulator Android/iOS atau sambungkan ponsel fisik dengan mode debugging aktif. Cek kesiapan perangkat:
```bash
flutter devices
```
Jalankan aplikasi dengan perintah:
```bash
flutter run
```

---

## 👤 Kontributor
- **Akhlaq Siddiq Zega** - [@akhlaqzega](https://github.com/akhlaqzega)
