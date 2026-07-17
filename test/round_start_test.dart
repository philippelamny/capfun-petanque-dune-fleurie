import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tournois_petanque/models/round.dart';
import 'package:tournois_petanque/models/team.dart';
import 'package:tournois_petanque/models/tournament.dart';
import 'package:tournois_petanque/providers/tournament_store.dart';
import 'package:tournois_petanque/screens/round_screen.dart';
import 'package:tournois_petanque/services/pairing_service.dart';
import 'package:tournois_petanque/services/storage_service.dart';

/// Avoids touching the filesystem / SharedPreferences plugins, which
/// aren't available in the widget-test host.
class _NoopStorage extends StorageService {
  @override
  Future<List<Tournament>> loadAll() async => [];

  @override
  Future<void> saveAll(List<Tournament> tournaments) async {}

  @override
  Future<({FirstRoundMode firstRoundMode, int numberOfRounds})> loadDefaults() async =>
      (firstRoundMode: FirstRoundMode.random, numberOfRounds: kDefaultRounds);

  @override
  Future<void> saveDefaults({
    required FirstRoundMode firstRoundMode,
    required int numberOfRounds,
  }) async {}
}

Tournament _tournamentWithPendingRound() {
  final pairing = PairingService();
  final tournament = Tournament(
    id: 't1',
    name: 'Test Cup',
    createdAt: DateTime(2026, 1, 1),
    teams: [for (var i = 0; i < 4; i++) Team(id: 'team$i', name: 'Team $i')],
    status: TournamentStatus.playing,
  );
  final round1 = pairing.generateRound1(tournament);
  // No startedAt: the round exists but its clock hasn't been started yet.
  tournament.rounds.add(Round(roundNumber: 1, matches: round1, durationMinutes: 35));
  return tournament;
}

Widget _wrap(Tournament tournament) {
  final store = TournamentStore(storage: _NoopStorage())
    ..tournaments.add(tournament)
    ..loading = false;
  return ChangeNotifierProvider<TournamentStore>.value(
    value: store,
    child: MaterialApp(home: RoundScreen(tournamentId: tournament.id)),
  );
}

void main() {
  testWidgets('round starts with no countdown, showing a start button instead', (tester) async {
    await tester.pumpWidget(_wrap(_tournamentWithPendingRound()));
    await tester.pumpAndSettle();

    expect(find.text("Le décompte n'a pas encore démarré"), findsOneWidget);
    expect(find.text('Démarrer'), findsOneWidget);
    expect(find.textContaining('Temps restant'), findsNothing);
  });

  testWidgets('tapping "Démarrer" starts the countdown and hides the start button', (tester) async {
    await tester.pumpWidget(_wrap(_tournamentWithPendingRound()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text("Le décompte n'a pas encore démarré"), findsNothing);
    expect(find.text('Démarrer'), findsNothing);
    expect(find.textContaining('Temps restant'), findsOneWidget);
  });
}
