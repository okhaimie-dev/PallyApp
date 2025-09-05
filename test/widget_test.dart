// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pally/main.dart';

void main() {
  testWidgets('App loads sign in page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PallyApp());
    
    // Wait for any async initialization to complete
    await tester.pumpAndSettle();

    // Verify that the sign in page loads
    expect(find.text('Connect, Chat, and Share\nYour Global Community Awaits'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
