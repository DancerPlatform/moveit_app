import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dancer_app/app.dart';
import 'package:dancer_app/providers/auth_provider.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const DancerApp(),
      ),
    );

    // Verify that the app title is shown
    expect(find.text('댄스학원'), findsOneWidget);
  });
}
