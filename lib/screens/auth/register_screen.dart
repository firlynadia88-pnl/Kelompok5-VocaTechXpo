import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';

import '../../utils/constants.dart';
import '../../widgets/starry_sky.dart';
import '../organizer/booth_onboarding_screen.dart';
// ==================== 3. REGISTER SCREEN ====================
class RegisterScreen extends StatefulWidget {
  final bool isOrganizer;
  const RegisterScreen({super.key, this.isOrganizer = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;
  late AnimationController _starController;
  late AnimationController _shimmerController;
  late final List<Star> _stars;

  final List<String> _jurusanList = [
    'Teknik Elektro',
    'Teknik Mesin',
    'Teknik Kimia',
    'Teknik Sipil',
    'Bisnis',
    'Teknologi Informasi dan Komputer',
  ];
  final List<String> _angkatanList = ['2024', '2023', '2022', '2021', '2020'];
  String? _selectedJurusan;
  String? _selectedAngkatan = '2024';
  String? _selectedProdi;
  String? _selectedUkm;

  final Map<String, List<String>> _prodiMap = {
    'Teknologi Informasi dan Komputer': [
      'Teknik Informatika',
      'Teknologi Rekayasa Komputer Jaringan (TRKJ)',
      'Teknologi Rekayasa Multimedia',
      'Teknologi Rekayasa Perangkat Lunak',
      'Teknik Multimedia dan Jaringan',
    ],
    'Teknik Elektro': [
      'Teknologi Elektronika',
      'Teknologi Listrik',
      'Teknologi Telekomunikasi',
      'Teknologi Rekayasa Jaringan Telekomunikasi',
      'Teknologi Rekayasa Instrumentasi dan Kontrol',
      'Teknologi Rekayasa Pembangkit Energi',
      'Teknologi Rekayasa Mekatronika',
    ],
    'Teknik Mesin': [
      'Teknologi Mesin',
      'Teknologi Industri',
      'Teknologi Rekayasa Manufaktur',
      'Teknologi Rekayasa Pengelasan dan Fabrikasi',
    ],
    'Teknik Kimia': [
      'Teknologi Kimia',
      'Teknologi Pengolahan Minyak dan Gas',
      'Teknologi Rekayasa Kimia Industri',
      'Teknologi Rekayasa Kimia Berkelanjutan',
    ],
    'Teknik Sipil': [
      'Teknologi Konstruksi Bangunan Air',
      'Teknologi Konstruksi Bangunan Gedung',
      'Teknologi Konstruksi Jalan dan Jembatan',
      'Teknologi Rekayasa Konstruksi Bangunan Gedung',
      'Teknologi Rekayasa Konstruksi Jalan dan Jembatan',
      'Rekayasa Transportasi',
    ],
    'Bisnis': [
      'Administrasi Bisnis',
      'Akuntansi',
      'Perbankan dan Keuangan',
      'Akuntansi Lembaga Keuangan Syariah',
      'Akuntansi Sektor Publik',
      'Manajemen Keuangan Sektor Publik',
      'Bahasa Inggris untuk Komunikasi Bisnis dan Profesional',
      'Keuangan Islam Terapan (S2 Terapan)',
    ],
  };

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    final random = Random(42);
    _stars = List.generate(
      75,
      (i) => Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 1.8 + 0.6,
        speed: random.nextDouble() * 0.2 + 0.1,
        seed: i,
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _starController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_namaController.text.isEmpty ||
        _nimController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedUkm == null ||
        (!widget.isOrganizer &&
            (_selectedJurusan == null || _selectedProdi == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data formulir pendaftaran!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi dan konfirmasi kata sandi tidak cocok!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'role': widget.isOrganizer ? 'organizer' : 'mahasiswa',
          'username': _namaController.text.trim(),
          'nim': _nimController.text.trim(),
          'phone': _phoneController.text.trim(),
          'ukm': _selectedUkm,
          'jurusan': widget.isOrganizer ? '-' : _selectedJurusan,
          'prodi': widget.isOrganizer ? '-' : _selectedProdi,
          'angkatan': _selectedAngkatan,
        },
      );
      if (response.user != null && mounted) {
        // Jika verifikasi email aktif, belum ada sesi untuk mengirim pengajuan booth.
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Akun berhasil dibuat. Konfirmasi email terlebih dahulu, lalu login untuk melanjutkan panduan booth.',
              ),
              backgroundColor: Color(0xFF8B5CF6),
              duration: Duration(seconds: 6),
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        if (widget.isOrganizer) {
          // Setelah registrasi Organizer berhasil, langsung arahkan ke panduan buka booth.
          // pushReplacement membuat tombol kembali pada halaman panduan kembali ke Login,
          // bukan ke formulir registrasi Organizer yang sudah selesai.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pendaftaran Organizer berhasil! Silakan ikuti panduan buka booth.',
              ),
              backgroundColor: Color(0xFF00A878),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const BoothOnboardingScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran Mahasiswa Berhasil!'),
              backgroundColor: Color(0xFF00A878),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Mendaftar: $e'),
            backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    String titleText = widget.isOrganizer
        ? 'Registrasi Akun Organizer'
        : 'Registrasi Akun Mahasiswa';
    return Scaffold(
      backgroundColor: const Color(0xFF060409),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarrySkyPainter(
                  animationValue: _starController.value,
                  stars: _stars,
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        titleText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: 840,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withOpacity(0.3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.isOrganizer
                                        ? 'Lengkapi Data Organizer dan Pilih UKM Penanggung Jawab Event.'
                                        : 'Lengkapi Data Identitas Kemahasiswaan & UKM Anda Untuk Pendaftaran Event Booth.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'Nama Lengkap / Username',
                                          _namaController,
                                          Icons.person_outline,
                                          'Masukkan Nama...',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          'NIM / ID Anggota',
                                          _nimController,
                                          Icons.badge_outlined,
                                          'Masukkan NIM/ID...',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'Email Kampus / Resmi',
                                          _emailController,
                                          Icons.email_outlined,
                                          'Masukkan Email...',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          'Nomor WhatsApp',
                                          _phoneController,
                                          Icons.phone_android_rounded,
                                          'Masukkan No WhatsApp...',
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pilihan UKM',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildGlassDropdown(
                                        value: _selectedUkm,
                                        hint: 'Pilih UKM...',
                                        items: globalUkmList,
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedUkm = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (!widget.isOrganizer) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Jurusan',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              _buildGlassDropdown(
                                                value: _selectedJurusan,
                                                hint: 'Pilih Jurusan...',
                                                items: _jurusanList,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedJurusan = val;
                                                    _selectedProdi = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Angkatan',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              _buildGlassDropdown(
                                                value: _selectedAngkatan,
                                                hint: 'Pilih Angkatan...',
                                                items: _angkatanList,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedAngkatan = val;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Program Studi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _buildGlassDropdown(
                                          value: _selectedProdi,
                                          hint: _selectedJurusan == null
                                              ? 'Pilih Jurusan terlebih dahulu...'
                                              : 'Pilih Program Studi...',
                                          items: _selectedJurusan == null
                                              ? []
                                              : _prodiMap[_selectedJurusan!]!,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedProdi = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPasswordField(
                                          'Kata Sandi',
                                          _passwordController,
                                          _obscurePassword,
                                          () {
                                            setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildPasswordField(
                                          'Konfirmasi Kata Sandi',
                                          _confirmPasswordController,
                                          _obscureConfirmPassword,
                                          () {
                                            setState(
                                              () => _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreeTerms,
                                        onChanged: (val) => setState(
                                          () => _agreeTerms = val ?? true,
                                        ),
                                        activeColor: const Color(0xFF8B5CF6),
                                        checkColor: Colors.white,
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Saya menyatakan bahwa data yang diinput adalah benar dan bersedia mematuhi tata tertib event.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: _isLoading
                                          ? null
                                          : _handleRegister,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Daftarkan Akun Baru',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.black38),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onTapToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••••••',
                    hintStyle: TextStyle(color: Colors.black38),
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTapToggle,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool hasItems = items.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: !hasItems
          ? null
          : () async {
              final selected = await showDialog<String>(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.black.withOpacity(0.52),
                builder: (dialogContext) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          decoration: BoxDecoration(
                            color: const Color(0xFF160D25).withOpacity(0.78),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFB794F6).withOpacity(0.55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                                blurRadius: 28,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.tune_rounded,
                                      color: Color(0xFFB794F6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        hint,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Tutup',
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.12),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 420),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    final selectedItem = item == value;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      child: Material(
                                        color: selectedItem
                                            ? const Color(0xFF8B5CF6).withOpacity(0.25)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => Navigator.of(dialogContext).pop(item),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  selectedItem
                                                      ? Icons.check_circle_rounded
                                                      : Icons.circle_outlined,
                                                  size: 17,
                                                  color: selectedItem
                                                      ? const Color(0xFFC4B5FD)
                                                      : Colors.white38,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: TextStyle(
                                                      color: selectedItem
                                                          ? Colors.white
                                                          : Colors.white.withOpacity(0.88),
                                                      fontSize: 13,
                                                      fontWeight: selectedItem
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );

              if (selected != null) {
                onChanged(selected);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB794F6).withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null
                      ? Colors.white.withOpacity(0.48)
                      : Colors.white.withOpacity(0.92),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              hasItems ? Icons.keyboard_arrow_down_rounded : Icons.lock_outline,
              color: const Color(0xFFB794F6),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 4. DASHBOARD SCREEN CLIENT ====================
// DASHBOARD SCREEN CLIENT: dipertahankan untuk role mahasiswa/client.
