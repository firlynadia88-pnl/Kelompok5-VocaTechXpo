import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/realistic_tree_3d_painter.dart';

// ==================== PRODUK SAYA: EVENT & BANNER ====================
class OrganizerProductsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OrganizerProductsScreen({super.key, this.onBack});

  @override
  State<OrganizerProductsScreen> createState() =>
      _OrganizerProductsScreenState();
}

class _OrganizerProductsScreenState extends State<OrganizerProductsScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8050F6);
  final _eventFormKey = GlobalKey<FormState>();
  final _eventName = TextEditingController();
  final _eventCategory = TextEditingController();
  final _eventDate = TextEditingController();
  final _boothCount = TextEditingController();
  final _eventLocation = TextEditingController();
  final _eventPrice = TextEditingController();
  final _eventDescription = TextEditingController();
  final _bannerTitle = TextEditingController();
  String? _selectedPromotionUkm;
  String _selectedDisplaySection = 'ukm_startup';
  String _priceMode = 'paid'; // paid | free
  String? _selectedEventUkm;
  final Set<int> _availableLayoutItems = <int>{};
  bool _layoutInitialized = false;

  static const List<String> _eventCategoryOptions = [
    'Bazar',
    'Teknologi',
    'Pameran',
    'Kuliner',
    'Musik',
    'Teater',
    'Seminar',
  ];
  static const List<String> _eventUkmOptions = [
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

  static const Map<String, String> _displaySectionOptions = {
    'ukm_startup': 'UKM & Startup Mahasiswa',
    'unggulan': 'Booth Wirausaha Unggulan',
  };

  PlatformFile? _posterFile;
  PlatformFile? _bannerFile;
  PlatformFile? _heroBannerFile;
  bool _savingEvent = false;
  bool _savingBanner = false;
  bool _savingHeroBanner = false;
  bool _gettingLocation = false;
  gmap.LatLng? _eventLatLng = const gmap.LatLng(5.1801, 97.1507);
  gmap.GoogleMapController? _eventMapController;
  // Mode satelit memakai Hybrid agar citra satelit tetap menampilkan label lokasi.
  gmap.MapType _selectedMapType = gmap.MapType.normal;
  bool _loading = true;
  List<Map<String, dynamic>> _promotions = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _eventName.dispose();
    _eventCategory.dispose();
    _eventDate.dispose();
    _boothCount.dispose();
    _eventLocation.dispose();
    _eventPrice.dispose();
    _eventDescription.dispose();
    _bannerTitle.dispose();
    _eventMapController?.dispose();
    super.dispose();
  }

  // --- GLASS DIALOG UNTUK KATEGORI TAMPILAN POSTER ---
  Future<String?> _showGlassDisplaySectionPicker({
    required String selectedValue,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x66080016),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x991B102B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0x887F55D9),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0x337F50F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x667F50F6),
                              ),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: Color(0xFFC9B5FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Kategori Tampilan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Tentukan lokasi poster ditampilkan',
                                  style: TextStyle(
                                    color: Color(0xFFC7BCD9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFFD8C9F5),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0x557F50F6)),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _displaySectionOptions.entries.map((entry) {
                          final selected = entry.key == selectedValue;
                          return Material(
                            color: selected
                                ? const Color(0x667F50F6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(entry.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 15,
                                ),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xCCB79AFF)
                                        : const Color(0x227F50F6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 19,
                                      color: selected
                                          ? const Color(0xFFD4C3FF)
                                          : const Color(0xFFB7A4D7),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.96),
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFFD4C3FF),
                                        size: 19,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.blur_on_rounded,
                            color: Color(0xFFBFA9F4),
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'GLASS • VOCA-TECHXPO',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // Picker transparan + blur yang dipakai untuk kategori dan pilihan harga.
  Future<String?> _showGlassOptionPicker({
    required String title,
    required String subtitle,
    required List<String> options,
    required String selectedValue,
    required IconData icon,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x66080016),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE61B102B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x997F55D9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
                    child: Row(
                      children: [
                        Icon(icon, color: const Color(0xFFC9B5FF), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              )),
                              const SizedBox(height: 3),
                              Text(subtitle, style: const TextStyle(
                                color: Color(0xFFC7BCD9), fontSize: 11,
                              )),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x557F50F6)),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(10),
                      children: options.map((option) {
                        final selected = option == selectedValue;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Material(
                            color: selected
                                ? const Color(0x667F50F6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(13),
                              onTap: () => Navigator.pop(dialogContext, option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xCCB79AFF)
                                        : const Color(0x337F50F6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: const Color(0xFFD4C3FF),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(option, style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      )),
                                    ),
                                    if (selected)
                                      const Icon(Icons.check_rounded,
                                        color: Color(0xFFD4C3FF), size: 19),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Text('GLASS • VOCA-TECHXPO',
                      style: TextStyle(
                        color: Color(0x99D8C9F5),
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- GLASS DIALOG UNTUK UKM / ORGANISASI ---
  Future<String?> _showGlassUkmPicker({String? selectedValue}) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x66080016),
      builder: (dialogContext) {
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.78),
                decoration: BoxDecoration(
                  color: const Color(0x991B102B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0x887F55D9),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0x337F50F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x667F50F6),
                              ),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFFC9B5FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih UKM / Organisasi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Pilih kategori pemilik booth',
                                  style: TextStyle(
                                    color: Color(0xFFC7BCD9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFFD8C9F5),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0x557F50F6),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(10),
                        itemCount: _eventUkmOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final ukm = _eventUkmOptions[index];
                          final selected = ukm == selectedValue;
                          return Material(
                            color: selected
                                ? const Color(0x667F50F6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.of(dialogContext).pop(ukm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xCCB79AFF)
                                        : const Color(0x227F50F6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 19,
                                      color: selected
                                          ? const Color(0xFFD4C3FF)
                                          : const Color(0xFFB7A4D7),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ukm,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.96),
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFFD4C3FF),
                                        size: 19,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.blur_on_rounded,
                            color: Color(0xFFBFA9F4),
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'GLASS • VOCA-TECHXPO',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('promotions')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _promotions = (response as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<PlatformFile?> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;

    try {
      await file.readAsBytes();
      return file;
    } catch (e) {
      _showMessage(
        'File tidak dapat dibaca. Silakan pilih gambar lain.',
        isError: true,
      );
      return null;
    }
  }

  Future<String> _uploadImage(PlatformFile file, String folder) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Sesi login tidak ditemukan.');
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'jpg';
    final contentType = safeExt == 'png'
        ? 'image/png'
        : (safeExt == 'webp' ? 'image/webp' : 'image/jpeg');
    final path =
        '${user.id}/$folder/${DateTime.now().microsecondsSinceEpoch}.$safeExt';
    final fileBytes = await file.readAsBytes();
    await Supabase.instance.client.storage
        .from('voca-media')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return Supabase.instance.client.storage
        .from('voca-media')
        .getPublicUrl(path);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> _getCurrentEventLocation() async {
    if (_gettingLocation) return;

    setState(() => _gettingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage(
          'Layanan lokasi/GPS belum aktif. Aktifkan lokasi perangkat atau browser lalu coba lagi.',
          isError: true,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'Izin lokasi ditolak. Izinkan akses lokasi pada browser/perangkat atau isi alamat secara manual.',
          isError: true,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Izin lokasi diblokir. Buka pengaturan izin lokasi browser/perangkat dan izinkan akses lokasi.',
          isError: true,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final currentLatLng = gmap.LatLng(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _eventLatLng = currentLatLng;
        });
        _eventMapController?.animateCamera(
          gmap.CameraUpdate.newCameraPosition(
            gmap.CameraPosition(target: currentLatLng, zoom: 17),
          ),
        );
      }

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        <String, String>{
          'format': 'jsonv2',
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
          'accept-language': 'id',
        },
      );

      final response = await http.get(
        uri,
        headers: const <String, String>{'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Layanan pencarian alamat mengembalikan kode ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format alamat dari layanan peta tidak valid.');
      }

      final displayName = (decoded['display_name'] ?? '').toString().trim();
      final address = decoded['address'];
      var formattedAddress = displayName;

      if (address is Map<String, dynamic>) {
        final parts = <String?>[
          address['road']?.toString(),
          address['neighbourhood']?.toString(),
          address['suburb']?.toString(),
          address['village']?.toString(),
          address['town']?.toString(),
          address['city']?.toString(),
          address['county']?.toString(),
          address['state']?.toString(),
          address['postcode']?.toString(),
          address['country']?.toString(),
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .toSet()
            .toList();

        if (parts.isNotEmpty) {
          formattedAddress = parts.join(', ');
        }
      }

      if (!mounted) return;
      _eventLocation.text = formattedAddress.isNotEmpty
          ? formattedAddress
          : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      _showMessage(
        'Lokasi berhasil ditemukan. Periksa alamat sebelum menyimpan.',
      );
    } on Exception catch (e) {
      _showMessage(
        'Gagal mengambil alamat lokasi. Periksa izin lokasi dan koneksi internet, atau isi alamat secara manual. Detail: $e',
        isError: true,
      );
    } catch (e) {
      _showMessage(
        'Gagal mengambil lokasi. Pastikan izin browser aktif dan coba lagi. Detail: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  InputDecoration _decoration(String label, String hint, IconData icon) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE4D9FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE4D9FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      );

  Widget _imagePickerCard({
    required String title,
    required PlatformFile? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD8C9F8),
            style: BorderStyle.solid,
          ),
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 42,
                    color: Color(0xFFB4A3DD),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF35245D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih gambar dari perangkat',
                    style: TextStyle(fontSize: 12, color: Color(0xFF81769B)),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.upload_rounded, color: _accent),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 34,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    file.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF35245D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Klik untuk mengganti gambar',
                    style: TextStyle(fontSize: 12, color: Color(0xFF81769B)),
                  ),
                ],
              ),
      ),
    );
  }

  bool get _isSeatEvent {
    final category = _eventCategory.text.trim().toLowerCase();
    return category == 'musik' || category == 'teater' || category == 'seminar';
  }

  int get _currentLayoutCount {
    if (_isSeatEvent) return 100;
    final count = int.tryParse(_boothCount.text.trim());
    if (count == null || count < 1) return 20;
    return count > 200 ? 200 : count;
  }

  Widget _layoutItemTile(int number, bool isSeat) {
    final available = _availableLayoutItems.contains(number);
    return InkWell(
      borderRadius: BorderRadius.circular(isSeat ? 8 : 10),
      onTap: () => setState(() {
        if (available) {
          _availableLayoutItems.remove(number);
        } else {
          _availableLayoutItems.add(number);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 42),
        decoration: BoxDecoration(
          color: available ? const Color(0xFFEDE4FF) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(isSeat ? 8 : 10),
          border: Border.all(
            color: available ? _accent : const Color(0xFF9CA3AF),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSeat ? Icons.event_seat_rounded : Icons.storefront_rounded,
              size: isSeat ? 16 : 18,
              color: available ? _purple : const Color(0xFF8A8A95),
            ),
            const SizedBox(height: 2),
            Text(
              '${isSeat ? 'K' : 'B'}$number',
              style: TextStyle(
                fontSize: isSeat ? 9 : 10,
                fontWeight: FontWeight.w900,
                color: available ? _purple : const Color(0xFF777783),
              ),
            ),
            Text(
              available ? 'Tersedia' : 'Ditutup',
              style: TextStyle(
                fontSize: isSeat ? 7 : 8,
                color: available ? _purple : const Color(0xFF777783),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _booth3DTile(int number, int count) {
    if (number > count) return const SizedBox.shrink();
    final available = _availableLayoutItems.contains(number);
    final base = available ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF);
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: () => setState(() {
        if (available) {
          _availableLayoutItems.remove(number);
        } else {
          _availableLayoutItems.add(number);
        }
      }),
      child: SizedBox(
        width: 47,
        height: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [base.withValues(alpha: .65), base]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: available
                        ? const [Color(0xFFEDE4FF), Color(0xFFC4B5FD)]
                        : const [Color(0xFFE5E7EB), Color(0xFFCBD5E1)],
                  ),
                  border: Border.all(color: base, width: 1.2),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 3, offset: const Offset(2, 3)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_rounded, size: 16, color: available ? _purple : const Color(0xFF6B7280)),
                    Text('B$number', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: available ? _purple : const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _livingTree({double size = 28}) {
    return SizedBox(
      width: size + 22,
      height: size * 1.48,
      child: CustomPaint(
        painter: RealisticTree3DPainter(),
        isComplex: true,
        willChange: false,
      ),
    );
  }

  Widget _build3DBoothMap(int count) {
    Widget booth(int n) => _booth3DTile(n, count);
    Widget boothRow(List<int> numbers, {MainAxisAlignment alignment = MainAxisAlignment.center}) =>
        Row(mainAxisAlignment: alignment, children: [
          for (final n in numbers)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3), child: booth(n)),
        ]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFDCEFE0), Color(0xFFF3F4F6)]),
        border: Border.all(color: const Color(0xFFB7D9BE)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 7, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFAFAFA), Color(0xFFE5E7EB)]),
              border: Border.all(color: const Color(0xFF64748B), width: 1.5),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(3, 4))],
            ),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('PANGGUNG / AREA BELAKANG', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6)),
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
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.account_balance_rounded, color: Color(0xFF64748B), size: 24),
                  SizedBox(height: 3),
                  Text('AREA GEDUNG / RUANG BELAJAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                ]),
              ),
              const SizedBox(height: 5),
              Container(height: 27, alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), border: Border.all(color: const Color(0xFF94A3B8))),
                child: const Text('LOBI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Column(children: [for (var n = 19; n <= 22; n++) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: booth(n))]),
            Expanded(child: Column(children: [
              boothRow([9, 10, 11]),
              Container(height: 44, margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFD6E8F9), Color(0xFFB7D5F0)]),
                  border: Border.all(color: const Color(0xFF8AAFCF)), borderRadius: BorderRadius.circular(5)),
                alignment: Alignment.center,
                child: const Text('JALUR UTAMA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF315C80))),
              ),
              boothRow([12, 13, 14]),
            ])),
            Column(children: [for (var n = 1; n <= 2; n++) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: booth(n))]),
          ]),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
            _livingTree(size: 30), booth(15), booth(16), booth(17), booth(18), _livingTree(size: 34),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
            _livingTree(size: 28), booth(8), booth(7), booth(6), _livingTree(size: 28),
          ]),
          const SizedBox(height: 3),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
            _livingTree(size: 28), booth(5), booth(4), booth(3), _livingTree(size: 28),
          ]),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFD6E8F9), borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF8AAFCF)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.directions_walk_rounded, size: 14, color: Color(0xFF315C80)),
              SizedBox(width: 5),
              Text('PINTU MASUK / JALUR PENGUNJUNG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF315C80))),
            ]),
          ),
          const SizedBox(height: 4),
          if (count > 22)
            Wrap(alignment: WrapAlignment.center, spacing: 5, runSpacing: 5, children: [
              for (var n = 23; n <= count; n++) booth(n),
            ]),
          const SizedBox(height: 4),
          const Text('🌳 Pohon taman   ·   Booth 3D   ·   Lorong pengunjung',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Color(0xFF47734D), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildLayoutEditor() {
    final category = _eventCategory.text.trim();
    if (category.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCCBFF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.map_outlined, color: _accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pilih kategori event terlebih dahulu untuk menampilkan denah booth atau kursi.',
                style: TextStyle(color: Color(0xFF777493), height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final isSeat = _isSeatEvent;
    final count = _currentLayoutCount;
    if (!_layoutInitialized) {
      _availableLayoutItems
        ..clear()
        ..addAll(List<int>.generate(count, (i) => i + 1));
      _layoutInitialized = true;
    } else {
      _availableLayoutItems.removeWhere((item) => item > count);
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCCBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isSeat ? Icons.event_seat_rounded : Icons.storefront_rounded,
                color: _purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSeat ? 'Atur Denah Kursi' : 'Atur Denah Booth',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF35245D),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            isSeat
                ? 'Denah berisi 5 kursi pada setiap baris, 10 baris ke belakang di sisi kiri dan kanan, dengan lorong di tengah. Ketuk kursi untuk membuka/menutup penjualan.'
                : 'Atur booth untuk kategori $category. Booth yang ditutup tidak akan tersedia untuk dipilih client.',
            style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF777493)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isSeat ? 'PANGGUNG / AREA DEPAN' : 'PETA AREA EVENT · $category',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: .7,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isSeat) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: List.generate(10, (rowIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: List.generate(5, (columnIndex) {
                            final number = rowIndex * 10 + columnIndex + 1;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _layoutItemTile(number, true),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
                Container(
                  width: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < 10; i++)
                        Container(
                          height: 49,
                          margin: const EdgeInsets.only(bottom: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7DDF8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.more_vert, size: 13, color: _purple),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: List.generate(10, (rowIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: List.generate(5, (columnIndex) {
                            final number = rowIndex * 10 + columnIndex + 6;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _layoutItemTile(number, true),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'LORONG TENGAH',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _purple, letterSpacing: 1),
              ),
            ),
          ] else ...[
            _build3DBoothMap(count),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 14, runSpacing: 8, children: [
            _layoutLegend(const Color(0xFFEDE4FF), _accent, 'Tersedia untuk client'),
            _layoutLegend(const Color(0xFFE5E7EB), const Color(0xFF9CA3AF), 'Ditutup organizer'),
          ]),
          const SizedBox(height: 8),
          Text(
            '${_availableLayoutItems.length} dari $count ${isSeat ? 'kursi' : 'booth'} tersedia',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF35245D)),
          ),
        ],
      ),
    );
  }

  Widget _layoutLegend(Color fill, Color border, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: fill, border: Border.all(color: border), borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF777493))),
    ],
  );

  Future<void> _selectEventDate({TextEditingController? controller}) async {
    final targetController = controller ?? _eventDate;
    final initial = DateTime.tryParse(targetController.text.trim()) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Pelaksanaan',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      barrierDismissible: true,
      barrierColor: const Color(0x55080016),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9B76FF),
              onPrimary: Colors.white,
              secondary: Color(0xFFBFA8FF),
              onSecondary: Color(0xFF21163F),
              surface: Color(0xE61B102B),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xE61B102B),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xE61B102B),
              shadowColor: const Color(0x66080016),
              elevation: 24,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: const Color(0x557F50F6),
              headerForegroundColor: Colors.white,
              weekdayStyle: const TextStyle(color: Color(0xFFD7C9F4)),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                if (states.contains(WidgetState.disabled)) return const Color(0x667F7397);
                return const Color(0xFFF4EEFF);
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return const Color(0xFF8050F6);
                return Colors.transparent;
              }),
              todayForegroundColor: const WidgetStatePropertyAll(Color(0xFFD4C3FF)),
              todayBorder: const BorderSide(color: Color(0xFF9B76FF)),
              yearForegroundColor: const WidgetStatePropertyAll(Colors.white),
              yearBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
              dividerColor: const Color(0x557F50F6),
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFFC9B5FF)),
              confirmButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFFC9B5FF)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: child!,
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) {
      targetController.text = '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
      if (controller == null) setState(() {});
    }
  }

  Future<void> _saveEvent() async {
    if (_savingEvent || !_eventFormKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Silakan login kembali.', isError: true);
      return;
    }
    if (_posterFile == null) {
      _showMessage('Pilih poster event terlebih dahulu.', isError: true);
      return;
    }
    setState(() => _savingEvent = true);
    try {
      final posterUrl = await _uploadImage(_posterFile!, 'event-posters');
      await Supabase.instance.client.from('booth_events').insert({
        'owner_id': user.id,
        'event_name': _eventName.text.trim(),
        'category': _eventCategory.text.trim(),
        'event_date': _eventDate.text.trim(),
        'booth_count': _currentLayoutCount,
        'location': _eventLocation.text.trim(),
        'price': _priceMode == 'free' ? 'Gratis' : _eventPrice.text.trim(),
        'description': _eventDescription.text.trim(),
        'poster_url': posterUrl,
        'display_section': _selectedDisplaySection,
        'ukm_name': _selectedDisplaySection == 'unggulan' ? _selectedEventUkm : null,
        'layout_config': {
          'layout_type': _isSeatEvent ? 'seating' : 'booth',
          'item_count': _currentLayoutCount,
          'available_items': _availableLayoutItems.toList()..sort(),
          'item_label': _isSeatEvent ? 'seat' : 'booth',
          'configured_by_owner': true,
          // Koordinat peta yang dipilih Organizer ikut tersimpan pada event.
          'event_latitude': _eventLatLng?.latitude,
          'event_longitude': _eventLatLng?.longitude,
        },
        'status': 'pending',
      });
      _eventName.clear();
      _eventCategory.clear();
      _eventDate.clear();
      _boothCount.clear();
      _eventLocation.clear();
      _eventPrice.clear();
      _priceMode = 'paid';
      _eventDescription.clear();
      setState(() {
        _posterFile = null;
        _selectedDisplaySection = 'ukm_startup';
        _selectedEventUkm = null;
        _availableLayoutItems.clear();
        _layoutInitialized = false;
      });
      await _loadData();
      _showMessage(
        'Event berhasil diunggah dan sekarang tampil di Kelola Booth.',
      );
    } catch (e) {
      _showMessage('Gagal menyimpan event: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingEvent = false);
    }
  }

  Future<void> _editPromotion(Map<String, dynamic> promo) async {
    final id = promo['id'];
    if (id == null) {
      _showMessage('ID banner tidak ditemukan.', isError: true);
      return;
    }

    final titleController = TextEditingController(
      text: (promo['title'] ?? '').toString(),
    );
    PlatformFile? replacementFile;
    bool saving = false;

    try {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x66080016),
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xF21B102B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x997F50F6), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x44000000), blurRadius: 28, offset: Offset(0, 12)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Edit Banner Promosi', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 18),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Judul Banner',
                          labelStyle: const TextStyle(color: Color(0xFFD6C8F5)),
                          filled: true,
                          fillColor: const Color(0x331F1538),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x667F50F6))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9B76FF), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (replacementFile != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0x227F50F6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x667F50F6))),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFFC9B5FF)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(replacementFile!.name, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            IconButton(onPressed: () => setDialogState(() => replacementFile = null), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                          ]),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: saving ? null : () async {
                            final picked = await _pickImage();
                            if (picked != null) setDialogState(() => replacementFile = picked);
                          },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Ganti gambar banner (opsional)'),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD6C8F5), side: const BorderSide(color: Color(0x667F50F6)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD6C8F5), side: const BorderSide(color: Color(0x667F50F6))), child: const Text('Batal'))),
                        const SizedBox(width: 10),
                        Expanded(child: FilledButton.icon(
                          onPressed: saving ? null : () async {
                            if (titleController.text.trim().isEmpty) {
                              _showMessage('Judul banner wajib diisi.', isError: true);
                              return;
                            }
                            setDialogState(() => saving = true);
                            try {
                              final user = Supabase.instance.client.auth.currentUser;
                              if (user == null) throw Exception('Sesi login tidak ditemukan.');
                              final updates = <String, dynamic>{'title': titleController.text.trim()};
                              if (replacementFile != null) {
                                updates['banner_url'] = await _uploadImage(replacementFile!, 'promotional-banners');
                              }
                              await Supabase.instance.client.from('promotions').update(updates).eq('id', id).eq('owner_id', user.id);
                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                              await _loadData();
                              _showMessage('Banner promosi berhasil diperbarui.');
                            } catch (e) {
                              setDialogState(() => saving = false);
                              _showMessage('Gagal memperbarui banner: $e', isError: true);
                            }
                          },
                          icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                          label: Text(saving ? 'Menyimpan...' : 'Simpan'),
                          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      titleController.dispose();
    }
  }

  Future<void> _deletePromotion(Map<String, dynamic> promo) async {
    final id = promo['id'];
    if (id == null) {
      _showMessage('ID banner tidak ditemukan.', isError: true);
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x66080016),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xF21B102B),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x887F50F6))),
          title: const Text('Hapus Banner?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          content: Text('Banner "${promo['title'] ?? 'Promosi'}" akan dihapus dari daftar promosi Anda.', style: const TextStyle(color: Color(0xFFE8DFFF))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal', style: TextStyle(color: Color(0xFFC9B5FF)))),
            FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.delete_outline), label: const Text('Hapus')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Sesi login tidak ditemukan.');
      await Supabase.instance.client.from('promotions').delete().eq('id', id).eq('owner_id', user.id);
      await _loadData();
      _showMessage('Banner promosi berhasil dihapus.');
    } catch (e) {
      _showMessage('Gagal menghapus banner: $e', isError: true);
    }
  }

  Future<void> _saveHeroBanner() async {
    if (_savingHeroBanner) return;

    if (_heroBannerFile == null) {
      _showMessage('Pilih gambar banner utama terlebih dahulu.', isError: true);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Silakan login kembali.', isError: true);
      return;
    }

    setState(() => _savingHeroBanner = true);
    try {
      final imageUrl = await _uploadImage(
        _heroBannerFile!,
        'hero-banners',
      );

      await Supabase.instance.client.from('hero_banners').insert({
        'owner_id': user.id,
        'image_url': imageUrl,
        'is_active': true,
      });

      if (!mounted) return;
      setState(() => _heroBannerFile = null);
      _showMessage(
        'Banner utama berhasil dipublikasikan ke bagian paling atas Dashboard Client.',
      );
    } catch (e) {
      _showMessage('Gagal mengunggah banner utama: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingHeroBanner = false);
    }
  }

  Future<void> _saveBanner() async {
    if (_savingBanner) return;
    if (_bannerTitle.text.trim().isEmpty) {
      _showMessage('Masukkan judul banner.', isError: true);
      return;
    }
    if (_selectedPromotionUkm == null || _selectedPromotionUkm!.isEmpty) {
      _showMessage('Pilih UKM pemilik promosi terlebih dahulu.', isError: true);
      return;
    }
    if (_bannerFile == null) {
      _showMessage('Pilih banner promosi terlebih dahulu.', isError: true);
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Silakan login kembali.', isError: true);
      return;
    }
    setState(() => _savingBanner = true);
    try {
      final bannerUrl = await _uploadImage(_bannerFile!, 'promotional-banners');
      await Supabase.instance.client.from('promotions').insert({
        'owner_id': user.id,
        'title': _bannerTitle.text.trim(),
        'ukm': _selectedPromotionUkm,
        'banner_url': bannerUrl,
        'is_active': true,
      });
      _bannerTitle.clear();
      setState(() {
        _bannerFile = null;
        _selectedPromotionUkm = null;
      });
      await _loadData();
      _showMessage(
        'Banner berhasil diunggah dan akan tampil di Promosi Spesial client.',
      );
    } catch (e) {
      _showMessage('Gagal mengunggah banner: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('organizer-products-page'),
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E0F4), width: 1.2),
              ),
              child: IconButton(
                tooltip: 'Kembali',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF581C87), size: 23),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Produk Saya',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF21163F)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Buat dan unggah event di sini. Pengelolaan, pengeditan, dan penghapusan event tersedia di Kelola Booth.',
          style: TextStyle(color: Color(0xFF777493), height: 1.5),
        ),
        const SizedBox(height: 22),
        _sectionCard(
          title: 'Buat Event',
          subtitle:
              'Poster event yang diunggah akan tampil di halaman Kelola Booth.',
          icon: Icons.event_available_rounded,
          child: Form(
            key: _eventFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormField<String>(
                  initialValue: _selectedDisplaySection,
                  builder: (field) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final selected = await _showGlassDisplaySectionPicker(
                          selectedValue: _selectedDisplaySection,
                        );
                        if (selected == null || !mounted) return;
                        setState(() {
                          _selectedDisplaySection = selected;
                          if (selected != 'unggulan') _selectedEventUkm = null;
                        });
                        field.didChange(selected);
                      },
                      child: InputDecorator(
                        decoration: _decoration(
                          'Tampilkan Poster Pada Kategori',
                          'Pilih kategori poster',
                          Icons.category_outlined,
                        ),
                        isEmpty: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _displaySectionOptions[_selectedDisplaySection] ??
                                    'Pilih kategori poster',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF35245D),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF8050F6),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_selectedDisplaySection == 'unggulan') ...[
                  const SizedBox(height: 12),
                  FormField<String>(
                    initialValue: _selectedEventUkm,
                    validator: (value) =>
                        _selectedDisplaySection == 'unggulan' &&
                                (value == null || value.isEmpty)
                            ? 'Pilih UKM terlebih dahulu.'
                            : null,
                    builder: (field) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final selected = await _showGlassUkmPicker(selectedValue: _selectedEventUkm);
                          if (selected == null || !mounted) return;
                          setState(() => _selectedEventUkm = selected);
                          field.didChange(selected);
                        },
                        child: InputDecorator(
                          decoration: _decoration(
                            'Pilih UKM',
                            'Pilih UKM penanggung jawab',
                            Icons.groups_outlined,
                          ).copyWith(errorText: field.errorText),
                          isEmpty: false,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedEventUkm ?? 'Pilih UKM penanggung jawab',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedEventUkm == null
                                        ? const Color(0xFF8A849F)
                                        : const Color(0xFF35245D),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF8050F6),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _eventName,
                  decoration: _decoration(
                    'Nama Event',
                    'Contoh: Voca Tech Market',
                    Icons.event,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama event wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 600;
                    final fields = [
                      FormField<String>(
                        initialValue: _eventCategoryOptions.contains(_eventCategory.text)
                            ? _eventCategory.text
                            : null,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Pilih kategori event.'
                            : null,
                        builder: (field) => InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final value = await _showGlassOptionPicker(
                              title: 'Pilih Kategori Event',
                              subtitle: 'Tentukan jenis kegiatan yang diselenggarakan',
                              options: _eventCategoryOptions,
                              selectedValue: _eventCategory.text,
                              icon: Icons.category_outlined,
                            );
                            if (value == null || !mounted) return;
                            setState(() {
                              _eventCategory.text = value;
                              _boothCount.text =
                                  (value == 'Musik' || value == 'Teater' || value == 'Seminar')
                                      ? '100'
                                      : (_boothCount.text.trim().isEmpty ||
                                              _boothCount.text.trim() == '100'
                                          ? '20'
                                          : _boothCount.text.trim());
                              _availableLayoutItems.clear();
                              _layoutInitialized = false;
                            });
                            field.didChange(value);
                          },
                          child: InputDecorator(
                            decoration: _decoration(
                              'Kategori Event',
                              'Pilih kategori event',
                              Icons.category_outlined,
                            ).copyWith(
                              errorText: field.errorText,
                              // Kosongkan hint bawaan InputDecoration.
                              // Teks placeholder hanya ditampilkan oleh Row di bawah.
                              hintText: '',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            isEmpty: _eventCategory.text.isEmpty,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _eventCategory.text.isEmpty
                                        ? 'Pilih kategori event'
                                        : _eventCategory.text,
                                    style: TextStyle(
                                      color: _eventCategory.text.isEmpty
                                          ? const Color(0xFF8A849F)
                                          : const Color(0xFF35245D),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF8050F6)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _eventDate,
                        readOnly: true,
                        onTap: () => _selectEventDate(),
                        decoration: _decoration(
                          'Tanggal Pelaksanaan',
                          'YYYY-MM-DD',
                          Icons.calendar_month_outlined,
                        ).copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF8050F6),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Tanggal wajib diisi.';
                          }
                          if (DateTime.tryParse(v.trim()) == null) {
                            return 'Pilih tanggal yang valid.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _boothCount,
                        keyboardType: TextInputType.number,
                        decoration: _decoration(
                          _isSeatEvent ? 'Jumlah Kursi' : 'Jumlah Booth Tersedia',
                          _isSeatEvent ? 'Otomatis 100 kursi' : 'Contoh: 20',
                          _isSeatEvent ? Icons.event_seat_outlined : Icons.storefront_outlined,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return n == null || n < 1
                              ? (_isSeatEvent ? 'Jumlah kursi otomatis 100.' : 'Masukkan jumlah booth yang valid.')
                              : null;
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final value = await _showGlassOptionPicker(
                                title: 'Pilih Sistem Harga',
                                subtitle: 'Tentukan apakah booth berbayar atau gratis',
                                options: const ['Berbayar', 'Gratis'],
                                selectedValue: _priceMode == 'free' ? 'Gratis' : 'Berbayar',
                                icon: Icons.payments_outlined,
                              );
                              if (value == null || !mounted) return;
                              setState(() {
                                _priceMode = value == 'Gratis' ? 'free' : 'paid';
                                if (_priceMode == 'free') _eventPrice.clear();
                              });
                            },
                            child: InputDecorator(
                              decoration: _decoration(
                                'Jenis Harga Sewa',
                                'Pilih berbayar atau gratis',
                                Icons.price_change_outlined,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _priceMode == 'free' ? 'Gratis' : 'Berbayar',
                                      style: const TextStyle(
                                        color: Color(0xFF35245D),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF8050F6)),
                                ],
                              ),
                            ),
                          ),
                          if (_priceMode == 'paid') ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _eventPrice,
                              keyboardType: TextInputType.number,
                              decoration: _decoration(
                                'Harga Sewa Booth',
                                'Contoh: 100000',
                                Icons.payments_outlined,
                              ),
                              validator: (v) => _priceMode == 'paid' &&
                                      (v == null || v.trim().isEmpty ||
                                          int.tryParse(v.trim()) == null)
                                  ? 'Masukkan harga berupa angka.'
                                  : null,
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Event ini tidak memungut biaya sewa booth.',
                                style: TextStyle(
                                  color: Color(0xFF6B4BA1),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ];
                    if (!wide) {
                      return Column(
                        children: fields
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: f,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 12),
                            Expanded(child: fields[1]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: fields[2]),
                            const SizedBox(width: 12),
                            Expanded(child: fields[3]),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                _buildLayoutEditor(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _eventLocation,
                  decoration:
                      _decoration(
                        'Lokasi Event',
                        'Masukkan alamat atau gunakan lokasi GPS',
                        Icons.location_on_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: 'Gunakan lokasi saya',
                          onPressed: _gettingLocation
                              ? null
                              : _getCurrentEventLocation,
                          icon: _gettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: _accent,
                                ),
                        ),
                      ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Lokasi event wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tekan ikon lokasi untuk mendeteksi alamat otomatis. Kamu juga bisa mengetik alamat secara manual.',
                  style: TextStyle(color: Color(0xFF81769B), fontSize: 12),
                ),
                if (_eventLatLng != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDCCBFF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Tampilan Peta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF35245D),
                                  ),
                                ),
                              ),
                              SegmentedButton<gmap.MapType>(
                                segments: const [
                                  ButtonSegment<gmap.MapType>(
                                    value: gmap.MapType.normal,
                                    label: Text('Normal'),
                                    icon: Icon(Icons.map_outlined),
                                  ),
                                  ButtonSegment<gmap.MapType>(
                                    value: gmap.MapType.hybrid,
                                    label: Text('Satelit'),
                                    icon: Icon(Icons.satellite_alt),
                                  ),
                                ],
                                selected: {_selectedMapType},
                                onSelectionChanged: (value) {
                                  setState(() {
                                    _selectedMapType = value.first;
                                  });
                                },
                                showSelectedIcon: false,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: gmap.GoogleMap(
                            initialCameraPosition: gmap.CameraPosition(
                              target: _eventLatLng!,
                              zoom: 15,
                            ),
                            onMapCreated: (controller) {
                              _eventMapController = controller;
                            },
                            onTap: (position) {
                              setState(() {
                                _eventLatLng = position;
                              });
                            },
                            mapType: _selectedMapType,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            compassEnabled: true,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: true,
                            markers: {
                              gmap.Marker(
                                markerId: const gmap.MarkerId('event_location'),
                                position: _eventLatLng!,
                                infoWindow: const gmap.InfoWindow(
                                  title: 'Lokasi Event Voca-TechXpo',
                                ),
                              ),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _eventDescription,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _decoration(
                    'Deskripsi Event',
                    'Jelaskan informasi event Anda',
                    Icons.description_outlined,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Deskripsi wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 16),
                _imagePickerCard(
                  title: 'Upload Poster Event',
                  file: _posterFile,
                  onTap: () async {
                    final picked = await _pickImage();
                    if (picked != null && mounted) {
                      setState(() => _posterFile = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _savingEvent ? null : _saveEvent,
                    icon: _savingEvent
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _savingEvent ? 'Mengunggah event...' : 'Simpan Event',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _sectionCard(
          title: 'Upload Banner Utama Dashboard Client',
          subtitle: 'Unggah gambar untuk banner paling atas di Dashboard Client. Tulisan “EXPO & MARKETPLACE 2026” dan “Pameran Wirausaha & Inovasi UKM Mahasiswa” akan muncul otomatis.',
          icon: Icons.panorama_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _imagePickerCard(
                title: 'Pilih Gambar Banner Utama',
                file: _heroBannerFile,
                onTap: () async {
                  final picked = await _pickImage();
                  if (picked != null && mounted) {
                    setState(() => _heroBannerFile = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_heroBannerFile != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EEFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCCBFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF6D28D9)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _heroBannerFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4C1D95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _savingHeroBanner ? null : _saveHeroBanner,
                  icon: _savingHeroBanner
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _savingHeroBanner
                        ? 'Mengunggah banner utama...'
                        : 'Publikasikan Banner Utama',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF581C87),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionCard(
          title: 'Upload Banner Promosi',
          subtitle: 'Banner aktif akan langsung muncul di bagian Promosi Spesial pada Dashboard Client dan juga tersimpan di Kelola Booth.',
          icon: Icons.campaign_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _bannerTitle,
                decoration: _decoration(
                  'Judul Promosi',
                  'Contoh: Promo Spesial Voca TechXpo',
                  Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 12),
              FormField<String>(
                initialValue: _selectedPromotionUkm,
                validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Pilih UKM pemilik promosi.'
                        : null,
                builder: (field) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final selected = await _showGlassUkmPicker(
                        selectedValue: _selectedPromotionUkm,
                      );
                      if (selected == null || !mounted) return;
                      setState(() => _selectedPromotionUkm = selected);
                      field.didChange(selected);
                    },
                    child: InputDecorator(
                      decoration: _decoration(
                        'Pilih UKM',
                        'Pilih UKM pemilik promosi',
                        Icons.groups_outlined,
                      ).copyWith(errorText: field.errorText),
                      isEmpty: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedPromotionUkm ??
                                  'Pilih UKM pemilik promosi',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _selectedPromotionUkm == null
                                    ? const Color(0xFF8A849F)
                                    : const Color(0xFF35245D),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF8050F6),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _imagePickerCard(
                title: 'Upload Banner Promosi',
                file: _bannerFile,
                onTap: () async {
                  final picked = await _pickImage();
                  if (picked != null && mounted) {
                    setState(() => _bannerFile = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _savingBanner ? null : _saveBanner,
                  icon: _savingBanner
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.campaign_rounded),
                  label: Text(
                    _savingBanner
                        ? 'Mengunggah banner...'
                        : 'Publikasikan Banner',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Banner Promosi Saya',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Color(0xFF21163F),
          ),
        ),
        const SizedBox(height: 12),
        if (!_loading && _promotions.isEmpty)
          _emptyInfo('Belum ada banner promosi yang diunggah.')
        else
          ..._promotions.map((promo) => _contentTile(
                title: (promo['title'] ?? 'Promosi').toString(),
                subtitle: (promo['is_active'] == true)
                    ? 'Aktif • tampil di dashboard client'
                    : 'Tidak aktif',
                imageUrl: (promo['banner_url'] ?? '').toString(),
                onEdit: () => _editPromotion(promo),
                onDelete: () => _deletePromotion(promo),
              )),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEAE4F8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF0E9FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF21163F),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777493),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget _emptyInfo(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEAE4F8)),
    ),
    child: Text(text, style: const TextStyle(color: Color(0xFF777493))),
  );

  Widget _contentTile({
    required String title,
    required String subtitle,
    required String imageUrl,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFEAE4F8)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 84,
                height: 72,
                child: imageUrl.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFF0E9FF),
                        child: Icon(Icons.image_outlined, color: _accent),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const ColoredBox(
                          color: Color(0xFFF0E9FF),
                          child: Icon(Icons.image_not_supported_outlined, color: _accent),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF21163F))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF777493))),
                ],
              ),
            ),
          ],
        ),
        if (onEdit != null || onDelete != null) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEAE4F8)),
          const SizedBox(height: 10),
          Row(children: [
            if (onEdit != null)
              Expanded(child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _accent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
            if (onEdit != null && onDelete != null) const SizedBox(width: 10),
            if (onDelete != null)
              Expanded(child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Color(0xFFFFCDD2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
          ]),
        ],
      ],
    ),
  );
}