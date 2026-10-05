import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ganti "flutter_voca_techxpo" dengan nama package project kamu yang ada di pubspec.yaml
import 'package:flutter_voca_techxpo/main.dart'; 

void main() {
  testWidgets('Voca-techXpro login screen smoke test', (WidgetTester tester) async {
    // Build aplikasi dan trigger frame.
    await tester.pumpWidget(const MyApp());

    // Verifikasi bahwa nama dan judul brand muncul di layar.
    expect(find.text('Firly Nadia'), findsOneWidget);
    expect(find.text('Voca-techXpro'), findsOneWidget);

    // Verifikasi bahwa label input form (Username, Alamat Email, Kata Sandi) ada.
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);

    // Verifikasi bahwa tombol "Masuk Sekarang" ada di layar.
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });
}