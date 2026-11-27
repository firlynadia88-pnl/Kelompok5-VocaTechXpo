import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({Key? key, required this.conversationId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();

  // Variabel untuk fitur gambar
  File? _selectedFile;
  bool _isUploading = false;

  // ==========================================
  // FUNGSI LOGIKA GAMBAR & PESAN
  // ==========================================

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _cancelImageSelection() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    
    // Jangan kirim jika teks kosong dan tidak ada gambar
    if (text.isEmpty && _selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    String? imageUrl;

    try {
      // 1. Upload gambar jika pengguna memilih file
      if (_selectedFile != null) {
        final fileExtension = _selectedFile!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.$fileExtension';

        // Pastikan bucket 'chat_images' sudah dibuat di Supabase Storage Anda
        await Supabase.instance.client.storage
            .from('chat_images')
            .upload(fileName, _selectedFile!);

        // Dapatkan URL publik dari gambar yang baru diupload
        imageUrl = Supabase.instance.client.storage
            .from('chat_images')
            .getPublicUrl(fileName);
      }

      // 2. Kirim pesan menggunakan layanan Anda
      // Catatan: Pastikan _chatService.sendMessage sudah menerima parameter imageUrl
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        message: text,
        senderType: 'user',
        // imageUrl: imageUrl, // Hapus komentar ini jika di chat_service Anda sudah ada parameter imageUrl
      );

      // 3. Reset input setelah berhasil
      _controller.clear();
      setState(() {
        _selectedFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _connectToOrganizer() {
    _chatService.switchToOrganizer(widget.conversationId);
  }

  // ==========================================
  // TAMPILAN UTAMA (UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voca-TechXpo Support'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.senderType == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.deepPurple : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama Pengirim (jika bukan user)
                            if (!isUser)
                              Text(
                                msg.senderType == 'bot' ? 'AI Assistant' : 'Organizer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.purple[900],
                                ),
                              ),
                            
                            // Menampilkan Gambar (Jika di model ChatMessage Anda ada imageUrl)
                            // Hapus komentar pada blok di bawah ini jika model ChatMessage Anda sudah memiliki properti `imageUrl`
                            /*
                            if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    msg.imageUrl!,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                ),
                              ),
                            */

                            // Menampilkan Teks Pesan
                            if (msg.message.isNotEmpty)
                              Text(
                                msg.message,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Opsi Bantuan / Chat Organizer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Apakah jawaban membantu? ', style: TextStyle(fontSize: 12)),
                ElevatedButton(
                  onPressed: _connectToOrganizer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Chat Organizer', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Area Input Pesan dan Lampiran Gambar
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tampilkan Preview Gambar jika file dipilih
              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedFile!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: GestureDetector(
                          onTap: _cancelImageSelection,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Baris Input Teks & Tombol
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Tombol Lampiran (Attachment)
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.deepPurple),
                      onPressed: _isUploading ? null : _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan tentang event atau booth...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Indikator Loading / Tombol Kirim
                    _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.deepPurple, strokeWidth: 2.5),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.deepPurple),
                            onPressed: _sendMessage,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}