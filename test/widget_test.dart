import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_app/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FarmaciaApp());

    // Verify that the title is present.
    expect(find.text('Control Farmacéutico'), findsOneWidget);
    expect(find.text('Comenzar verificación'), findsOneWidget);
  });
}

