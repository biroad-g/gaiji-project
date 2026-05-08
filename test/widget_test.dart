import 'package:flutter_test/flutter_test.dart';
import 'package:gaiji_app/main.dart';

void main() {
  testWidgets('GaijiApp smoke test', (WidgetTester tester) async {
    // アプリが起動できることを確認
    await tester.pumpWidget(const GaijiApp());
    expect(find.byType(GaijiApp), findsOneWidget);
  });
}
