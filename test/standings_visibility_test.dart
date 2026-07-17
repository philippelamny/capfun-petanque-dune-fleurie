import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tournois_petanque/models/round.dart';
import 'package:tournois_petanque/models/team.dart';
import 'package:tournois_petanque/models/tournament.dart';
import 'package:tournois_petanque/providers/tournament_store.dart';
import 'package:tournois_petanque/screens/round_screen.dart';
import 'package:tournois_petanque/services/pairing_service.dart';

Tournament _tournamentAtRound(int roundNumber) {
  final pairing = PairingService();
  final tournament = Tournament(
    id: 't1',
    name: 'Test Cup',
    createdAt: DateTime(2026, 1, 1),
    teams: [for (var i = 0; i < 4; i++) Team(id: 'team$i', name: 'Team $i')],
    status: TournamentStatus.playing,
  );

  final round1 = pairing.generateRound1(tournament);
  tournament.rounds.add(Round(roundNumber: 1, matches: round1, durationMinutes: 35));
  for (final m in tournament.rounds[0].matches) {
    if (!m.isBye) m.submitScore(13, 7);
  }

  if (roundNumber >= 2) {
    final round2 = pairing.generateRound(tournament, roundNumber: 2);
    tournament.rounds.add(Round(roundNumber: 2, matches: round2, durationMinutes: 35));
    tournament.status = TournamentStatus.playing;
  }

  return tournament;
}

Widget _wrap(Tournament tournament) {
  final store = TournamentStore()
    ..tournaments.add(tournament)
    ..loading = false;
  return ChangeNotifierProvider<TournamentStore>.value(
    value: store,
    child: MaterialApp(home: RoundScreen(tournamentId: tournament.id)),
  );
}

void main() {
  testWidgets('classement action and rank captions are hidden during round 1', (tester) async {
    await tester.pumpWidget(_wrap(_tournamentAtRound(1)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.leaderboard_outlined), findsNothing);
    expect(find.textContaining('Rang'), findsNothing);
  });

  testWidgets('classement action appears from round 2 and shows team points', (tester) async {
    await tester.pumpWidget(_wrap(_tournamentAtRound(2)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.leaderboard_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('Classement provisoire'), findsOneWidget);
    expect(find.textContaining('pts marqués'), findsWidgets);
  });

  testWidgets('round 2 match cards show each team\'s rank and points', (tester) async {
    await tester.pumpWidget(_wrap(_tournamentAtRound(2)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rang'), findsWidgets);
    expect(find.textContaining('pts'), findsWidgets);
  });
}
