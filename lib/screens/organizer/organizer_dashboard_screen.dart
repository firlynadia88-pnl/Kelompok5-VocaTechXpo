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

import '../../widgets/starry_sky.dart';
import '../shared/shared_messages_screen.dart';
import 'organizer_products_screen.dart';
import 'organizer_booth_management_screen.dart';
import 'booth_onboarding_screen.dart';
import '../auth/login_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _pageBackground = Color(0xFFF8FAFC);

  int _selectedIndex = 0;
  bool _isBoothMenuExpanded = true;
  bool _hasUnreadMessages = true;
  bool _profileLoading = true;
  String _username = 'Organizer';
  String _email = '';
  String _ukm = '';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _menuMessages = const [
    {
      'sender': 'Panitia VocaTechXpo',
      'message': 'Selamat datang di dashboard Organizer.',
      'time': 'Baru',
    },
    {
      'sender': 'Informasi Sistem',
      'message': 'Lengkapi informasi booth untuk memulai pengajuan.',
      'time': 'Panduan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOrganizerProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizerProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _profileLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('username, email, ukm, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      if (data != null) {
        _username = (data['username'] ?? '').toString().trim().isEmpty
            ? 'Organizer'
            : data['username'].toString();
        _email = (data['email'] ?? user.email ?? '').toString();
        _ukm = (data['ukm'] ?? '').toString();
      } else {
        _username = (user.userMetadata?['username'] ?? 'Organizer').toString();
        _email = user.email ?? '';
        _ukm = (user.userMetadata?['ukm'] ?? '').toString();
      }
    } catch (_) {
      if (mounted) {
        _username = (user.userMetadata?['username'] ?? 'Organizer').toString();
        _email = user.email ?? '';
        _ukm = (user.userMetadata?['ukm'] ?? '').toString();
      }
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Tetap kembalikan pengguna ke halaman login jika sign-out gagal.
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _selectMenu(int index, {required bool isMobile}) {
    if (index == 95) {
      _logout();
      return;
    }

    setState(() {
      _selectedIndex = index;
      if (index == 5) _hasUnreadMessages = false;
    });

    if (isMobile) Navigator.of(context).pop();
  }

  void _toggleBoothMenu() {
    setState(() {
      _isBoothMenuExpanded = !_isBoothMenuExpanded;
    });
  }

  void _openBoothOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BoothOnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      backgroundColor: _pageBackground,
      // Gunakan drawer langsung seperti Dashboard Client agar lebar panel,
      // overlay gelap, dan perilaku menutupnya konsisten.
      drawer: isDesktop ? null : _buildOrganizerSidebar(isMobile: true),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.16)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    Builder(
                      builder: (context) => IconButton(
                        tooltip: 'Buka menu',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded, color: _purple),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Icon(
                    Icons.storefront_rounded,
                    color: _accent,
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'VOCA-TECHXPO',
                    style: TextStyle(
                      color: Color(0xFF21163F),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 9 : 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE4D7FF)),
                    ),
                    child: Text(
                      'ORGANIZER',
                      style: TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 9 : 8,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isDesktop)
                    SizedBox(
                      width: 260,
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F3FA),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Profil Organizer',
                    onPressed: () => setState(() => _selectedIndex = 7),
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: _purple,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 260,
              child: _buildOrganizerSidebar(isMobile: false),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildSelectedOrganizerPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerSidebar({required bool isMobile}) {
    return Container(
      color: _purple,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Tutup menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              _organizerMenuItem(
                0,
                Icons.home_rounded,
                'Dashboard',
                isMobile,
              ),
              const SizedBox(height: 8),

              // Menu induk Kelola Booth dengan submenu yang bisa dibuka/tutup.
              _buildBoothMenuHeader(isMobile: isMobile),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(
                    left: 18,
                    top: 5,
                    bottom: 5,
                  ),
                  child: Column(
                    children: [
                      _organizerSubMenuItem(
                        1,
                        Icons.map_outlined,
                        'Control Center',
                        isMobile,
                      ),
                      _organizerSubMenuItem(
                        8,
                        Icons.assignment_outlined,
                        'Pemesanan',
                        isMobile,
                      ),
                      _organizerSubMenuItem(
                        9,
                        Icons.account_balance_wallet_outlined,
                        'Transaksi',
                        isMobile,
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isBoothMenuExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeInOut,
              ),

              const SizedBox(height: 8),
              _organizerMenuItem(
                2,
                Icons.inventory_2_rounded,
                'Produk Saya',
                isMobile,
              ),
              const SizedBox(height: 8),
              _organizerMenuItem(
                3,
                Icons.bar_chart_rounded,
                'Insight Penjualan',
                isMobile,
              ),
              const SizedBox(height: 8),
              _organizerMenuItem(
                4,
                Icons.star_border_rounded,
                'Rating & Ulasan',
                isMobile,
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 16),
              const Text(
                'Komunikasi & Layanan',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _organizerMenuItem(
                5,
                Icons.forum_rounded,
                'Pesan',
                isMobile,
                showRedDot: _hasUnreadMessages,
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 16),
              const Text(
                'Akun',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _organizerMenuItem(
                7,
                Icons.person_outline_rounded,
                'Profile',
                isMobile,
              ),
              const SizedBox(height: 8),
              _organizerMenuItem(
                95,
                Icons.logout_rounded,
                'Keluar',
                isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoothMenuHeader({required bool isMobile}) {
    final bool boothSectionSelected =
        _selectedIndex == 1 || _selectedIndex == 8 || _selectedIndex == 9;

    return Material(
      color: boothSectionSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _toggleBoothMenu,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 20,
                color: boothSectionSelected ? _purple : Colors.white70,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Kelola Booth',
                  style: TextStyle(
                    color: boothSectionSelected
                        ? const Color(0xFF2E1065)
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _isBoothMenuExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 19,
                  color: boothSectionSelected ? _purple : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _organizerSubMenuItem(
    int index,
    IconData icon,
    String label,
    bool isMobile,
  ) {
    final bool selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? Colors.white.withOpacity(0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => _selectMenu(index, isMobile: isMobile),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _organizerMenuItem(
    int index,
    IconData icon,
    String label,
    bool isMobile, {
    bool hasDropdown = false,
    bool showRedDot = false,
  }) {
    final bool selected = _selectedIndex == index;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectMenu(index, isMobile: isMobile),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? _purple : Colors.white70,
                  ),
                  if (showRedDot)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5A66),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? const Color(0xFF2E1065) : Colors.white,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (hasDropdown)
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: selected ? _purple : Colors.white70,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedOrganizerPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOrganizerOverview();
      case 1:
        return const OrganizerBoothManagementScreen(key: ValueKey('booths'));
      case 8:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('booking'),
          title: 'Pemesanan Booth',
          subtitle:
              'Daftar pemesanan booth dari client akan ditampilkan di halaman ini. Data akan dihubungkan dengan Supabase pada tahap integrasi pemesanan.',
          icon: Icons.assignment_outlined,
        );
      case 9:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('transactions'),
          title: 'Transaksi',
          subtitle:
              'Informasi pembayaran, status verifikasi, dan riwayat transaksi akan ditampilkan di halaman ini setelah integrasi pembayaran selesai.',
          icon: Icons.account_balance_wallet_outlined,
        );
      case 2:
        return OrganizerProductsScreen(
          key: const ValueKey('products'),
          onBack: () {
            setState(() => _selectedIndex = 0);
          },
        );
      case 3:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('sales'),
          title: 'Insight Penjualan',
          subtitle: 'Ringkasan pesanan, pendapatan, dan performa penjualan akan tampil di sini setelah data transaksi terhubung.',
          icon: Icons.bar_chart_rounded,
        );
      case 4:
        return _buildOrganizerEmptyPage(
          key: const ValueKey('ratings'),
          title: 'Rating & Ulasan',
          subtitle:
              'Pantau penilaian dan masukan pengunjung terhadap booth Anda.',
          icon: Icons.star_border_rounded,
        );
      case 5:
        return SharedMessagesScreen(
          isOrganizer: true,
          onBack: () {
            setState(() => _selectedIndex = 0);
          },
        );
      case 6:
        return SharedMessagesScreen(
          isOrganizer: true,
          onBack: () {
            setState(() => _selectedIndex = 0);
          },
        );
      case 7:
        return _buildOrganizerProfile();
      default:
        return _buildOrganizerOverview();
    }
  }

  Widget _buildOrganizerOverview() {
    return ListView(
      key: const ValueKey('organizer-dashboard'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Dashboard Organizer',
          style: const TextStyle(
            color: Color(0xFF21163F),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _profileLoading ? 'Memuat profil...' : 'Halo, $_username! 👋',
          style: const TextStyle(
            color: Color(0xFF6B6484),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola booth, produk, dan aktivitas usaha Anda di VocaTechXpo.',
          style: TextStyle(color: Color(0xFF777493), height: 1.5),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.18),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kelola Produk dan Promosi Anda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola event yang diunggah, edit informasi event, dan atur banner promosi Anda untuk ditampilkan di dashboard client.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _selectedIndex = 2);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text(
                    'Produk Saya',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ringkasan Aktivitas',
          style: TextStyle(
            color: Color(0xFF21163F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns = constraints.maxWidth > 850
                ? 4
                : constraints.maxWidth > 500
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 3.0 : 1.65,
              children: const [
                _OrganizerMetricCard(
                  title: 'Status Booth',
                  value: '—',
                  caption: 'Belum dimuat',
                  icon: Icons.storefront_rounded,
                  color: Color(0xFF8B5CF6),
                ),
                _OrganizerMetricCard(
                  title: 'Produk',
                  value: '—',
                  caption: 'Data belum terhubung',
                  icon: Icons.inventory_2_rounded,
                  color: Color(0xFF3478FF),
                ),
                _OrganizerMetricCard(
                  title: 'Pesanan',
                  value: '—',
                  caption: 'Data belum terhubung',
                  icon: Icons.receipt_long_rounded,
                  color: Color(0xFFF59E0B),
                ),
                _OrganizerMetricCard(
                  title: 'Penjualan',
                  value: '—',
                  caption: 'Data belum terhubung',
                  icon: Icons.trending_up_rounded,
                  color: Color(0xFF10B981),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Akses Cepat',
          style: TextStyle(
            color: Color(0xFF21163F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _quickAction(
              icon: Icons.storefront_rounded,
              label: 'Kelola Booth',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _quickAction(
              icon: Icons.inventory_2_rounded,
              label: 'Produk Saya',
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _quickAction(
              icon: Icons.bar_chart_rounded,
              label: 'Insight Penjualan',
              onTap: () => setState(() => _selectedIndex = 3),
            ),
            _quickAction(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () => setState(() => _selectedIndex = 5),
            ),
          ],
        ),
        if (_ukm.isNotEmpty) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAE4F8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: _accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori Organizer',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777493),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _ukm,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF21163F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 190,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAE4F8)),
            ),
            child: Row(
              children: [
                Icon(icon, color: _accent, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF2D2448),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerEmptyPage({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(0xFF21163F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF777493), height: 1.5),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAE4F8)),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0E9FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _accent, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF21163F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                onAction == null ? 'Belum ada data untuk ditampilkan.' : 'Mulai dari pengajuan booth. Data akan tampil setelah proses dan database fitur ini terhubung.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777493), height: 1.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerMessages() {
    return ListView(
      key: const ValueKey('organizer-chat'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Chat',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(0xFF21163F),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pusat komunikasi untuk informasi dan calon pembeli booth Anda.',
          style: TextStyle(color: Color(0xFF777493), height: 1.5),
        ),
        const SizedBox(height: 20),
        ..._menuMessages.map(
          (message) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFEAE4F8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF0E9FF),
                  child: Icon(Icons.person_outline_rounded, color: _purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['sender']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF21163F),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message['message']!,
                        style: const TextStyle(
                          color: Color(0xFF777493),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message['time']!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Daftar percakapan contoh ini belum terhubung dengan tabel chat Supabase.',
          style: TextStyle(fontSize: 11, color: Color(0xFF8A849F)),
        ),
      ],
    );
  }

  Widget _buildOrganizerProfile() {
    return ListView(
      key: const ValueKey('organizer-profile'),
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Profile Organizer',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(0xFF21163F),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Informasi akun Organizer yang sedang masuk.',
          style: TextStyle(color: Color(0xFF777493)),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAE4F8)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFF0E9FF),
                child: Icon(Icons.person_rounded, color: _accent, size: 38),
              ),
              const SizedBox(height: 12),
              Text(
                _username,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF21163F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777493)),
              ),
              const SizedBox(height: 20),
              _profileRow(
                'Role',
                'Organizer',
                Icons.admin_panel_settings_outlined,
              ),
              const Divider(height: 24),
              _profileRow(
                'UKM / Kategori',
                _ukm.isEmpty ? 'Belum diisi' : _ukm,
                Icons.groups_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _accent, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF777493), fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF21163F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrganizerMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _OrganizerMetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6F6889),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF21163F),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(color: Color(0xFF8A849F), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
