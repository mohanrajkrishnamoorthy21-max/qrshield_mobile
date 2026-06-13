import 'package:flutter_test/flutter_test.dart';
import 'package:qrshield_mobile/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QRShieldApp());

    // Verify that the splash screen shows 'QRShield'.
    expect(find.text('QRShield'), findsOneWidget);
    expect(find.text('Smart Anti-Phishing Protection'), findsOneWidget);

    // Pump frames to let the animations and 2.5s navigation timer complete
    await tester.pump(const Duration(seconds: 3));
  });
}
