import 'package:flutter_test/flutter_test.dart';
import 'package:bikehelpers/main.dart';

void main() {
  testWidgets('Smoke test - App runs and has title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BikeHelpersApp());

    // Verify that splash screen title 'BikeHelpers' is found.
    expect(find.text('BikeHelpers'), findsOneWidget);

    // Majukan waktu agar timer di splash screen selesai
    await tester.pump(const Duration(seconds: 3));
  });
}
