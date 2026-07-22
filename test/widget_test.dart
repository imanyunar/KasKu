import 'package:flutter_test/flutter_test.dart';
import 'package:catatkas/main.dart';

void main() {
  testWidgets('CatatKasApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CatatKasApp());
    expect(find.byType(CatatKasApp), findsOneWidget);
  });
}
