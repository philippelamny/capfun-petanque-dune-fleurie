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

      final round2Matches = pairing.generateRound2(tournament);
      tournament.rounds.add(
        Round(roundNumber: 2, matches: round2Matches, durationMinutes: 35),
      );
      _playRound(tournament, tournament.rounds[1]);

      final round3Matches = pairing.generateRound3(tournament);
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

      // Best-vs-worst check for rounds 2 and 3: for every non-bye match,
      // the paired teams should not both come from the same half of the
      // pre-round standings (i.e. it's not "winners vs winners").
      for (final roundIndex in [1, 2]) {
        final round = tournament.rounds[roundIndex];
        final standingsBefore = Tournament(
          id: 't',
          name: 'snapshot',
          createdAt: DateTime(2026, 1, 1),
          teams: tournament.teams,
          rounds: tournament.rounds.sublist(0, roundIndex),
        ).computeStandings();
        final rank = {
          for (var i = 0; i < standingsBefore.length; i++) standingsBefore[i].team.id: i,
        };
        for (final match in round.matches) {
          if (match.isBye) continue;
          final rankA = rank[match.teamAId]!;
          final rankB = rank[match.teamBId]!;
          final half = standingsBefore.length ~/ 2;
          final sameHalf = (rankA < half) == (rankB < half);
          expect(sameHalf, isFalse,
              reason:
                  'round ${round.roundNumber}: ${match.teamAId} (rank $rankA) vs ${match.teamBId} (rank $rankB) should pair across the best/worst split');
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

    final round2 = pairing.generateRound2(tournament);
    tournament.rounds.add(Round(roundNumber: 2, matches: round2, durationMinutes: 35));
    _playRound(tournament, tournament.rounds[1]);

    final round1Keys = round1.where((m) => !m.isBye).map((m) => pairKey(m.teamAId, m.teamBId!)).toSet();
    for (final match in round2.where((m) => !m.isBye)) {
      final key = pairKey(match.teamAId, match.teamBId!);
      expect(round1Keys.contains(key), isFalse, reason: 'round 2 rematch: $key');
    }

    final round3 = pairing.generateRound3(tournament);
    final playedBefore = {...round1Keys, ...round2.where((m) => !m.isBye).map((m) => pairKey(m.teamAId, m.teamBId!))};
    for (final match in round3.where((m) => !m.isBye)) {
      final key = pairKey(match.teamAId, match.teamBId!);
      expect(playedBefore.contains(key), isFalse, reason: 'round 3 rematch: $key');
    }
  });
}
