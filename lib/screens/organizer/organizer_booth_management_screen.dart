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


// ==================== KELOLA BOOTH: DATA EVENT & PROMOSI ====================
class OrganizerBoothManagementScreen extends StatefulWidget {
  const OrganizerBoothManagementScreen({super.key});

  @override
  State<OrganizerBoothManagementScreen> createState() =>
      _OrganizerBoothManagementScreenState();
}

class _OrganizerBoothManagementScreenState
    extends State<OrganizerBoothManagementScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8050F6);
  static const Color _ink = Color(0xFF21163F);
  static const Color _muted = Color(0xFF777493);

  bool _loading = true;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _booths = [];
  List<Map<String, dynamic>> _promotions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('booth_events')
            .select()
            .eq('owner_id', user.id)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('booths')
            .select()
            .eq('owner_id', user.id)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('promotions')
            .select()
            .eq('owner_id', user.id)
            .order('created_at', ascending: false),
      ]);

      if (!mounted) return;
      setState(() {
        _events = (results[0] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _booths = (results[1] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _promotions = (results[2] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data Kelola Booth belum dapat dimuat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _countPending(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == 'pending' || status == 'menunggu';
    }).length;
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String caption,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAE4F8)),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, {bool active = false}) {
    final normalized = status.toLowerCase();
    final Color color = active
        ? const Color(0xFF15803D)
        : normalized == 'approved' ||
                normalized == 'disetujui' ||
                normalized == 'active'
            ? const Color(0xFF15803D)
            : normalized == 'rejected' || normalized == 'ditolak'
                ? const Color(0xFFDC2626)
                : const Color(0xFFB7791F);
    final String label = active
        ? 'Aktif'
        : status.isEmpty
            ? 'Menunggu'
            : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }


  Future<void> _editManagedEvent(Map<String, dynamic> event) async {
    final id = event['id'];
    if (id == null) {
      _showManagedMessage('ID event tidak ditemukan.', isError: true);
      return;
    }

    final name = TextEditingController(text: (event['event_name'] ?? '').toString());
    final description = TextEditingController(text: (event['description'] ?? '').toString());
    final category = TextEditingController(text: (event['category'] ?? '').toString());
    final date = TextEditingController(text: (event['event_date'] ?? '').toString());
    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Text('Edit Event & Poster', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Judul / Nama Event',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Event',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Event',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: date,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Event',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white),
                onPressed: saving ? null : () async {
                  if (name.text.trim().isEmpty) {
                    _showManagedMessage('Judul event tidak boleh kosong.', isError: true);
                    return;
                  }
                  setDialogState(() => saving = true);
                  try {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) throw Exception('Sesi login tidak ditemukan.');
                    await Supabase.instance.client.from('booth_events').update({
                      'event_name': name.text.trim(),
                      'description': description.text.trim(),
                      'category': category.text.trim(),
                      'event_date': date.text.trim(),
                    }).eq('id', id).eq('owner_id', user.id);
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    await _load();
                    _showManagedMessage('Event berhasil diperbarui.');
                  } catch (e) {
                    setDialogState(() => saving = false);
                    _showManagedMessage('Gagal memperbarui event: $e', isError: true);
                  }
                },
                icon: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      description.dispose();
      category.dispose();
      date.dispose();
    }
  }

  Future<void> _deleteManagedItem(
    Map<String, dynamic> item, {
    required bool isEvent,
  }) async {
    final id = item['id'];
    if (id == null) {
      _showManagedMessage('ID data tidak ditemukan.', isError: true);
      return;
    }
    final label = isEvent
        ? (item['event_name'] ?? 'Event').toString()
        : (item['title'] ?? 'Banner promosi').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus data?', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        content: Text('"$label" akan dihapus. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Sesi login tidak ditemukan.');
      final table = isEvent ? 'booth_events' : 'promotions';
      await Supabase.instance.client
          .from(table)
          .delete()
          .eq('id', id)
          .eq('owner_id', user.id);
      await _load();
      _showManagedMessage(isEvent ? 'Event berhasil dihapus.' : 'Banner promosi berhasil dihapus.');
    } catch (e) {
      _showManagedMessage('Gagal menghapus data: $e', isError: true);
    }
  }

  void _showManagedMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _purple,
      ),
    );
  }

  Widget _section({
    required String title,
    required String description,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String nameKey,
    required String imageKey,
    required String subtitleBuilderKey,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE4F8)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _purple, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F1FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: _purple,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0EBF8)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    color: Color(0xFFA69ABF),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada data. Tambahkan melalui menu Produk Saya.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((item) {
              final image = (item[imageKey] ?? '').toString();
              final name = (item[nameKey] ?? 'Tanpa nama').toString();

              String subtitle;
              String status;
              if (subtitleBuilderKey == 'event') {
                subtitle =
                    '${item['category'] ?? 'Event'} • ${item['event_date'] ?? '-'}';
                status = (item['status'] ?? 'pending').toString();
              } else if (subtitleBuilderKey == 'booth') {
                subtitle =
                    '${item['business_type'] ?? '-'} • ${item['organizer_type'] ?? '-'}';
                status = (item['status'] ?? 'pending').toString();
              } else {
                subtitle = 'Promosi Spesial • ${item['ukm'] ?? 'Organizer'}';
                status = item['is_active'] == true ? 'active' : 'nonaktif';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFBFE),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFF0EBF8)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: SizedBox(
                        width: 88,
                        height: 82,
                        child: image.isEmpty
                            ? const ColoredBox(
                                color: Color(0xFFF0E9FF),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: _accent,
                                  size: 28,
                                ),
                              )
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const ColoredBox(
                                    color: Color(0xFFF0E9FF),
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: _accent,
                                      size: 26,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _statusBadge(
                            status,
                            active: subtitleBuilderKey == 'promotion' &&
                                item['is_active'] == true,
                          ),
                        ],
                      ),
                    ),
                    if (subtitleBuilderKey == 'event' || subtitleBuilderKey == 'promotion')
                      PopupMenuButton<String>(
                        tooltip: 'Kelola data',
                        icon: const Icon(Icons.more_vert_rounded, color: _muted),
                        onSelected: (action) {
                          if (action == 'edit' && subtitleBuilderKey == 'event') {
                            _editManagedEvent(item);
                          } else if (action == 'delete') {
                            _deleteManagedItem(
                              item,
                              isEvent: subtitleBuilderKey == 'event',
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (subtitleBuilderKey == 'event')
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit judul & deskripsi'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int pendingBooths = _countPending(_booths);
    final int activePromotions =
        _promotions.where((item) => item['is_active'] == true).length;

    return RefreshIndicator(
      color: _purple,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Booth',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Pantau booth, event, poster, dan promosi Anda dalam satu tempat.',
                      style: TextStyle(
                        color: _muted,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Muat ulang data',
                onPressed: _loading ? null : _load,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0E9FF),
                  foregroundColor: _purple,
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF581C87),
                  Color(0xFF7135B5),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'ORGANIZER SPACE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Semua aktivitas booth Anda, lebih mudah dipantau.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Periksa status pengajuan dan pastikan informasi event serta banner promosi selalu terbaru.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ringkasan Aktivitas',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: CircularProgressIndicator(color: _purple),
              ),
            )
          else ...[
            Row(
              children: [
                _summaryCard(
                  title: 'Pengajuan Booth',
                  count: _booths.length,
                  icon: Icons.storefront_outlined,
                  color: const Color(0xFF8050F6),
                  caption: '$pendingBooths menunggu proses',
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  title: 'Event & Poster',
                  count: _events.length,
                  icon: Icons.event_note_rounded,
                  color: const Color(0xFF2563EB),
                  caption: 'Event terunggah',
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  title: 'Banner Aktif',
                  count: activePromotions,
                  icon: Icons.campaign_outlined,
                  color: const Color(0xFF059669),
                  caption: 'Promosi dipublikasikan',
                ),
              ],
            ),
            const SizedBox(height: 22),
            _section(
              title: 'Pengajuan Booth',
              description: 'Status pendaftaran booth Anda',
              icon: Icons.storefront_outlined,
              items: _booths,
              nameKey: 'name',
              imageKey: 'poster_url',
              subtitleBuilderKey: 'booth',
            ),
            _section(
              title: 'Event dan Poster',
              description: 'Daftar event yang telah Anda unggah',
              icon: Icons.event_available_rounded,
              items: _events,
              nameKey: 'event_name',
              imageKey: 'poster_url',
              subtitleBuilderKey: 'event',
            ),
            _section(
              title: 'Banner Promosi',
              description: 'Promosi yang ditampilkan kepada client',
              icon: Icons.campaign_outlined,
              items: _promotions,
              nameKey: 'title',
              imageKey: 'banner_url',
              subtitleBuilderKey: 'promotion',
            ),
          ],
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Voca-TechXpo • Organizer Dashboard',
              style: TextStyle(
                color: _muted.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
