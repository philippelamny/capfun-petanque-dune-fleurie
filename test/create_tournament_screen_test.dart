import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tournois_petanque/models/tournament.dart';
import 'package:tournois_petanque/providers/tournament_store.dart';
import 'package:tournois_petanque/screens/create_tournament_screen.dart';

Widget _wrap(TournamentStore store) {
  return ChangeNotifierProvider<TournamentStore>.value(
    value: store,
    child: const MaterialApp(home: CreateTournamentScreen()),
  );
}

void main() {
  testWidgets('defaults to the last-used first-round mode and round count', (tester) async {
    final store = TournamentStore()
      ..loading = false
      ..lastFirstRoundMode = FirstRoundMode.registrationOrder
      ..lastNumberOfRounds = 5;
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('Un nouveau tournoi de pétanque en 5 manches !'), findsOneWidget);

    final registrationChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text("Ordre d'inscription"), matching: find.byType(ChoiceChip)),
    );
    expect(registrationChip.selected, isTrue);

    final fiveChip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.descendant(of: find.byType(ChoiceChip), matching: find.text('5')),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(fiveChip.selected, isTrue);
  });

  testWidgets('tapping chips switches first-round mode and round count', (tester) async {
    final store = TournamentStore()..loading = false;
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    // Defaults: random draw, 3 rounds.
    expect(find.text('Un nouveau tournoi de pétanque en 3 manches !'), findsOneWidget);

    await tester.tap(find.text("Ordre d'inscription"));
    await tester.ensureVisible(find.text('8'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    expect(find.text('Un nouveau tournoi de pétanque en 8 manches !'), findsOneWidget);
    final registrationChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text("Ordre d'inscription"), matching: find.byType(ChoiceChip)),
    );
    expect(registrationChip.selected, isTrue);
    final randomChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Tirage au sort'), matching: find.byType(ChoiceChip)),
    );
    expect(randomChip.selected, isFalse);
  });
}
