import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voca_techxpo/main.dart';

void main() {
  testWidgets('Voca TechXpo app can be created', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
