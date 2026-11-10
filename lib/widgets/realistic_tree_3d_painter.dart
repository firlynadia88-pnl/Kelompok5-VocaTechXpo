import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RealisticTree3DPainter extends CustomPainter {
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
