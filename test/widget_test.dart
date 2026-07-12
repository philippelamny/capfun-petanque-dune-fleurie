import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tournois_petanque/main.dart';

void main() {
  testWidgets('App shows the splash animation then the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PetanqueApp());
    await tester.pump();

    // Splash is showing first; the home screen hasn't appeared yet.
    expect(find.text('Tournois Pétanque Cap Fun'), findsNothing);

    // Let the roll-in animation and hold finish, then the fade transition.
    await tester.pump(const Duration(milliseconds: 2250));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(find.text('Tournois Pétanque Cap Fun'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
