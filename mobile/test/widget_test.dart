import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquasense_mobile/main.dart';
import 'package:aquasense_mobile/features/auth/application/auth_controller.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
        ],
        child: const AquaSenseApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AquaSenseApp), findsOneWidget);
  });
}
