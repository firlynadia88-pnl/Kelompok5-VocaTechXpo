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

// ==================== PESAN TERPADU CLIENT & ORGANIZER ====================
// UI percakapan terpadu. Data contoh disimpan di memori aplikasi saat ini.
// Untuk sinkronisasi lintas perangkat dan AI sungguhan, hubungkan ke tabel
// Supabase conversations/messages serta Edge Function AI (lihat instruksi setelah kode).
class SharedMessagesScreen extends StatefulWidget {
  final bool isOrganizer;
  final VoidCallback? onBack;
  const SharedMessagesScreen({
    super.key,
    required this.isOrganizer,
    this.onBack,
  });

  @override
  State<SharedMessagesScreen> createState() => _SharedMessagesScreenState();
}

class _SharedMessagesScreenState extends State<SharedMessagesScreen> {
  static const Color _purple = Color(0xFF581C87);
  static const Color _accent = Color(0xFF8B5CF6);
  static final List<_VocaChatMessage> _sharedHistory = [
    _VocaChatMessage(
      text: 'Halo! 👋 Saya asisten Voca-TechXpo. Saya bisa membantu menjawab pertanyaan awal tentang event, booth, dan produk. Jika perlu konfirmasi langsung, kamu bisa menghubungi organizer.',
      sender: 'ai',
      time: DateTime.now(),
    ),
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _organizerRequested = false;
  bool _satisfied = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sharedHistory.add(
        _VocaChatMessage(
          text: text,
          sender: widget.isOrganizer ? 'organizer' : 'user',
          time: DateTime.now(),
        ),
      );
      _messageController.clear();
      if (!widget.isOrganizer) {
        _sharedHistory.add(
          _VocaChatMessage(
            text: _organizerRequested
                ? 'Pesanmu sudah masuk ke percakapan ini. Organizer dapat membalas di sini saat tersedia. Untuk harga, stok, pembayaran, dan konfirmasi pesanan, tunggu konfirmasi resmi dari organizer ya.'
                : _localAnswer(text),
            sender: 'ai',
            time: DateTime.now(),
          ),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _localAnswer(String question) {
    final q = question.toLowerCase();
    if (q.contains('harga') || q.contains('biaya')) {
      return 'Informasi harga dapat berbeda untuk setiap booth atau produk. Saya belum memiliki data harga spesifik di percakapan ini. Tekan “Chat Organizer” agar pengelola memberikan konfirmasi resmi.';
    }
    if (q.contains('bayar') ||
        q.contains('pembayaran') ||
        q.contains('transfer')) {
      return 'Untuk keamanan, ikuti metode pembayaran yang tersedia di halaman pemesanan aplikasi. Status pembayaran dan konfirmasi pesanan harus diverifikasi melalui sistem atau organizer.';
    }
    if (q.contains('booth') || q.contains('event') || q.contains('acara')) {
      return 'Kamu bisa membuka detail event atau booth untuk melihat informasi yang tersedia. Jika informasi lokasi, jadwal, fasilitas, atau ketersediaan belum tercantum, hubungi organizer melalui tombol di bawah.';
    }
    return 'Terima kasih atas pertanyaannya! Saya belum memiliki informasi spesifik yang cukup untuk memastikan jawaban tersebut. Kamu bisa menekan “Chat Organizer” agar pengelola menindaklanjuti dalam percakapan yang sama.';
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 760;
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6DDF8)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _purple,
                      size: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: _purple,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isOrganizer ? 'Pesan Masuk' : 'Pesan',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF21163F),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isOrganizer
                          ? 'Balas percakapan pengunjung dan lanjutkan riwayat chat yang sama.'
                          : 'Satu ruang percakapan untuk bantuan AI dan komunikasi dengan organizer.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777493),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isOrganizer)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Inbox',
                    style: TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAE4F8)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF0ECF7)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFF0E9FF),
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: _purple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voca-TechXpo Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF21163F),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'AI Assistant • Organizer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF777493),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Percakapan aktif',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF777493),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _sharedHistory.length,
                      itemBuilder: (context, index) {
                        final message = _sharedHistory[index];
                        final mine = widget.isOrganizer
                            ? message.sender == 'organizer'
                            : message.sender == 'user';
                        final isAi = message.sender == 'ai';
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop
                                  ? 520
                                  : MediaQuery.sizeOf(context).width * .78,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? _purple
                                  : (isAi
                                        ? const Color(0xFFF3EEFF)
                                        : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: Radius.circular(mine ? 15 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAi || message.sender == 'organizer') ...[
                                  Text(
                                    isAi ? 'AI Assistant' : 'Organizer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: mine ? Colors.white70 : _purple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: mine
                                        ? Colors.white
                                        : const Color(0xFF30264A),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    _formatTime(message.time),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: mine
                                          ? Colors.white60
                                          : Colors.black45,
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
                  if (!widget.isOrganizer && !_organizerRequested)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7FF),
                          border: Border.all(color: const Color(0xFFE8DDFB)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apakah jawaban ini membantu?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF30264A),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _satisfied = true),
                                  icon: Icon(
                                    _satisfied
                                        ? Icons.check_circle
                                        : Icons.thumb_up_alt_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _satisfied ? 'Terima kasih!' : 'Puas',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _purple,
                                    side: const BorderSide(
                                      color: Color(0xFFD8C8F6),
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () => setState(
                                    () => _organizerRequested = true,
                                  ),
                                  icon: const Icon(
                                    Icons.support_agent_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('Chat Organizer'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (_organizerRequested)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Permintaan diteruskan dalam percakapan ini. Organizer dapat membalas di sini.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF777493),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF0ECF7))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: widget.isOrganizer
                                  ? 'Balas pesan pengunjung...'
                                  : 'Tulis pesan tentang event atau booth...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sendMessage,
                          style: IconButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Catatan: jawaban otomatis pada versi ini masih berupa bantuan lokal contoh. Konfirmasi harga, pembayaran, stok, dan pesanan tetap harus dilakukan oleh organizer/sistem.',
            style: TextStyle(fontSize: 10, color: Color(0xFF8A849F)),
          ),
        ],
      ),
    );
  }
}

class _VocaChatMessage {
  final String text;
  final String sender; // user, ai, organizer
  final DateTime time;
  const _VocaChatMessage({
    required this.text,
    required this.sender,
    required this.time,
  });
}
