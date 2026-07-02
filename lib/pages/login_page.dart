import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';

/// Halaman Login & Registrasi dengan tema gelap premium.
/// Mendukung login via Email & Password serta Google Sign-In.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Eksekusi proses autentikasi (Login/Register) dengan Email
  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isRegisterMode) {
        // Mode Registrasi
        await _authService.signUpWithEmail(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil! Akun Anda telah siap.'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      } else {
        // Mode Login
        await _authService.signInWithEmail(email, password);
      }
    } catch (e) {
      if (mounted) {
        String errMsg = 'Terjadi kesalahan autentikasi.';
        final errString = e.toString().toLowerCase();
        
        if (errString.contains('user-not-found') || errString.contains('invalid-credential')) {
          errMsg = 'Email atau kata sandi salah.';
        } else if (errString.contains('email-already-in-use')) {
          errMsg = 'Email sudah terdaftar. Silakan login.';
        } else if (errString.contains('weak-password')) {
          errMsg = 'Kata sandi terlalu lemah (minimal 6 karakter).';
        } else if (errString.contains('network-request-failed')) {
          errMsg = 'Koneksi internet bermasalah.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppTheme.roseRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Eksekusi Login menggunakan Google Sign-In
  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null && mounted) {
        // Pengguna membatalkan login
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In gagal: ${e.toString()}'),
            backgroundColor: AppTheme.roseRed,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goldColor = isDark ? AppTheme.primaryGold : AppTheme.darkGold;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: isDark ? AppTheme.surfaceColor : Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: goldColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Bulat Premium
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: goldColor, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Judul Branding
                      Text(
                        'AL-HIJRAH BATIK',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        _isRegisterMode ? 'Buat Akun Kasir Baru' : 'Sistem POS Kasir Premium',
                        style: TextStyle(
                          color: isDark ? AppTheme.mutedTextColor : Colors.grey.shade600,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Input Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'nama@domain.com',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Email wajib diisi';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                          if (val.length < 6) return 'Kata sandi minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input Konfirmasi Password (Khusus Register)
                      if (_isRegisterMode) ...[
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Konfirmasi kata sandi wajib';
                            if (val != _passwordController.text) {
                              return 'Kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // Tombol Submit Utama
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(color: goldColor),
                              )
                            : ElevatedButton(
                                onPressed: _handleEmailAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: goldColor,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isRegisterMode ? 'DAFTAR SEKARANG' : 'MASUK KASIR',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle Register / Login Mode
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          _isRegisterMode
                              ? 'Sudah punya akun? Masuk di sini'
                              : 'Belum punya akun? Daftar di sini',
                          style: TextStyle(
                            color: goldColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pembatas "Atau"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'ATAU',
                              style: TextStyle(
                                color: isDark ? Colors.white30 : Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tombol Google Sign-In Premium
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleAuth,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Icon
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                height: 18,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback jika tidak ada internet
                                  return const Icon(Icons.g_mobiledata, size: 24);
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Masuk dengan Google',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
