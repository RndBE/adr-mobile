import 'package:adr_mobile/features/adr/models/adr_content_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selecting logger shows logger content', () {
    final selection = const AdrContentSelection.prisma(1).selectLogger();

    expect(selection.isLoggerSelected, isTrue);
    expect(selection.activePrismaIndex, 1);
  });

  test('selecting prisma hides logger content and updates active index', () {
    final selection = const AdrContentSelection.logger().selectPrisma(2);

    expect(selection.isLoggerSelected, isFalse);
    expect(selection.activePrismaIndex, 2);
  });
}
