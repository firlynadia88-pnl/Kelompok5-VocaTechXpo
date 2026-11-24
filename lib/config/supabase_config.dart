import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    // .env boleh tidak tersedia saat pengembangan; gunakan nilai fallback di bawah.
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://bptllbnxpuglooqdmmyv.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_QctjbhHmweqyiB74MLfRuA_Z2Xr-sNR',
  );
}
