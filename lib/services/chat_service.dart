import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';

class ChatService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Reading API Key dynamically via getter
  String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // 1. Stream pesan realtime dari Supabase
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  // 2. Logika Kirim Pesan & Trigger AI (Tahap 1: AI -> Tahap 2: Organizer)
  Future<void> sendMessage({
    required String conversationId,
    required String message,
    required String senderType,
    String? imageUrl,
  }) async {
    try {
      final String userId =
          supabase.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000001';

      // A. Cek status & topik UKM percakapan di Supabase
      final existing = await supabase
          .from('conversations')
          .select('id, status, topic')
          .eq('id', conversationId)
          .maybeSingle();

      String status = 'bot';
      String ukmTopic = 'Voca-TechXpo';

      if (existing == null) {
        await supabase.from('conversations').insert({
          'id': conversationId,
          'user_id': userId,
          'client_id': userId,
          'status': 'bot',
          'unread_count': 0,
        });
      } else {
        status = (existing['status'] ?? 'bot').toString();
        ukmTopic = (existing['topic'] ?? 'Voca-TechXpo').toString();
      }

      // B. Simpan pesan pengirim (User/Organizer) ke tabel messages
      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_type': senderType,
        'message': message,
        'image_url': imageUrl,
        'is_read': senderType == 'organizer',
      });

      final String previewText = (imageUrl != null && imageUrl.isNotEmpty)
          ? (message.isEmpty ? '📷 Mengirim gambar' : '📷 $message')
          : message;

      final bool isAiMode = (status == 'bot' || status == 'ai');

      // C. TAHAP 1: Jika pengirim 'user' dan masih mode AI, panggil Groq AI
      if (senderType == 'user' && isAiMode) {
        final promptForAi = message.isEmpty && imageUrl != null
            ? 'Pengunjung mengirimkan lampiran gambar pada obrolan $ukmTopic.'
            : message;

        final String botReply = await _getGroqResponse(
          promptForAi,
          ukmTopic: ukmTopic,
        );

        // Simpan balasan AI Bot ke Supabase
        await supabase.from('messages').insert({
          'conversation_id': conversationId,
          'sender_type': 'bot',
          'message': botReply,
        });

        // Perbarui cuplikan room (unread_count tetap 0 karena masih ditangani AI)
        await supabase.from('conversations').update({
          'last_message': botReply,
          'last_message_at': DateTime.now().toIso8601String(),
          'unread_count': 0,
        }).eq('id', conversationId);
      }
      // D. TAHAP 2: Jika sudah beralih ke Organizer, AI berhenti & kirim notif ke Inbox Organizer
      else if (senderType == 'user' && !isAiMode) {
        await supabase.from('conversations').update({
          'last_message': previewText,
          'last_message_at': DateTime.now().toIso8601String(),
          'unread_count': 1,
        }).eq('id', conversationId);
      }
      // E. Jika Organizer membalas pesan Client
      else if (senderType == 'organizer') {
        await markUserMessagesAsRead(conversationId);
        await supabase.from('conversations').update({
          'last_message': previewText,
          'last_message_at': DateTime.now().toIso8601String(),
          'unread_count': 0,
        }).eq('id', conversationId);
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // 3. Fungsi memanggil API Groq dengan konteks UKM pilihan Client
  Future<String> _getGroqResponse(
    String userMessage, {
    String ukmTopic = 'Voca-TechXpo',
  }) async {
    try {
      if (groqApiKey.isEmpty) {
        print('GROQ API KEY WARNING: Key tidak ditemukan di file .env');
        return 'Maaf, API Key Groq belum terkonfigurasi di file .env.';
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b',
          'messages': [
            {
              'role': 'system',
              'content': '''Anda adalah Voca-Bot, asisten AI ramah untuk Voca-TechXpo.
Saat ini pengunjung sedang membuka ruang obrolan khusus untuk topik/booth: "$ukmTopic".
Tugas Anda adalah menjawab pertanyaan seputar acara Voca-TechXpo, jadwal, informasi umum pendaftaran, dan daftar booth/UKM tersebut.

DATA RESMI ACARA VOCA-TECHXPO:
- Nama Acara: Voca-TechXpo (Pameran Inovasi Teknologi, Karya Mahasiswa, & Bazar UMKM Politeknik).
- Tanggal & Jam: [ISI TANGGAL ACARA, misal: 25-27 November 2026], pukul 08.00 - 17.00 WIB.
- Lokasi: [ISI LOKASI, misal: Aula Utama & Lapangan Gedung Direktorat Kampus].
- Tiket Masuk: Gratis untuk seluruh mahasiswa dan pengunjung umum (cukup registrasi di meja penerima tamu / aplikasi).
- Rangkaian Acara: Pameran karya teknologi tiap jurusan, open recruitment UKM & HIMA, bazar kuliner & produk UMKM mahasiswa, workshop teknologi, dan pentas seni.
- Metode Pembayaran di Booth: Mendukung QRIS Voca-TechXpo, Transfer Bank [ISI NAMA BANK & NO REK], serta tunai (cash) langsung di booth.

PROFIL SINGKAT UKM & HIMA PESERTA:
- UKM Edelweis: Organisasi mahasiswa pencinta alam (kegiatan pendakian, konservasi alam, SAR, dan panjat tebing).
- UKM Taekwondo: Unit kegiatan bela diri Taekwondo (latihan rutin fisik, teknik poomsae & kyorugi, serta kejuaraan).
- UKM Polyrobocom: Komunitas riset dan pengembangan robotika politeknik (persiapan Kontes Robot Indonesia / KRI).
- UKM Merpati Putih: Perguruan pencak silat tangan kosong (latihan olah napas, tenaga dalam, dan bela diri tradisional).
- BEM: Badan Eksekutif Mahasiswa (pusat koordinasi kegiatan kemahasiswaan, advokasi, dan panitia utama event kampus).
- HIMATIK: Himpunan Mahasiswa Teknik Informatika dan Komputer (pameran aplikasi, web, AI, game, dan keamanan siber).
- HIMABIS: Himpunan Mahasiswa Administrasi Bisnis (pameran manajemen bisnis, pemasaran digital, dan kewirausahaan).
- HIMA ELEKTRO: Himpunan Mahasiswa Teknik Elektro (pameran IoT, otomasi industri, kelistrikan, dan mikrokontroler).
- HIMA MESIN: Himpunan Mahasiswa Teknik Mesin (pameran manufaktur, desain CAD, otomotif, dan rekayasa mekanik).
- HIMA SIPIL: Himpunan Mahasiswa Teknik Sipil (pameran maket konstruksi, struktur bangunan, dan inovasi material).
- Wirausaha Mahasiswa Mandiri (UMKM): Wadah bisnis dan bazar mahasiswa yang menjual aneka kuliner, minuman, fashion, dan merchandise kreatif.
- UKM IECLOP (Improving English Club of Polytechnic): Komunitas pengembangan bahasa Inggris (debate, speech, storytelling, dan TOEFL preparation).
- UKM LDK-FORDIMA: Lembaga Dakwah Kampus Forum Studi Mahasiswa Islam (kajian keislaman, mentoring, dan kegiatan sosial).
- UKM POLICY (Polytechnic Linux Community): Komunitas sistem operasi Linux, open-source software, jaringan, dan administrasi server.
- UKM Sanggar Seni: Wadah kreativitas mahasiswa di bidang seni tari tradisional/modern, musik, vokal, dan teater.

ALUR PENDAFTARAN UMUM UKM / HIMA:
- Terbuka untuk seluruh mahasiswa aktif (terutama semester 1 dan 3).
- Cara daftar: Kunjungi langsung booth "$ukmTopic" di lokasi expo untuk mengisi formulir pendaftaran, atau minta link formulir online kepada admin.
- Syarat umum: KTM (Kartu Tanda Mahasiswa) atau bukti registrasi mahasiswa aktif.

ATURAN FORMAT PESAN (PENTING):
1. Balaslah seperti sedang chatting di WhatsApp. Gunakan bahasa santai, jelas, dan ramah.
2. DILARANG KERAS menggunakan format Markdown seperti tanda bintang (**) untuk huruf tebal, atau garis (|) untuk membuat tabel.
3. Jika perlu membuat daftar, gunakan baris baru dan tanda strip (-) biasa.

ATURAN FORMAT PESAN (WAJIB):
1. Jawablah seperti sedang chatting di WhatsApp: santai, sopan, informatif, dan langsung ke inti jawaban.
2. DILARANG KERAS menggunakan format Markdown seperti tanda bintang (**) untuk huruf tebal atau garis (|) untuk tabel.
3. Jika membuat poin daftar, gunakan baris baru dan tanda strip (-) biasa.
4. Gunakan DATA RESMI di atas untuk menjawab pertanyaan pengunjung secara lengkap agar pengunjung tidak perlu repot menghubungi organizer untuk hal-hal umum.
5. HANYA jika pengunjung menanyakan hal yang butuh pengecekan manual (seperti cek bukti transfer yang baru dikirim, stok sisa barang saat ini, nego harga, atau jadwal internal khusus yang belum tertulis di atas), barulah arahkan dengan kalimat: "Untuk pengecekan langsung oleh panitia $ukmTopic, silakan klik tombol 'Chat Organizer' di bawah pesan ini ya."'''
            },
            {'role': 'user', 'content': userMessage}
          ]
        }),
      );

      print('Groq Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Groq Response Body: ${response.body}');
        return 'Maaf, gagal terhubung ke Groq API (Error: ${response.statusCode}).';
      }
    } catch (e) {
      print('Error Groq Exception: $e');
      return 'Maaf, gagal terhubung ke sistem AI.';
    }
  }

  // 4. Fungsi Beralih dari AI ke Organizer saat tombol "Chat Organizer" diklik
  Future<bool> switchToOrganizer(String conversationId) async {
    // 4B. Fungsi Kembali dari Organizer ke Mode Chatbot AI
  Future<bool> switchToAi(String conversationId) async {
    try {
      const backToAiMsg =
          'Percakapan dikembalikan ke Voca-Bot AI. Silakan tanyakan apa saja seputar event atau booth ini ya.';

      await supabase.from('conversations').update({
        'status': 'bot',
        'last_message': 'Kembali ke mode AI Assistant',
        'last_message_at': DateTime.now().toIso8601String(),
        'unread_count': 0,
      }).eq('id', conversationId);

      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_type': 'bot',
        'message': backToAiMsg,
      });

      return true;
    } catch (e) {
      print('Error switching back to AI: $e');
      return false;
    }
  }

    try {
      const takeoverMsg =
          'Pesanmu sudah dialihkan ke Organizer. Admin UKM akan segera membalas di ruang obrolan ini, silakan tulis detail pertanyaan atau bukti transfermu ya.';

      await supabase.from('conversations').update({
        'status': 'organizer',
        'last_message': 'Meminta terhubung dengan Organizer',
        'last_message_at': DateTime.now().toIso8601String(),
        'unread_count': 1,
      }).eq('id', conversationId);

      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_type': 'bot',
        'message': takeoverMsg,
      });

      return true;
    } catch (e) {
      print('Error switching to organizer: $e');
      return false;
    }
  }

  // 5. Fungsi Membersihkan Riwayat Pesan di Supabase
  Future<void> clearMessages(String conversationId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .eq('conversation_id', conversationId);

      await supabase
          .from('conversations')
          .update({'status': 'bot', 'unread_count': 0})
          .eq('id', conversationId);
    } catch (e) {
      print('Error clearing messages: $e');
    }
  }

  // 6. Tandai pesan Client sudah dilihat/dibaca oleh Admin Organizer
Future<void> markUserMessagesAsRead(String conversationId) async {
  try {
    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('sender_type', 'user')
        .eq('is_read', false);
  } catch (e) {
    print('Error marking messages as read: $e');
  }
}

}