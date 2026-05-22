import 'package:adr_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isFirstTimeApp': true});

    await tester.pumpWidget(const AdrMobileApp());
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.byType(AdrMobileApp), findsOneWidget);
  });
}
