import 'package:flutter_test/flutter_test.dart';
import 'package:word_master/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const WordMasterApp());
    expect(find.text('词达人'), findsOneWidget);
  });
}
