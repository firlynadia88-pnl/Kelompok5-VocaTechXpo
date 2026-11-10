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
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';

import '../client/dashboard_screen.dart';
import 'organizer_dashboard_screen.dart';
// ==================== ALUR BUKA BOOTH ====================
class BoothOnboardingScreen extends StatefulWidget {
  const BoothOnboardingScreen({super.key});

  @override
  State<BoothOnboardingScreen> createState() => _BoothOnboardingScreenState();
}

class _BoothOnboardingScreenState extends State<BoothOnboardingScreen> {
  static const Color _purple = Color(0xFF8050F6);
  static const List<String> _businessTypes = [
    'Makanan',
    'IoT/Pameran',
    'Bazar',
  ];
  static const List<String> _organizerTypes = [
    'UKM IECLOP (Improving English Club of Polytechnic)',
    'UKM LDK-FORDIMA',
    'UKM POLICY (Polytechnic Linux Community)',
    'UKM Sanggar Seni',
    'UKM Edelweis',
    'UKM Taekwondo',
    'UKM Polyrobocom',
    'UKM Merpati Putih',
    'BEM',
    'HIMATIK',
    'HIMABIS',
    'HIMA ELEKTRO',
    'HIMA MESIN',
    'HIMA SIPIL',
    'Wirausaha Mahasiswa Mandiri (UMKM)',
  ];

  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _organizerUsernameController =
      TextEditingController();
  final TextEditingController _organizerPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _agreed = false;
  bool _obscureOrganizerPassword = true;
  bool _isSubmitting = false;
  final Set<int> _expandedTutorialSteps = {1};
  String? _businessType;
  String? _organizerType;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _organizerUsernameController.dispose();
    _organizerPasswordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _continueFromTerms() {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centang persetujuan persyaratan untuk melanjutkan.'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }
    _goToStep(2);
  }

  Future<void> _submitBooth() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_businessType == null || _organizerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih jenis usaha dan kategori pelaku usaha terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi login tidak ditemukan. Silakan login kembali sebelum membuka booth.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final username = _organizerUsernameController.text.trim();
      final password = _organizerPasswordController.text;

      // Simpan pengajuan booth milik akun yang sedang login.
      await supabase.from('booths').insert({
        'owner_id': user.id,
        'name': _nameController.text.trim(),
        'business_type': _businessType,
        'organizer_type': _organizerType,
        'admin_whatsapp': _phoneController.text.trim(),
        'status': 'pending',
      });

      // Perbarui hanya kolom profil yang memang diizinkan oleh GRANT.
      await supabase
          .from('profiles')
          .update({
            'username': username,
            'email': user.email,
            'phone': _phoneController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Simpan username/kategori ke metadata Auth; password dikelola Supabase Auth.
      await supabase.auth.updateUser(
        UserAttributes(
          password: password,
          data: {
            'username': username,
            'role': 'organizer',
            'ukm': _organizerType,
          },
        ),
      );

      // Role diubah melalui fungsi SECURITY DEFINER, bukan UPDATE langsung.
      await supabase.rpc('become_organizer');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booth berhasil diajukan! Mengarahkan ke Dashboard Organizer...',
          ),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const OrganizerDashboardScreen(),
        ),
        (route) => false,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data booth: ${e.message}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 6),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data booth diproses, tetapi pembaruan akun gagal: ${e.message}',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat membuka booth: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF21163F),
        elevation: 0,
        scrolledUnderElevation: 0,
        // Geser judul sedikit mendekati tombol panah.
        titleSpacing: 0,
        title: const Text(
          'Buka Booth Anda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF21163F),
          ),
        ),
        // Geser tombol kembali sedikit ke kanan, tanpa membuat jarak judul terlalu jauh.
        leadingWidth: 78,
        leading: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E0F4), width: 1.1),
            ),
            alignment: Alignment.center,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () {
                if (_step > 0) {
                  _goToStep(_step - 1);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: List.generate(3, (index) {
                      final active = index <= _step;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                          height: 5,
                          decoration: BoxDecoration(
                            color: active ? _purple : const Color(0xFFE4DDF8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildTutorialStep(size),
                      _buildTermsStep(),
                      _buildBoothFormStep(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tutorialIllustration({
    required IconData icon,
    required String label,
    required int variant,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E0FF)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 20,
                  top: 12,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 22,
                    color: Color(0xFFC3AEFF),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 25,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Color(0xFFB59AFF),
                  ),
                ),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE9DEFF), Color(0xFFD2BEFF)],
                    ),
                  ),
                  child: Icon(icon, size: 54, color: _purple),
                ),
                if (variant == 0)
                  Positioned(
                    bottom: 1,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: _purple,
                        size: 25,
                      ),
                    ),
                  ),
                if (variant == 1)
                  Positioned(
                    bottom: 2,
                    right: 43,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: _purple,
                        size: 24,
                      ),
                    ),
                  ),
                if (variant == 2)
                  Positioned(
                    bottom: 1,
                    right: 43,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: _purple,
                        size: 24,
                      ),
                    ),
                  ),
                if (variant == 3)
                  Positioned(
                    bottom: 1,
                    right: 43,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF36A875),
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF55427D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tutorialStepCard({
    required int number,
    required IconData icon,
    required String title,
    required String description,
    required String imageLabel,
    required int variant,
    required List<String> tips,
  }) {
    final isExpanded = _expandedTutorialSteps.contains(number);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isExpanded ? const Color(0xFFD7C7FF) : const Color(0xFFE9E3F7),
          width: isExpanded ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F4BC3)
                .withOpacity(isExpanded ? 0.08 : 0.025),
            blurRadius: isExpanded ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedTutorialSteps.remove(number);
                    } else {
                      _expandedTutorialSteps.add(number);
                    }
                  });
                },
                splashColor: const Color(0xFF8050F6).withOpacity(0.08),
                highlightColor: const Color(0xFF8050F6).withOpacity(0.035),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0E9FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$number',
                          style: const TextStyle(
                            color: _purple,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF20183F),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: Color(0xFF777493),
                              ),
                              maxLines: isExpanded ? null : 2,
                              overflow: isExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? const Color(0xFFF0E9FF)
                                : const Color(0xFFF8F6FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _purple,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tutorialIllustration(
                            icon: icon,
                            label: imageLabel,
                            variant: variant,
                          ),
                          const SizedBox(height: 13),
                          ...tips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 17,
                                    color: _purple,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: Color(0xFF5E5878),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showIosStylePicker({
    required String title,
    required List<String> options,
    required String? selectedValue,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      barrierDismissible: true,
      builder: (popupContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8FD),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 28,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 9),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D4E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF21163F),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        minimumSize: Size.zero,
                        onPressed: () => Navigator.of(popupContext).pop(),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            color: _purple,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEAE6F2)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option == selectedValue;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => Navigator.of(popupContext).pop(option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEDE5FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFCBB8FF)
                                    : const Color(0xFFEDE9F5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.3,
                                      color: const Color(0xFF292142),
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    color: _purple,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialStep(Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Panduan Membuka Booth',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17133A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ikuti panduan berikut untuk mulai berjualan, memamerkan karya, atau memperkenalkan kegiatan UKM di VocaTechXpo. Baca setiap tahap sebelum melanjutkan.',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF777493),
            ),
          ),
          const SizedBox(height: 20),
          _tutorialStepCard(
            number: 1,
            icon: Icons.storefront_rounded,
            title: 'Buka menu Buka Booth Anda',
            description: 'Masuk ke halaman Profil, lalu pilih menu “Buka Booth Anda” pada bagian Aktivitas Saya. Kamu akan diarahkan ke panduan pendaftaran booth.',
            imageLabel: 'Mulai dari menu profil',
            variant: 0,
            tips: [
              'Pastikan kamu masuk menggunakan akun VocaTechXpo milikmu.',
              'Baca panduan ini sampai selesai agar memahami proses pendaftaran booth.',
            ],
          ),
          _tutorialStepCard(
            number: 2,
            icon: Icons.assignment_rounded,
            title: 'Pahami alur dan persyaratan',
            description: 'Sebelum mengisi data, pahami ketentuan yang berlaku untuk semua pemilik booth. Informasi yang diberikan harus benar dan konten harus sesuai aturan.',
            imageLabel: 'Baca ketentuan sebelum mendaftar',
            variant: 1,
            tips: [
              'Baca seluruh persyaratan buka booth dengan teliti.',
              'Centang “Saya menyetujui semua persyaratan yang telah ditentukan” jika kamu setuju.',
              'Tekan tombol “Mulai Buka Booth Anda” untuk masuk ke formulir.',
            ],
          ),
          _tutorialStepCard(
            number: 3,
            icon: Icons.edit_document,
            title: 'Lengkapi informasi booth',
            description: 'Isi formulir dengan identitas usaha, event, atau kegiatan yang ingin kamu tampilkan. Pilih jenis usaha dan kategori yang paling sesuai.',
            imageLabel: 'Isi data booth dengan benar',
            variant: 0,
            tips: [
              'Nama Event / Usaha: tulis nama yang mudah dikenali pengunjung.',
              'Jenis Usaha: pilih Makanan, IoT/Pameran, atau Bazar.',
              'Kategori Pelaku Usaha: pilih UKM yang sesuai atau Wirausaha Mahasiswa Mandiri (UMKM).',
              'Nomor Admin: masukkan nomor WhatsApp aktif yang dapat dihubungi pengunjung.',
            ],
          ),
          _tutorialStepCard(
            number: 4,
            icon: Icons.add_photo_alternate_rounded,
            title: 'Siapkan produk atau informasi event',
            description: 'Setelah booth diajukan dan tersedia, lengkapi tampilan booth dengan informasi yang membantu pengunjung memahami apa yang kamu tawarkan.',
            imageLabel: 'Tampilkan produk dan kegiatan',
            variant: 1,
            tips: [
              'Gunakan foto produk atau kegiatan yang jelas dan relevan.',
              'Tulis nama, deskripsi, harga, atau jadwal kegiatan jika diperlukan.',
              'Pastikan informasi yang ditampilkan akurat dan tidak menyesatkan.',
            ],
          ),
          _tutorialStepCard(
            number: 5,
            icon: Icons.campaign_rounded,
            title: 'Perkenalkan booth kepada pengunjung',
            description: 'Buat booth mudah dikenali dan informatif. Kamu dapat membagikan informasi booth melalui kanal promosi yang tersedia dan mengarahkan pengunjung untuk melihat produk atau kegiatanmu.',
            imageLabel: 'Kenalkan booth di VocaTechXpo',
            variant: 2,
            tips: [
              'Gunakan nama dan deskripsi yang jelas.',
              'Tanggapi pertanyaan pengunjung dengan sopan.',
              'Jaga komunikasi dan informasi kontak tetap aktif.',
            ],
          ),
          _tutorialStepCard(
            number: 6,
            icon: Icons.verified_user_rounded,
            title: 'Tunggu pemeriksaan pengajuan',
            description: 'Informasi booth dapat ditinjau oleh penyelenggara sebelum ditampilkan. Pastikan data yang kamu berikan lengkap agar proses pemeriksaan berjalan lebih lancar.',
            imageLabel: 'Pemeriksaan sebelum booth ditampilkan',
            variant: 3,
            tips: [
              'Penyelenggara dapat meminta perbaikan jika ada informasi yang kurang sesuai.',
              'Booth dapat ditampilkan setelah proses persetujuan sesuai mekanisme aplikasi.',
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5DAFF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: _purple, size: 23),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tips: gunakan informasi yang jelas, foto yang sesuai, dan nomor admin yang aktif agar pengunjung lebih mudah mengenali booth kamu.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF55427D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _goToStep(1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Lanjut ke Persyaratan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsStep() {
    final terms = [
      'Informasi yang diberikan harus benar, lengkap, dan sesuai dengan event atau usaha yang dibuka.',
      'Konten booth tidak boleh mengandung unsur SARA, kekerasan, penipuan, atau hal yang melanggar hukum.',
      'Penyelenggara berhak menolak atau menonaktifkan booth yang tidak sesuai dengan ketentuan.',
      'Pemilik booth bertanggung jawab atas produk, layanan, harga, dan aktivitas yang ditampilkan.',
      'Komunikasi dan transaksi dengan pengunjung menjadi tanggung jawab pemilik booth masing-masing.',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.fact_check_rounded, color: _purple, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Persyaratan Buka Booth',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17133A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Harap baca dan pahami ketentuan berikut sebelum melanjutkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF777493), height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAE4FF)),
            ),
            child: Column(
              children: terms
                  .asMap()
                  .entries
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: entry.key == terms.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: Color(0xFFF0EDFA)),
                              ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0E9FF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: _purple,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                height: 1.45,
                                color: Color(0xFF55516F),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _agreed ? _purple : const Color(0xFFE4DDF8),
              ),
            ),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _purple,
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              title: const Text(
                'Saya menyetujui semua persyaratan yang telah ditentukan.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF282142),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            'Mulai Buka Booth Anda',
            Icons.arrow_forward_rounded,
            _continueFromTerms,
          ),
        ],
      ),
    );
  }

  Widget _buildBoothFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.store_mall_directory_rounded,
              color: _purple,
              size: 58,
            ),
            const SizedBox(height: 10),
            const Text(
              'Lengkapi Informasi Booth',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17133A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Isi informasi berikut untuk mulai mengajukan booth Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF777493), height: 1.4),
            ),
            const SizedBox(height: 22),
            _fieldLabel('Nama Event / Usaha'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                'Masukkan nama event atau usaha Anda',
                Icons.description_outlined,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama event/usaha wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Jenis Usaha'),
            FormField<String>(
              initialValue: _businessType,
              validator: (value) => value == null ? 'Pilih jenis usaha.' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final value = await _showIosStylePicker(
                        title: 'Pilih Jenis Usaha',
                        options: _businessTypes,
                        selectedValue: _businessType,
                      );
                      if (value != null) {
                        setState(() => _businessType = value);
                        field.didChange(value);
                      }
                    },
                    child: InputDecorator(
                      decoration:
                          _inputDecoration(
                            'Pilih jenis usaha',
                            Icons.calendar_month_outlined,
                          ).copyWith(
                            errorText: field.errorText,
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _purple,
                              size: 23,
                            ),
                          ),
                      child: Text(
                        _businessType ?? 'Pilih jenis usaha',
                        style: TextStyle(
                          fontSize: 13,
                          color: _businessType == null
                              ? const Color(0xFFAAA5C2)
                              : const Color(0xFF292142),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Kategori Pelaku Usaha'),
            FormField<String>(
              initialValue: _organizerType,
              validator: (value) =>
                  value == null ? 'Pilih kategori pelaku usaha.' : null,
              builder: (field) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final value = await _showIosStylePicker(
                    title: 'Kategori Pelaku Usaha',
                    options: _organizerTypes,
                    selectedValue: _organizerType,
                  );
                  if (value != null) {
                    setState(() => _organizerType = value);
                    field.didChange(value);
                  }
                },
                child: InputDecorator(
                  decoration:
                      _inputDecoration(
                        'Pilih kategori pelaku usaha',
                        Icons.grid_view_rounded,
                      ).copyWith(
                        errorText: field.errorText,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _purple,
                          size: 23,
                        ),
                      ),
                  child: Text(
                    _organizerType ?? 'Pilih kategori pelaku usaha',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _organizerType == null
                          ? const Color(0xFFAAA5C2)
                          : const Color(0xFF292142),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Nomor Admin WhatsApp'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                'Masukkan nomor WhatsApp admin',
                Icons.phone_outlined,
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Nomor admin wajib diisi.';
                if (phone.replaceAll(RegExp(r'[^0-9+]'), '').length < 9)
                  return 'Masukkan nomor WhatsApp yang valid.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _fieldLabel('Username Organizer'),
            TextFormField(
              controller: _organizerUsernameController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: _inputDecoration(
                'Buat username untuk akun organizer',
                Icons.person_outline,
              ),
              validator: (value) {
                final username = value?.trim() ?? '';
                if (username.isEmpty) return 'Username organizer wajib diisi.';
                if (username.length < 3) return 'Username minimal 3 karakter.';
                if (username.contains(' '))
                  return 'Username tidak boleh mengandung spasi.';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _fieldLabel('Password Organizer'),
            TextFormField(
              controller: _organizerPasswordController,
              obscureText: _obscureOrganizerPassword,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  _inputDecoration(
                    'Buat password organizer (minimal 8 karakter)',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscureOrganizerPassword
                          ? 'Tampilkan password'
                          : 'Sembunyikan password',
                      onPressed: () => setState(
                        () => _obscureOrganizerPassword =
                            !_obscureOrganizerPassword,
                      ),
                      icon: Icon(
                        _obscureOrganizerPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _purple,
                      ),
                    ),
                  ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Password organizer wajib diisi.';
                if (password.length < 8) return 'Password minimal 8 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitBooth,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.storefront_rounded),
                label: Text(
                  _isSubmitting ? 'Menyimpan...' : 'Buka Booth',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pastikan semua informasi benar sebelum melanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF88839F)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Color(0xFF21183F),
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAA5C2), fontSize: 13),
        prefixIcon: Icon(icon, color: _purple, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4DDF8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4DDF8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );

  Widget _primaryButton(String label, IconData icon, VoidCallback onPressed) =>
      SizedBox(
        height: 54,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
          ),
        ),
      );
}
