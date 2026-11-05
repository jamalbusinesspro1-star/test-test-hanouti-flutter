import 'package:flutter_test/flutter_test.dart';
import 'package:hanouti/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HanoutiApp());
    expect(find.byType(HanoutiApp), findsOneWidget);
  });
}
