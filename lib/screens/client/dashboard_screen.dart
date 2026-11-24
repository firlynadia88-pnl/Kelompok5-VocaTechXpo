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

import '../../widgets/starry_sky.dart';
import '../../widgets/realistic_tree_3d_painter.dart';
import '../shared/shared_messages_screen.dart';
import '../organizer/booth_onboarding_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedTabFilter = 0;
  int _currentBannerIndex = 0;
  int _currentPosterIndex = 0;

  bool _hasUnreadMessages = true;
  bool _isDarkMode = false;
  int _membershipTab = 0;
  String _selectedFont = 'ppins';

  late final AnimationController _shimmerController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat();

  final List<Map<String, dynamic>> _incomingMessages = [
    {
      'sender': 'Panitia Expo 2026',
      'message': 'Halo tenant, mohon konfirmasi kehadiran pitching.',
      'time': '10:15',
    },
    {
      'sender': 'Klien - Budi Santoso',
      'message': 'Apakah stok Smart Hydroponic ready?',
      'time': '09:30',
    },
    {
      'sender': 'Organizer Utama',
      'message': 'Pemberitahuan: Setup booth dimulai pukul 08.00.',
      'time': 'Kemarin',
    },
  ];

  final PageController _bannerController = PageController();
  final PageController _posterController = PageController();

  Timer? _posterTimer;
  RealtimeChannel? _promotionChannel;
  RealtimeChannel? _eventChannel;
  RealtimeChannel? _heroBannerChannel;
  List<String> _heroBannerUrls = [];
  // Jika banner dari Organizer tersedia, tampilkan hanya banner tersebut.
  // Banner aset bawaan dipakai sebagai fallback saat belum ada banner upload.
  int get _visibleHeroBannerCount =>
      _heroBannerUrls.isNotEmpty ? _heroBannerUrls.length : _bannerImages.length;

  List<Map<String, dynamic>> _uploadedEvents = [];
  Map<String, dynamic>? _selectedClientEvent;
  String? _selectedClientLayoutItem;
  gmap.MapType _clientEventMapType = gmap.MapType.normal;

  List<Map<String, dynamic>> get _filteredUploadedEvents {
    final section = _selectedTabFilter == 0 ? 'unggulan' : 'ukm_startup';
    return _uploadedEvents.where((event) =>
      (event['display_section'] ?? 'ukm_startup').toString() == section &&
      (event['poster_url'] ?? '').toString().trim().isNotEmpty
    ).toList();
  }

  int get _visiblePosterCount {
    if (_uploadedEvents.isEmpty) return _posterImages.length;
    return _filteredUploadedEvents.isEmpty ? 1 : _filteredUploadedEvents.length;
  }

  Future<void> _loadHeroBanners() async {
    try {
      final rows = await Supabase.instance.client
          .from('hero_banners')
          .select('image_url')
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final urls = (rows as List)
          .map((row) => (row['image_url'] ?? '').toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _heroBannerUrls = urls;
        _currentBannerIndex = 0;
      });
      if (_bannerController.hasClients) {
        _bannerController.jumpToPage(0);
      }
    } catch (e) {
      // Jika tabel belum dimigrasikan, banner bawaan tetap ditampilkan.
      debugPrint('Gagal memuat banner utama: $e');
    }
  }

  Future<void> _loadUploadedEvents() async {
    try {
      final rows = await Supabase.instance.client
          .from('booth_events')
          .select('id, owner_id, event_name, category, event_date, booth_count, location, price, description, poster_url, display_section, ukm_name, layout_config, status, created_at')
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _uploadedEvents = (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .where((event) => (event['poster_url'] ?? '').toString().trim().isNotEmpty)
            .toList();
        _currentPosterIndex = 0;
      });
      if (_posterController.hasClients) _posterController.jumpToPage(0);
    } catch (e) {
      debugPrint('Gagal memuat poster event: $e');
    }
  }

  final List<String> _bannerImages = [
    'assets/images/banner_1.PNG',
    'assets/images/banner_2.PNG',
    'assets/images/banner_3.PNG',
  ];

  final List<String> _posterImages = [
    'assets/images/poster_tenant_sanggar.png',
    'assets/images/poster_umkm_pom.jpeg',
    'assets/images/poster_bisnis_fest.jpeg',
  ];

  List<Map<String, dynamic>> _boothList = [
    {
      'title': 'Pastry Larana Booth',
      'category': 'Kuliner & F&B',
      'owner': 'UKM IECLOP',
      'price': 'Rp 10.000',
      'badge': 'Promo Hangat',
      'image': 'assets/images/Promo_Booth_Kue_Larana.png',
    },
    {
      'title': 'Open Koperasi Booth',
      'category': 'Koperasi UKM',
      'owner': 'UKM LDK-Fordima',
      'price': 'Rp 10.000',
      'badge': '',
      'image': 'assets/images/Poster_Promosi_Open_Koperasi.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPromotionsFromSupabase();
    _loadUploadedEvents();
    _loadHeroBanners();
    _eventChannel = Supabase.instance.client
        .channel('client-booth-events-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booth_events',
          callback: (_) => _loadUploadedEvents(),
        )
        .subscribe();
    _heroBannerChannel = Supabase.instance.client
        .channel('client-hero-banners-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hero_banners',
          callback: (_) => _loadHeroBanners(),
        )
        .subscribe();
    _promotionChannel = Supabase.instance.client
        .channel('client-promotions-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'promotions',
          callback: (_) => _loadPromotionsFromSupabase(),
        )
        .subscribe();
    _posterTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_posterController.hasClients) {
        int nextPage = _currentPosterIndex + 1;
        if (nextPage >= _visiblePosterCount) {
          nextPage = 0;
        }
        _posterController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadPromotionsFromSupabase() async {
    try {
      final rows = await Supabase.instance.client
          .from('promotions')
          .select('title, banner_url, owner_id, ukm')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      final loaded = (rows as List)
          .map<Map<String, dynamic>>((row) {
            final item = Map<String, dynamic>.from(row as Map);
            return {
              'title': (item['title'] ?? 'Promosi Organizer').toString(),
              'category': 'Promosi Spesial',
              'owner': (item['ukm'] ?? 'Organizer Voca-TechXpo').toString(),
              'price': '',
              'badge': 'Promosi Spesial',
              'image': (item['banner_url'] ?? '').toString(),
              'isNetwork': true,
            };
          })
          .where((item) => (item['image'] as String).isNotEmpty)
          .toList();
      if (!mounted || loaded.isEmpty) return;
      setState(() => _boothList = loaded);
    } catch (_) {
      // Jika tabel/bucket belum disiapkan, dashboard tetap memakai konten demo.
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _posterController.dispose();
    _shimmerController.dispose();
    _posterTimer?.cancel();
    final channel = _promotionChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    final eventChannel = _eventChannel;
    if (eventChannel != null) {
      Supabase.instance.client.removeChannel(eventChannel);
    }
    final heroBannerChannel = _heroBannerChannel;
    if (heroBannerChannel != null) {
      Supabase.instance.client.removeChannel(heroBannerChannel);
    }
    super.dispose();
  }

  void _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 900;

    final Color bgColor = _isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final Color cardColor = _isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;
    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E293B);
    final Color searchBgColor = _isDarkMode
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: isDesktop ? null : _buildSidebarContent(context, isMobile: true),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu_rounded, color: textColor),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'VOCA-TECHXPO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: isDesktop ? 260 : 130,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            onChanged: (val) {},
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Cari ...',
                              hintStyle: TextStyle(
                                color: Colors.black38,
                                fontSize: 12,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isDesktop) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: searchBgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          _isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _currentIndex == 1
                            ? Color(0xFF8B5CF6).withOpacity(0.2)
                            : searchBgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentIndex == 1
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: _currentIndex == 1
                            ? const Color(0xFF8B5CF6)
                            : textColor,
                        size: 18,
                      ),
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
              child: _buildSidebarContent(context, isMobile: false),
            ),
          Expanded(child: _getSelectedBodyContent()),
        ],
      ),
    );
  }

  Widget _getSelectedBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(MediaQuery.sizeOf(context).width > 900);
      case 1:
        return _buildProfileContent(context);
      case 2:
        return SharedMessagesScreen(
          isOrganizer: false,
          onBack: () {
            setState(() => _currentIndex = 0);
          },
        );
      case 3:
        return SharedMessagesScreen(
          isOrganizer: false,
          onBack: () {
            setState(() => _currentIndex = 0);
          },
        );
      case 4:
        return _buildClientOrdersPage();
      case 5:
        return _buildClientEventDetailPage();
      default:
        return _buildHomeContent(MediaQuery.sizeOf(context).width > 900);
    }
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isMobile}) {
    return Container(
      color: const Color(0xFF581C87),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            'Menu',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white60,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(0, Icons.home_rounded, 'Dashboard', isMobile),
          const SizedBox(height: 8),
          _buildDrawerItem(
            4,
            Icons.receipt_long_rounded,
            'Pesanan Saya',
            isMobile,
          ),
          const SizedBox(height: 8),
          _buildDrawerItem(97, Icons.star_border_rounded, 'Rating', isMobile),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'Komunikasi & Layanan',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white60,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerItem(
            2,
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
          _buildDrawerItem(
            1,
            Icons.person_outline_rounded,
            'Profile',
            isMobile,
          ),
          const SizedBox(height: 8),
          _buildDrawerItem(
            95,
            Icons.logout_rounded,
            'Keluar',
            isMobile,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    int index,
    IconData icon,
    String label,
    bool isMobile, {
    bool hasDropdown = false,
    bool isLogout = false,
    bool showRedDot = false,
  }) {
    bool isSelected = (_currentIndex == index);
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          _handleLogout(context);
          return;
        }
        if (index >= 0 && index <= 4) {
          setState(() {
            _currentIndex = index;
            if (index == 2) {
              _hasUnreadMessages = false;
            }
          });
        }
        if (isMobile) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF2E1065) : Colors.white70,
                ),
                if (showRedDot)
                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
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
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2E1065) : Colors.white,
                ),
              ),
            ),
            if (hasDropdown)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOrganizerContent() {
    final Color cardColor = _isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;
    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola komunikasi langsung dengan panitia event dan calon pembeli/klien booth Anda.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _incomingMessages.length,
              itemBuilder: (context, index) {
                final chat = _incomingMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF8B5CF6),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  chat['sender']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  chat['time']!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat['message']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotAIContent() {
    final Color cardColor = _isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;
    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E293B);
    final Color chatBubbleColor = _isDarkMode
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Chatbot Assistant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tanyakan seputar panduan pameran, tips promosi UMKM, atau bantuan teknis booth.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: chatBubbleColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Halo! Ada yang bisa saya bantu terkait persiapan booth atau informasi event Voca-techXpo 2026?',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: textColor, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan ke AI Assistant...',
                            hintStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: chatBubbleColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openClientEventDetail(Map<String, dynamic> event) {
    final config = event['layout_config'];
    final layout = config is Map ? Map<String, dynamic>.from(config) : <String, dynamic>{};
    final available = (layout['available_items'] is List)
        ? (layout['available_items'] as List).map((e) => e.toString()).toList()
        : <String>[];
    setState(() {
      _selectedClientEvent = Map<String, dynamic>.from(event);
      final label = (layout['item_label'] ?? (layout['layout_type'] == 'seating' ? 'seat' : 'booth')).toString();
      final prefix = label == 'seat' ? 'K' : 'B';
      _selectedClientLayoutItem = available.isNotEmpty ? '$prefix${available.first.replaceAll(RegExp(r'[^0-9]'), '')}' : null;
      _currentIndex = 5;
    });
  }

  String _clientMoneyLabel(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'gratis' || value == '0') return 'Gratis';
    if (value.toLowerCase().startsWith('rp')) return value;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return value;
    final number = int.tryParse(digits);
    if (number == null) return value;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp$formatted';
  }

  Widget _buildClientEventDetailPage() {
    final event = _selectedClientEvent;
    if (event == null) return _buildHomeContent(MediaQuery.sizeOf(context).width > 900);

    final configRaw = event['layout_config'];
    final config = configRaw is Map
        ? Map<String, dynamic>.from(configRaw)
        : <String, dynamic>{};
    final layoutType = (config['layout_type'] ?? 'booth').toString();
    final itemLabel = (config['item_label'] ?? (layoutType == 'seating' ? 'seat' : 'booth')).toString();
    final count = int.tryParse((config['item_count'] ?? event['booth_count'] ?? 0).toString()) ?? 0;
    final available = config['available_items'] is List
        ? (config['available_items'] as List).map((e) => e.toString()).toSet()
        : <String>{};
    final location = (event['location'] ?? '').toString().trim();
    final eventName = (event['event_name'] ?? 'Event Voca TechXpo').toString();
    final price = _clientMoneyLabel(event['price']);
    final isSeating = layoutType == 'seating';

    return Container(
      color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            IconButton(
              onPressed: () => setState(() => _currentIndex = 0),
              icon: Icon(Icons.arrow_back_rounded, color: _isDarkMode ? Colors.white : const Color(0xFF581C87)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Detail Event', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _isDarkMode ? Colors.white : const Color(0xFF2E1065)))),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                (event['poster_url'] ?? '').toString(),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEDE5FA), child: Center(child: Icon(Icons.image_not_supported_outlined, size: 42, color: Color(0xFF8050F6)))),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(eventName, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _isDarkMode ? Colors.white : const Color(0xFF24143F))),
          const SizedBox(height: 12),
          _clientInfoTile(Icons.category_outlined, 'Kategori', (event['category'] ?? '-').toString()),
          _clientInfoTile(Icons.calendar_month_outlined, 'Tanggal', (event['event_date'] ?? '-').toString()),
          _clientInfoTile(Icons.location_on_outlined, 'Lokasi', location.isEmpty ? 'Lokasi belum dicantumkan organizer' : location),
          _clientInfoTile(Icons.payments_outlined, 'Harga sewa', price),
          if ((event['description'] ?? '').toString().trim().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(event['description'].toString(), style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54, height: 1.5))),
          const SizedBox(height: 22),
          Text(isSeating ? 'Pilih Kursi' : 'Pilih Booth', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _isDarkMode ? Colors.white : const Color(0xFF2E1065))),
          const SizedBox(height: 6),
          Text('Denah dan nomor mengikuti konfigurasi yang dibuat organizer.', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 14),
          if (count <= 0)
            _clientEmptyCard('Denah belum tersedia', 'Organizer belum mengatur jumlah booth atau kursi untuk event ini.')
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x338B5CF6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSeating ? 'Denah Kursi Event' : 'Denah Booth Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _isDarkMode ? Colors.white : const Color(0xFF35245D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tampilan denah mengikuti susunan yang dibuat organizer. Pilih area yang masih tersedia.',
                    style: TextStyle(fontSize: 11, height: 1.4,
                      color: _isDarkMode ? Colors.white60 : const Color(0xFF777493)),
                  ),
                  const SizedBox(height: 12),
                  if (isSeating)
                    _buildClientSeatMap(count, available, itemLabel)
                  else
                    _buildClientBoothMap(count, available, itemLabel),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    _clientLegend(const Color(0xFFEDE4FF), 'Tersedia'),
                    _clientLegend(const Color(0xFF7C3AED), 'Pilihan kamu'),
                    _clientLegend(const Color(0xFFE5E7EB), 'Ditutup organizer'),
                  ]),
                ],
              ),
            ),
          const SizedBox(height: 18),
          _buildClientEventLocationMap(event, location),
          const SizedBox(height: 18),
          SizedBox(height: 50, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _selectedClientLayoutItem == null ? null : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denah sudah ditampilkan. Integrasi checkout perlu tabel booking dan pembayaran terlebih dahulu.')));
            },
            child: Text(_selectedClientLayoutItem == null ? 'Pilih booth/kursi tersedia' : 'Lanjutkan dengan $_selectedClientLayoutItem'),
          )),
        ],
      ),
    );
  }


  // Denah booth client memakai susunan, ukuran, dan dekorasi yang sama
  // dengan denah 3D pada halaman Organizer. Interaksi pilih booth tetap khusus client.
  Widget _buildClientBoothMap(int count, Set<String> available, String itemLabel) {
    Widget booth(int number) {
      if (number > count) return const SizedBox.shrink();

      final id = '${itemLabel == 'seat' ? 'K' : 'B'}$number';
      final isOpen = available.contains(id) || available.contains('$number');
      final isSelected = _selectedClientLayoutItem == id;
      final base = isSelected
          ? const Color(0xFF6D28D9)
          : (isOpen ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF));

      return InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: isOpen
            ? () => setState(() => _selectedClientLayoutItem = id)
            : null,
        child: SizedBox(
          width: 47,
          height: 54,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [base.withValues(alpha: .65), base],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? const [
                              Color(0xFF8B5CF6),
                              Color(0xFF6D28D9),
                            ]
                          : (isOpen
                              ? const [
                                  Color(0xFFEDE4FF),
                                  Color(0xFFC4B5FD),
                                ]
                              : const [
                                  Color(0xFFE5E7EB),
                                  Color(0xFFCBD5E1),
                                ]),
                    ),
                    border: Border.all(
                      color: base,
                      width: isSelected ? 2 : 1.2,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 3,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : (isOpen
                                ? const Color(0xFF581C87)
                                : const Color(0xFF6B7280)),
                      ),
                      Text(
                        id,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (isOpen
                                  ? const Color(0xFF581C87)
                                  : const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget boothRow(List<int> numbers) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final number in numbers)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: booth(number),
              ),
          ],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F5E9),
            Color(0xFFDCEFE0),
            Color(0xFFF3F4F6),
          ],
        ),
        border: Border.all(color: const Color(0xFFB7D9BE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFAFAFA), Color(0xFFE5E7EB)],
              ),
              border: Border.all(
                color: const Color(0xFF64748B),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(3, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PANGGUNG / AREA BELAKANG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 72,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFF94A3B8)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF64748B),
                        size: 24,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'AREA GEDUNG / RUANG BELAJAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    border: Border.all(color: const Color(0xFF94A3B8)),
                  ),
                  child: const Text(
                    'LOBI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  for (var number = 19; number <= 22; number++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: booth(number),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    boothRow([9, 10, 11]),
                    Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD6E8F9), Color(0xFFB7D5F0)],
                        ),
                        border: Border.all(color: const Color(0xFF8AAFCF)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'JALUR UTAMA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF315C80),
                        ),
                      ),
                    ),
                    boothRow([12, 13, 14]),
                  ],
                ),
              ),
              Column(
                children: [
                  for (var number = 1; number <= 2; number++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: booth(number),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _clientLivingTree(size: 30),
              booth(15),
              booth(16),
              booth(17),
              booth(18),
              _clientLivingTree(size: 34),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _clientLivingTree(size: 28),
              booth(8),
              booth(7),
              booth(6),
              _clientLivingTree(size: 28),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _clientLivingTree(size: 28),
              booth(5),
              booth(4),
              booth(3),
              _clientLivingTree(size: 28),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFD6E8F9),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF8AAFCF)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  size: 14,
                  color: Color(0xFF315C80),
                ),
                SizedBox(width: 5),
                Text(
                  'PINTU MASUK / JALUR PENGUNJUNG',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF315C80),
                  ),
                ),
              ],
            ),
          ),
          if (count > 22)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (var number = 23; number <= count; number++)
                    booth(number),
                ],
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            '🌳 Pohon taman   ·   Booth 3D   ·   Lorong pengunjung',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF47734D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientLivingTree({double size = 28}) {
    return SizedBox(
      width: size + 22,
      height: size * 1.48,
      child: CustomPaint(
        painter: _ClientRealisticTree3DPainter(),
        isComplex: true,
        willChange: false,
      ),
    );
  }

  Widget _buildClientSeatMap(int count, Set<String> available, String itemLabel) {
    Widget seat(int number) {
      if (number > count) return const SizedBox.shrink();
      final id = '${itemLabel == 'seat' ? 'K' : 'K'}$number';
      final isOpen = available.contains(id) || available.contains('$number');
      final isSelected = _selectedClientLayoutItem == id;
      final fill = isSelected ? const Color(0xFF7C3AED)
          : (isOpen ? const Color(0xFFEDE4FF) : const Color(0xFFE5E7EB));
      return InkWell(
        onTap: isOpen ? () => setState(() => _selectedClientLayoutItem = id) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 49,
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF581C87)
              : (isOpen ? const Color(0xFF8B5CF6) : const Color(0xFF9CA3AF)),
              width: isSelected ? 2 : 1.2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.event_seat_rounded, size: 16, color: isSelected ? Colors.white
              : (isOpen ? const Color(0xFF581C87) : Colors.grey)),
            Text(id, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : (isOpen ? const Color(0xFF581C87) : Colors.grey.shade700))),
            Text(isOpen ? 'Tersedia' : 'Ditutup',
              style: TextStyle(fontSize: 7, color: isSelected ? Colors.white : Colors.grey.shade700)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDCCBFF))),
      child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF581C87), borderRadius: BorderRadius.circular(9)),
          child: const Text('PANGGUNG / AREA DEPAN', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: List.generate(10, (rowIndex) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: List.generate(5, (columnIndex) {
              final number = rowIndex * 10 + columnIndex + 1;
              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                child: seat(number)));
            })),
          )))),
          Container(width: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(children: [for (var i=0; i<10; i++)
              Container(height: 49, margin: const EdgeInsets.only(bottom: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE7DDF8), borderRadius: BorderRadius.circular(5)),
                child: const Icon(Icons.more_vert, size: 13, color: Color(0xFF581C87)))])),
          Expanded(child: Column(children: List.generate(10, (rowIndex) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: List.generate(5, (columnIndex) {
              final number = rowIndex * 10 + columnIndex + 6;
              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                child: seat(number)));
            })),
          )))),
        ]),
        const SizedBox(height: 4),
        const Text('LORONG TENGAH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
          color: Color(0xFF581C87), letterSpacing: 1)),
      ]),
    );
  }

  Widget _buildClientEventLocationMap(Map<String, dynamic> event, String location) {
    final rawConfig = event['layout_config'];
    final config = rawConfig is Map ? Map<String, dynamic>.from(rawConfig) : <String, dynamic>{};
    final rawMap = config['map_location'];
    final mapData = rawMap is Map ? Map<String, dynamic>.from(rawMap) : <String, dynamic>{};
    final lat = double.tryParse((mapData['latitude'] ?? '').toString());
    final lng = double.tryParse((mapData['longitude'] ?? '').toString());
    final hasCoordinates = lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x338B5CF6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.map_outlined, color: Color(0xFF8050F6)),
          const SizedBox(width: 8),
          Expanded(child: Text('Lokasi Event', style: TextStyle(fontWeight: FontWeight.w800,
            color: _isDarkMode ? Colors.white : const Color(0xFF2E1065)))),
          SegmentedButton<gmap.MapType>(
            segments: const [
              ButtonSegment(value: gmap.MapType.normal, label: Text('Normal'), icon: Icon(Icons.map_outlined)),
              ButtonSegment(value: gmap.MapType.satellite, label: Text('Satelit'), icon: Icon(Icons.satellite_alt_outlined)),
            ],
            selected: {_clientEventMapType},
            onSelectionChanged: (value) => setState(() => _clientEventMapType = value.first),
            showSelectedIcon: false,
          ),
        ]),
        const SizedBox(height: 8),
        Text(location.isEmpty ? 'Alamat belum diisi organizer.' : location,
          style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 10),
        if (hasCoordinates)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 260,
              child: gmap.GoogleMap(
                key: ValueKey('${event['id']}_${lat}_$lng'),
                initialCameraPosition: gmap.CameraPosition(
                  target: gmap.LatLng(lat, lng), zoom: 16),
                mapType: _clientEventMapType,
                markers: {
                  gmap.Marker(
                    markerId: const gmap.MarkerId('client_event_location'),
                    position: gmap.LatLng(lat, lng),
                    infoWindow: gmap.InfoWindow(
                      title: (event['event_name'] ?? 'Lokasi Event').toString(),
                      snippet: location,
                    ),
                  ),
                },
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                compassEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
              ),
            ),
          )
        else
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDCCBFF))),
            child: const Text(
              'Titik peta belum tersimpan untuk event ini. Organizer perlu menyimpan ulang lokasi melalui peta agar titik yang sama muncul di client.',
              style: TextStyle(fontSize: 11, color: Color(0xFF777493), height: 1.4),
            ),
          ),
      ]),
    );
  }

  Widget _clientInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF8050F6), size: 19),
        const SizedBox(width: 10),
        SizedBox(width: 88, child: Text(title, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.black54))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isDarkMode ? Colors.white : const Color(0xFF31234A)))),
      ]),
    );
  }

  Widget _clientLegend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 11, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.black12))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.white70 : Colors.black54)),
    ]);
  }

  Widget _clientEmptyCard(String title, String message) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x338B5CF6))), child: Column(children: [const Icon(Icons.event_busy_outlined, size: 34, color: Color(0xFF8B5CF6)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey))]));
  }

  Widget _buildClientOrdersPage() {
    return Container(
      color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pesanan Saya', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _isDarkMode ? Colors.white : const Color(0xFF2E1065))),
          const SizedBox(height: 5),
          Text('Pantau status pemesanan, jadwal, lokasi, dan denah booth atau kursi kamu.', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 22),
          _clientEmptyCard(
            'Belum ada pesanan',
            'Event yang sudah kamu pesan akan muncul di sini, lengkap dengan poster, jadwal, lokasi, nomor booth/kursi, denah, dan status pembayaran.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentIndex = 0),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Lihat Event di Dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6D28D9),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Catatan: halaman ini sudah disiapkan dari sisi tampilan. Penyimpanan pesanan dan verifikasi pembayaran perlu disambungkan ke tabel booking/payment yang sesuai dengan database proyek.',
            style: TextStyle(fontSize: 11, height: 1.45, color: _isDarkMode ? Colors.white54 : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(bool isDesktop) {
    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E293B);
    final Color cardColor = _isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: isDesktop ? 340 : 200,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _bannerController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                            itemCount: _visibleHeroBannerCount,
                            itemBuilder: (context, index) {
                              final isUploadedHero = _heroBannerUrls.isNotEmpty;
                              final heroImage = isUploadedHero
                                  ? _heroBannerUrls[index]
                                  : _bannerImages[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: const Color(0xFF060409),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      isUploadedHero
                                          ? Image.network(
                                              heroImage,
                                              fit: BoxFit.cover,
                                              cacheWidth: 1800,
                                              filterQuality: FilterQuality.low,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                final total = progress.expectedTotalBytes;
                                                final loaded = progress.cumulativeBytesLoaded;
                                                return Container(
                                                  color: const Color(0xFFEEE7F8),
                                                  alignment: Alignment.center,
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(
                                                        width: 25,
                                                        height: 25,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Color(0xFF8050F6),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 9),
                                                      Text(
                                                        total == null
                                                            ? 'Memuat banner...'
                                                            : 'Memuat ${(loaded / total * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                                        style: const TextStyle(
                                                          color: Color(0xFF581C87),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const ColoredBox(
                                                color: Color(0xFF8B5CF6),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Colors.white,
                                                    size: 34,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Image.asset(
                                              heroImage,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: const Color(0xFF8B5CF6),
                                                  child: Center(
                                                    child: Text(
                                                      'Banner tidak ditemukan:\n$heroImage',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.85),
                                              Colors.black.withOpacity(0.55),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(28.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'EXPO & MARKETPLACE 2026',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5CF6),
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'Pameran Wirausaha &\nInovasi UKM Mahasiswa',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (_currentBannerIndex < _visibleHeroBannerCount - 1) {
                                    _bannerController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  } else {
                                    _bannerController.animateToPage(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF8B5CF6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_visibleHeroBannerCount, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBannerIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentBannerIndex == index
                                ? const Color(0xFF8B5CF6)
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jelajahi Booth & Inovasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() { _selectedTabFilter = 0; _currentPosterIndex = 0; });
                            if (_posterController.hasClients) _posterController.jumpToPage(0);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booth Wirausaha Unggulan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabFilter == 0
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedTabFilter == 0)
                                Container(
                                  width: 40,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        GestureDetector(
                          onTap: () {
                            setState(() { _selectedTabFilter = 1; _currentPosterIndex = 0; });
                            if (_posterController.hasClients) _posterController.jumpToPage(0);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UKM & Startup Mahasiswa',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabFilter == 1
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedTabFilter == 1)
                                Container(
                                  width: 40,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: isDesktop ? 500 : 540,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _posterController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPosterIndex = index;
                        });
                      },
                      itemCount: _visiblePosterCount,
                      itemBuilder: (context, index) {
                        bool isCurrentActive = _currentPosterIndex == index;
                        final uploadedEvents = _filteredUploadedEvents;
                        final hasUploadedEvents = uploadedEvents.isNotEmpty;
                        final event = hasUploadedEvents ? uploadedEvents[index] : null;
                        final posterUrl = (event?['poster_url'] ?? '').toString();
                        final showEmptyCategory = _uploadedEvents.isNotEmpty && uploadedEvents.isEmpty;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: isCurrentActive ? 0 : 16,
                          ),
                          child: GestureDetector(
                            onTap: event == null ? null : () => _openClientEventDetail(event),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                            child: showEmptyCategory
                                ? Container(
                                    color: const Color(0xFFF7F3FF),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.photo_library_outlined, size: 48, color: Color(0xFF8B5CF6)),
                                            const SizedBox(height: 12),
                                            Text(
                                              _selectedTabFilter == 0
                                                  ? 'Belum ada poster Booth Wirausaha Unggulan'
                                                  : 'Belum ada poster UKM & Startup Mahasiswa',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Color(0xFF6D5A91), fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : hasUploadedEvents
                                ? Image.network(
                                    posterUrl,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    cacheWidth: 1000,
                                    filterQuality: FilterQuality.low,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Color(0xFF8050F6),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Memuat poster...',
                                              style: TextStyle(
                                                color: Color(0xFF777493),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Text('Poster tidak dapat dimuat')),
                                  )
                                : Image.asset(
                                    _posterImages[index],
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Text('Poster demo tidak ditemukan')),
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: isDesktop ? 24 : 4,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPosterIndex > 0) {
                            _posterController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _posterController.animateToPage(
                              _visiblePosterCount - 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: isDesktop ? 24 : 4,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPosterIndex < _visiblePosterCount - 1) {
                            _posterController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _posterController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promo Spesial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 360,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _boothList.length,
                  itemBuilder: (context, index) {
                    final booth = _boothList[index];
                    final String badgeText = booth['badge'] ?? '';

                    return Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    height: 170,
                                    color: Colors.transparent,
                                    child:
                                        (booth['image'] != null &&
                                            (booth['image'] as String)
                                                .isNotEmpty)
                                        ? (booth['isNetwork'] == true
                                              ? Image.network(
                                                  booth['image'].toString(),
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 700,
                                                  filterQuality: FilterQuality.low,
                                                  loadingBuilder: (context, child, progress) {
                                                    if (progress == null) return child;
                                                    return const Center(
                                                      child: SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(0xFF8050F6),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Center(
                                                        child: Icon(
                                                          Icons.storefront,
                                                          color: Color(
                                                            0xFF8B5CF6,
                                                          ),
                                                          size: 40,
                                                        ),
                                                      ),
                                                )
                                              : Image.asset(
                                                  booth['image'].toString(),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Center(
                                                        child: Icon(
                                                          Icons.storefront,
                                                          color: Color(
                                                            0xFF8B5CF6,
                                                          ),
                                                          size: 40,
                                                        ),
                                                      ),
                                                ))
                                        : const Center(
                                            child: Icon(
                                              Icons.storefront,
                                              color: Color(0xFF8B5CF6),
                                              size: 40,
                                            ),
                                          ),
                                  ),
                                ),
                                if (badgeText.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              booth['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booth['owner'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booth['price'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF8B5CF6),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {},
                                  child: const Center(
                                    child: Text(
                                      'Kunjungi Booth',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                        child: Container(
                          width: 650,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(150),
                            color: Color(0xFF8B5CF6)
                                .withOpacity(_isDarkMode ? 0.22 : 0.12),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                        child: Container(
                          width: 350,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Color(0xFF8B5CF6)
                                .withOpacity(_isDarkMode ? 0.18 : 0.08),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 50,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Lihat Lainnya',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gabung Membership',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMembershipTabItem('Kumpulkan Koin', 0),
                                const SizedBox(width: 20),
                                _buildMembershipTabItem('Penawaran Tiket', 1),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: const [
                                      Color(0xFF3B82F6),
                                      Color(0xFF8B5CF6),
                                      Color(0xFFFFFFFF),
                                      Color(0xFF8B5CF6),
                                      Color(0xFF3B82F6),
                                    ],
                                    stops: [
                                      0.0,
                                      _shimmerController.value - 0.3,
                                      _shimmerController.value,
                                      _shimmerController.value + 0.3,
                                      1.0,
                                    ].map((s) => s.clamp(0.0, 1.0)).toList(),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'VOCA-TECHXPO',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'EVENT WIRAUSAHA MAHASISWA MARKETPLACE BOOTH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dapatkan poin lebih banyak dengan melakukan transaksi di booth pameran.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8B5CF6),
                                  side: const BorderSide(
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Pelajari Lebih Lanjut',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipTabItem(String title, int index) {
    bool isSelected = _membershipTab == index;
    return GestureDetector(
      onTap: () => setState(() => _membershipTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  void _openBoothFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BoothOnboardingScreen()),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final bool isDark = _isDarkMode;
    final Color bgColor = isDark
        ? const Color(0xFF081225)
        : const Color(0xFFF8FAFF);
    final Color cardColor = isDark ? const Color(0xFF17263B) : Colors.white;
    final Color textColor = isDark
        ? const Color(0xFFF8FAFF)
        : const Color(0xFF111B45);
    final Color subTextColor = isDark
        ? const Color(0xFFB8C5DB)
        : const Color(0xFF727D9B);
    final Color borderColor = isDark
        ? const Color(0xFF34445F)
        : const Color(0xFFE5E4FA);
    final Color purple = const Color(0xFF8B5CF6);

    return Container(
      color: bgColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Header profil dengan tombol kembali seperti referensi.
              Row(
                children: [
                  Material(
                    color: isDark
                        ? const Color(0xFF17243B)
                        : Colors.white.withOpacity(0.9),
                    shape: CircleBorder(
                      side: BorderSide(color: borderColor, width: 1.2),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _currentIndex = 0),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF4C1D95),
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: purple.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 43,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelompok 5 - Voca-techXpo',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'marketplace_booth@voca-techxpo.ac.id',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Dompet Saya
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildProfileSectionHeader(
                      'Dompet Saya',
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWalletCard(
                            'Dana',
                            'Rp 0',
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF3478FF),
                            cardColor,
                            textColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _buildWalletCard(
                            'Koin VocaTech',
                            '0 Koin',
                            Icons.monetization_on_rounded,
                            const Color(0xFFFFB52E),
                            cardColor,
                            textColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _buildWalletCard(
                            'Voucher Saya',
                            '0 Voucher',
                            Icons.confirmation_num_rounded,
                            const Color(0xFFEC64C8),
                            cardColor,
                            textColor,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Keuangan / Vpaylater dengan gradien ungu.
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildProfileSectionHeader(
                      'Keuangan',
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {},
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF7C35E8),
                                      Color(0xFF5528B8),
                                      Color(0xFF34269A),
                                    ]
                                  : const [
                                      Color(0xFFF5EDFF),
                                      Color(0xFFE8D9FF),
                                      Color(0xFFDCCBFF),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isDark
                                  ? Color(0xFF9A79FF).withOpacity(0.8)
                                  : const Color(0xFFDCCBFF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? const Color(0xFF7C3AED)
                                            : const Color(0xFFB89AFF))
                                        .withOpacity(isDark ? 0.25 : 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 15,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFF5E9FF),
                                            Color(0xFFBCA4FF),
                                            Color(0xFF8B5CF6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.65),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 31,
                                        color: Color(0xFF5723B8),
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vpaylater',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF682BC7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Cicilan Pasti 0% + Diskon Khusus untuk Organizer',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.35,
                                              color: isDark
                                                  ? Colors.white.withOpacity(
                                                      0.88,
                                                    )
                                                  : const Color(0xFF8172A8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFFD8CCFF),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Aktivitas Saya
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildProfileSectionHeader(
                      'Aktivitas Saya',
                      textColor,
                      subTextColor,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                      children: [
                        _buildActivityCard(
                          'Buka Booth Anda',
                          'Mulai berjualan dan perkenalkan event Anda',
                          Icons.storefront_rounded,
                          const Color(0xFFC084FC),
                          cardColor,
                          textColor,
                          isDark: isDark,
                          onTap: _openBoothFlow,
                        ),
                        _buildActivityCard(
                          'Favorit Saya',
                          '',
                          Icons.favorite_rounded,
                          const Color(0xFFFF4FA3),
                          cardColor,
                          textColor,
                          isDark: isDark,
                        ),
                        _buildActivityCard(
                          'VocaTechVIP',
                          '',
                          Icons.workspace_premium_rounded,
                          const Color(0xFFFFC857),
                          cardColor,
                          textColor,
                          isDark: isDark,
                        ),
                        _buildActivityCard(
                          'Terakhir Dilihat',
                          '',
                          Icons.history_rounded,
                          const Color(0xFF9B7CFF),
                          cardColor,
                          textColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pilihan tema
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildPreferenceIcon(
                      Icons.palette_rounded,
                      const Color(0xFF9B5CFF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your mode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Change the colors that appear in apps',
                            style: TextStyle(fontSize: 10, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2B43)
                            : const Color(0xFFFAF9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          value: _isDarkMode,
                          isDense: true,
                          dropdownColor: cardColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: subTextColor,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: false,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 16,
                                    color: Color(0xFFFFB020),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Light',
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.nightlight_round,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFFE0D7FF)
                                        : const Color(0xFF5B6478),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dark',
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _isDarkMode = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Pilihan font
              _buildProfilePanel(
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildPreferenceIcon(
                      Icons.text_fields_rounded,
                      const Color(0xFFB084FF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your available font',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Set the font style in the application',
                            style: TextStyle(fontSize: 10, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2B43)
                            : const Color(0xFFFAF9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFont,
                          isDense: true,
                          dropdownColor: cardColor,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: subTextColor,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ppins',
                              child: Text('Poppins'),
                            ),
                            DropdownMenuItem(
                              value: 'geist',
                              child: Text('Geist'),
                            ),
                            DropdownMenuItem(
                              value: 'outfit',
                              child: Text('Outfit'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedFont = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tombol keluar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF343F),
                    backgroundColor: isDark
                        ? Color(0xFF200F20).withOpacity(0.35)
                        : const Color(0xFFFFF7F7),
                    side: const BorderSide(
                      color: Color(0xFFFF343F),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text(
                    'Keluar (Log Out)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePanel({
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(10),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: borderColor.withOpacity(isDark ? 0.95 : 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileSectionHeader(
    String title,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 11,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded, size: 17, color: subTextColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildWalletCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor, {
    bool isDark = false,
  }) {
    final Color borderColor = isDark
        ? const Color(0xFF3A4A64)
        : const Color(0xFFE8E6FA);

    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xFF223149).withOpacity(0.88)
            : const Color(0xFFFCFBFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.95),
                      iconColor,
                      Color.lerp(iconColor, Colors.black, 0.12)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    title == 'Koin VocaTech' ? 50 : 9,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: title == 'Koin VocaTech' ? 24 : 22,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: isDark
                    ? const Color(0xFF9CAED0)
                    : const Color(0xFF8791B0),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: title == 'Koin VocaTech'
                  ? const Color(0xFFFFBE45)
                  : const Color(0xFFB17BFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor, {
    bool isDark = false,
    VoidCallback? onTap,
  }) {
    final Color borderColor = isDark
        ? const Color(0xFF3A4A64)
        : const Color(0xFFE8E6FA);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Color(0xFF223149).withOpacity(0.88)
              : const Color(0xFFFCFBFF),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(Colors.white, iconColor, isDark ? 0.22 : 0.12)!,
                    Color.lerp(
                      iconColor,
                      isDark ? const Color(0xFF18263D) : Colors.white,
                      0.62,
                    )!,
                    iconColor.withOpacity(isDark ? 0.18 : 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: iconColor.withOpacity(isDark ? 0.28 : 0.20),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(isDark ? 0.14 : 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  const BoxShadow(
                    color: Colors.white12,
                    blurRadius: 1,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: iconColor.withOpacity(0.18), size: 31),
                  Transform.translate(
                    offset: const Offset(-0.8, -1.1),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 27,
                      shadows: [
                        Shadow(
                          color: iconColor.withOpacity(0.42),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                        const Shadow(
                          color: Colors.white30,
                          blurRadius: 1,
                          offset: Offset(-1, -1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: textColor,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.25,
                        color: isDark
                            ? const Color(0xFFB8C5DB)
                            : const Color(0xFF7A84A2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: isDark ? const Color(0xFF9CAED0) : const Color(0xFF8791B0),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 5. DASHBOARD SCREEN ORGANIZER ====================
// Dashboard Organizer terpisah dari Dashboard Client.
// Role akun dibaca dari public.profiles pada proses login.

class _ClientRealisticTree3DPainter extends CustomPainter {
  final Paint _paint = Paint()..isAntiAlias = true;

  void _ellipse(
    Canvas canvas,
    Rect rect,
    List<Color> colors, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    double radius = 0,
  }) {
    _paint
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(rect, _paint);
    _paint.shader = null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bayangan pohon di permukaan tanah.
    _paint
      ..shader = const RadialGradient(
        colors: [Color(0x55321F12), Color(0x22321F12), Color(0x00321F12)],
      ).createShader(Rect.fromCenter(
        center: Offset(w * .52, h * .91),
        width: w * .98,
        height: h * .22,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .52, h * .91),
        width: w * .98,
        height: h * .22,
      ),
      _paint,
    );
    _paint.shader = null;

    // Batang pohon: sedikit miring agar tidak terlihat seperti ikon datar.
    final trunk = ui.Path()
      ..moveTo(w * .43, h * .88)
      ..quadraticBezierTo(w * .47, h * .72, w * .46, h * .52)
      ..lineTo(w * .60, h * .52)
      ..quadraticBezierTo(w * .55, h * .72, w * .66, h * .89)
      ..close();

    _paint
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF603719),
          Color(0xFF9A5B2B),
          Color(0xFFC18445),
          Color(0xFF75431F),
        ],
        stops: [0, .28, .58, 1],
      ).createShader(Rect.fromLTWH(w * .4, h * .5, w * .3, h * .4));
    canvas.drawPath(trunk, _paint);
    _paint.shader = null;

    // Garis tekstur kulit batang.
    final bark = Paint()
      ..color = const Color(0x8870442A)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * .49, h * .61), Offset(w * .48, h * .82), bark);
    canvas.drawLine(Offset(w * .56, h * .58), Offset(w * .59, h * .84), bark);
    canvas.drawLine(Offset(w * .53, h * .69), Offset(w * .55, h * .75), bark);

    // Cabang yang tampak di sela tajuk.
    final branches = Paint()
      ..color = const Color(0xFF75451F)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .52, h * .57), Offset(w * .29, h * .35), branches);
    canvas.drawLine(Offset(w * .53, h * .54), Offset(w * .76, h * .31), branches);
    canvas.drawLine(Offset(w * .51, h * .49), Offset(w * .49, h * .27), branches);

    // Lapisan tajuk bagian belakang untuk memberi volume.
    _ellipse(canvas, Rect.fromLTWH(w * .10, h * .12, w * .48, h * .43),
        const [Color(0xFF7CCB68), Color(0xFF237B35)]);
    _ellipse(canvas, Rect.fromLTWH(w * .40, h * .04, w * .48, h * .48),
        const [Color(0xFF8ED875), Color(0xFF267D36)]);
    _ellipse(canvas, Rect.fromLTWH(w * .22, h * .00, w * .55, h * .48),
        const [Color(0xFF9BE17D), Color(0xFF348C3D)]);

    // Gumpalan daun depan dengan gradasi gelap-terang.
    _ellipse(canvas, Rect.fromLTWH(w * .02, h * .27, w * .48, h * .34),
        const [Color(0xFF65B94F), Color(0xFF176B2D)]);
    _ellipse(canvas, Rect.fromLTWH(w * .47, h * .24, w * .49, h * .37),
        const [Color(0xFF62B84D), Color(0xFF155F2A)]);
    _ellipse(canvas, Rect.fromLTWH(w * .20, h * .20, w * .60, h * .43),
        const [Color(0xFF78CA5D), Color(0xFF1D7832)]);

    // Sorotan daun di sisi yang terkena cahaya.
    _ellipse(canvas, Rect.fromLTWH(w * .20, h * .12, w * .25, h * .15),
        const [Color(0xCCB7F28D), Color(0x0079C65B)]);
    _ellipse(canvas, Rect.fromLTWH(w * .55, h * .16, w * .20, h * .13),
        const [Color(0xAA9FE477), Color(0x0079C65B)]);

    // Daun-daun kecil sebagai tekstur tajuk, bukan lingkaran tunggal.
    final leafPaint = Paint()..isAntiAlias = true;
    final leaves = <(double, double, double, Color)>[
      (.20, .34, .055, Color(0xFFB2E982)),
      (.31, .24, .045, Color(0xFFC1F095)),
      (.43, .31, .050, Color(0xFF9BDD70)),
      (.62, .25, .050, Color(0xFFB1E985)),
      (.76, .36, .045, Color(0xFF8ED36A)),
      (.18, .47, .045, Color(0xFF8BD366)),
      (.39, .48, .050, Color(0xFF9FE078)),
      (.59, .45, .045, Color(0xFF8BD166)),
      (.79, .48, .050, Color(0xFF78C65A)),
    ];
    for (final leaf in leaves) {
      leafPaint.color = leaf.$4;
      canvas.save();
      canvas.translate(w * leaf.$1, h * leaf.$2);
      canvas.rotate(-.55);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * leaf.$3 * 1.8,
          height: w * leaf.$3,
        ),
        leafPaint,
      );
      canvas.restore();
    }

    // Kontur bayangan bawah tajuk untuk efek volume 3D.
    _paint
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00104420), Color(0x66345F27)],
      ).createShader(Rect.fromLTWH(w * .12, h * .40, w * .78, h * .20));
    canvas.drawOval(Rect.fromLTWH(w * .12, h * .43, w * .78, h * .17), _paint);
    _paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
