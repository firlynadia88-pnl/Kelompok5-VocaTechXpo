
import 'package:flutter/material.dart';

class ImageLoader extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageLoader({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final String image = imageUrl.trim();

    Widget child;

    if (image.isEmpty) {
      child = _placeholder();
    } else {
      child = Image.network(
        image,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,

        // Tampilan ketika gambar sedang dimuat
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return _placeholder(loading: true);
        },

        // Tampilan jika gambar gagal dimuat
        errorBuilder: (context, error, stackTrace) {
          return _placeholder(error: true);
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }

  Widget _placeholder({
    bool loading = false,
    bool error = false,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: const Color(0xFFF0E9FF),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF8050F6),
                  ),
                )
              : Icon(
                  error
                      ? Icons.broken_image_outlined
                      : Icons.image_outlined,
                  color: const Color(0xFF8050F6),
                  size: 28,
                ),
        ),
      ),
    );
  }
}
