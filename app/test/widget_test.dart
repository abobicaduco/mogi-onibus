import 'package:flutter_test/flutter_test.dart';

import 'package:mogionibus/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MogiOnibusApp());
    await tester.pump();
    expect(find.text('Ônibus Mogi'), findsWidgets);
  });
}
