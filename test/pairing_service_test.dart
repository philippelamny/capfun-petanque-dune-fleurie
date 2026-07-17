import 'package:flutter_test/flutter_test.dart';
import 'package:tournois_petanque/models/round.dart';
import 'package:tournois_petanque/models/team.dart';
import 'package:tournois_petanque/models/tournament.dart';
import 'package:tournois_petanque/services/pairing_service.dart';

Tournament _buildTournament(int teamCount) {
  return Tournament(
    id: 't',
    name: 'Test',
    createdAt: DateTime(2026, 1, 1),
    teams: [
      for (var i = 0; i < teamCount; i++) Team(id: 'team$i', name: 'Team $i'),
    ],
  );
}

/// Plays out a round by giving every non-bye match a deterministic winner
/// (team A always wins) so standings are well-defined for the next round.
void _playRound(Tournament tournament, Round round) {
  for (final match in round.matches) {
    if (match.isBye) continue;
    match.submitScore(13, 5);
  }
}

void main() {
  final pairing = PairingService();

  for (final teamCount in [4, 5, 6, 7, 8, 9, 10, 11]) {
    test('$teamCount teams: bye rules hold across all 3 rounds', () {
      final tournament = _buildTournament(teamCount);

      final round1Matches = pairing.generateRound1(tournament);
      tournament.rounds.add(
        Round(roundNumber: 1, matches: round1Matches, durationMinutes: 35),
      );
      _playRound(tournament, tournament.rounds[0]);

      final round2Matches = pairing.generateRound(tournament, roundNumber: 2);
      tournament.rounds.add(
        Round(roundNumber: 2, matches: round2Matches, durationMinutes: 35),
      );
      _playRound(tournament, tournament.rounds[1]);

      final round3Matches = pairing.generateRound(tournament, roundNumber: 3);
      tournament.rounds.add(
        Round(roundNumber: 3, matches: round3Matches, durationMinutes: 35),
      );
      _playRound(tournament, tournament.rounds[2]);

      final isOdd = teamCount.isOdd;

      // Every round: everyone plays if even, exactly one team waits if odd.
      for (final round in tournament.rounds) {
        final byes = round.matches.where((m) => m.isBye).toList();
        expect(byes.length, isOdd ? 1 : 0,
            reason: 'round ${round.roundNumber} bye count');
        expect(round.matches.length, isOdd ? (teamCount + 1) ~/ 2 : teamCount ~/ 2);
        final playedTeamIds = round.matches.expand((m) => [m.teamAId, if (m.teamBId != null) m.teamBId!]);
        expect(playedTeamIds.toSet().length, teamCount,
            reason: 'every team appears exactly once in round ${round.roundNumber}');
      }

      // A team can never get a bye more than once across the tournament.
      final byeTeamIds = tournament.rounds
          .expand((r) => r.matches)
          .where((m) => m.isBye)
          .map((m) => m.teamAId)
          .toList();
      expect(byeTeamIds.toSet().length, byeTeamIds.length,
          reason: 'no team should be benched twice');

      // Winners-vs-winners check for rounds 2 and 3: teams should be paired
      // within their current win-count "score group" (winners with
      // winners, losers with losers), except for the one legitimate
      // cross-group pairing per group boundary when a group has an odd
      // count (its weakest team "floats down" to play the best team of
      // the next group down).
      for (final roundIndex in [1, 2]) {
        final round = tournament.rounds[roundIndex];
        final standingsBefore = Tournament(
          id: 't',
          name: 'snapshot',
          createdAt: DateTime(2026, 1, 1),
          teams: tournament.teams,
          rounds: tournament.rounds.sublist(0, roundIndex),
        ).computeStandings();

        // Score-group index per team: 0 = most wins, 1 = next group, etc.
        // The bye recipient (if any) sits out this round's pairing.
        String? byeTeamId;
        for (final m in round.matches) {
          if (m.isBye) byeTeamId = m.teamAId;
        }
        final ranked = [for (final s in standingsBefore) s.team.id]..remove(byeTeamId);
        final winsById = {for (final s in standingsBefore) s.team.id: s.wins};
        final groupIndex = <String, int>{};
        var group = -1;
        int? lastWins;
        for (final id in ranked) {
          final w = winsById[id];
          if (lastWins == null || w != lastWins) {
            group++;
            lastWins = w;
          }
          groupIndex[id] = group;
        }

        final crossingCounts = <int, int>{};
        for (final match in round.matches) {
          if (match.isBye) continue;
          final gA = groupIndex[match.teamAId]!;
          final gB = groupIndex[match.teamBId]!;
          final diff = (gA - gB).abs();
          expect(diff <= 1, isTrue,
              reason: 'round ${round.roundNumber}: ${match.teamAId} (group $gA) vs '
                  '${match.teamBId} (group $gB) should be in the same or an adjacent score group');
          if (diff == 1) {
            final boundary = gA < gB ? gA : gB;
            crossingCounts[boundary] = (crossingCounts[boundary] ?? 0) + 1;
            expect(crossingCounts[boundary], 1,
                reason: 'round ${round.roundNumber}: more than one match crosses the group boundary at $boundary');
          }
        }
      }
    });
  }

  test('rematches are avoided whenever a rematch-free pairing exists', () {
    // 8 teams gives plenty of room to always find a conflict-free pairing.
    final tournament = _buildTournament(8);
    final round1 = pairing.generateRound1(tournament);
    tournament.rounds.add(Round(roundNumber: 1, matches: round1, durationMinutes: 35));
    _playRound(tournament, tournament.rounds[0]);

    final round2 = pairing.generateRound(tournament, roundNumber: 2);
    tournament.rounds.add(Round(roundNumber: 2, matches: round2, durationMinutes: 35));
    _playRound(tournament, tournament.rounds[1]);

    final round1Keys = round1.where((m) => !m.isBye).map((m) => pairKey(m.teamAId, m.teamBId!)).toSet();
    for (final match in round2.where((m) => !m.isBye)) {
      final key = pairKey(match.teamAId, match.teamBId!);
      expect(round1Keys.contains(key), isFalse, reason: 'round 2 rematch: $key');
    }

    final round3 = pairing.generateRound(tournament, roundNumber: 3);
    final playedBefore = {...round1Keys, ...round2.where((m) => !m.isBye).map((m) => pairKey(m.teamAId, m.teamBId!))};
    for (final match in round3.where((m) => !m.isBye)) {
      final key = pairKey(match.teamAId, match.teamBId!);
      expect(playedBefore.contains(key), isFalse, reason: 'round 3 rematch: $key');
    }
  });

  test('registrationOrder mode pairs round 1 by registration order, no shuffle', () {
    final tournament = Tournament(
      id: 't',
      name: 'Test',
      createdAt: DateTime(2026, 1, 1),
      firstRoundMode: FirstRoundMode.registrationOrder,
      teams: [for (var i = 0; i < 6; i++) Team(id: 'team$i', name: 'Team $i')],
    );
    final matches = pairing.generateRound1(tournament);
    expect(matches.length, 3);
    expect(matches[0].teamAId, 'team0');
    expect(matches[0].teamBId, 'team1');
    expect(matches[1].teamAId, 'team2');
    expect(matches[1].teamBId, 'team3');
    expect(matches[2].teamAId, 'team4');
    expect(matches[2].teamBId, 'team5');
  });

  test('registrationOrder mode gives the bye to the last registered team when odd', () {
    final tournament = Tournament(
      id: 't',
      name: 'Test',
      createdAt: DateTime(2026, 1, 1),
      firstRoundMode: FirstRoundMode.registrationOrder,
      teams: [for (var i = 0; i < 5; i++) Team(id: 'team$i', name: 'Team $i')],
    );
    final matches = pairing.generateRound1(tournament);
    final bye = matches.firstWhere((m) => m.isBye);
    expect(bye.teamAId, 'team4');
  });
}
