import 'package:flutter/painting.dart';

class ImageCacheService {
  ImageCacheService._();

  static void configure() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 250;
    cache.maximumSizeBytes = 120 * 1024 * 1024;
  }

  static Future<void> evict(String url) async {
    if (url.trim().isEmpty) return;
    await NetworkImage(url).evict();
  }
}
