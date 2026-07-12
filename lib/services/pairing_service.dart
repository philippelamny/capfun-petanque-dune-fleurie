import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/match.dart';
import '../models/team.dart';
import '../models/tournament.dart';

/// Builds the pairings for each of the 3 rounds of a tournament.
///
/// Round 1 is fully random. Rounds 2 and 3 rank teams by current standings
/// (wins, then point difference) and pair the top half against the bottom
/// half ("fold" pairing, best against worst). A randomized local search is
/// used to avoid rematches (two teams that already played each other)
/// whenever a rematch-free pairing exists.
///
/// Odd team counts get one team a bye each round. A team that has already
/// had a bye is never given another one — with team count fixed for the
/// whole tournament and only 3 rounds, there are always enough distinct
/// teams to give each bye to a different team.
class PairingService {
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  static const int _searchAttempts = 400;

  List<PetanqueMatch> generateRound1(Tournament tournament) {
    final pool = List<Team>.from(tournament.teams)..shuffle(_random);
    // No history yet in round 1, so any team can take the bye.
    final bye = pool.length.isOdd ? pool.removeLast() : null;
    final matches = _pairSequentially(pool, roundNumber: 1, history: {});
    if (bye != null) {
      matches.add(_byeMatch(bye, 1));
    }
    return matches;
  }

  List<PetanqueMatch> generateRound2(Tournament tournament) =>
      _generateRankedRound(tournament, roundNumber: 2);

  List<PetanqueMatch> generateRound3(Tournament tournament) =>
      _generateRankedRound(tournament, roundNumber: 3);

  // -- helpers --------------------------------------------------------

  /// Ranks teams by current standings (most wins, best point difference,
  /// first) and fold-pairs the top half against the bottom half. The team
  /// that rests on an odd count is the weakest team that has never had a
  /// bye before — a team can only ever sit out once across the tournament.
  List<PetanqueMatch> _generateRankedRound(
    Tournament tournament, {
    required int roundNumber,
  }) {
    final standings = tournament.computeStandings();
    // Ranked strongest (most wins, best point diff) to weakest.
    final ranked = [for (final s in standings) s.team];

    Team? bye;
    if (ranked.length.isOdd) {
      final alreadyByed = tournament.teamsWithBye();
      final eligible = ranked.where((t) => !alreadyByed.contains(t.id)).toList();
      // `eligible` should never be empty for a valid tournament: team count
      // is fixed for all 3 rounds, so an odd count needs at most 3 distinct
      // bye recipients. The full `ranked` fallback only guards against that
      // invariant somehow not holding.
      final pool = eligible.isNotEmpty ? eligible : ranked;
      bye = pool.last; // weakest team among those still eligible for a bye
      ranked.remove(bye);
    }

    final history = tournament.playedPairKeys();
    final matches = _foldPair(ranked, roundNumber: roundNumber, history: history);
    if (bye != null) matches.add(_byeMatch(bye, roundNumber));
    return matches;
  }

  PetanqueMatch _byeMatch(Team team, int roundNumber) => PetanqueMatch(
        id: _uuid.v4(),
        roundNumber: roundNumber,
        teamAId: team.id,
      );

  /// Randomly shuffles [teams] and pairs them adjacently, searching for an
  /// ordering with as few history rematches as possible.
  List<PetanqueMatch> _pairSequentially(
    List<Team> teams, {
    required int roundNumber,
    required Set<String> history,
  }) {
    if (teams.isEmpty) return [];
    List<Team> best = List.of(teams)..shuffle(_random);
    int bestConflicts = _sequentialConflicts(best, history);
    for (var i = 0; i < _searchAttempts && bestConflicts > 0; i++) {
      final candidate = List.of(teams)..shuffle(_random);
      final conflicts = _sequentialConflicts(candidate, history);
      if (conflicts < bestConflicts) {
        bestConflicts = conflicts;
        best = candidate;
      }
    }
    return [
      for (var i = 0; i + 1 < best.length; i += 2)
        PetanqueMatch(
          id: _uuid.v4(),
          roundNumber: roundNumber,
          teamAId: best[i].id,
          teamBId: best[i + 1].id,
        ),
    ];
  }

  int _sequentialConflicts(List<Team> teams, Set<String> history) {
    var conflicts = 0;
    for (var i = 0; i + 1 < teams.length; i += 2) {
      if (history.contains(pairKey(teams[i].id, teams[i + 1].id))) {
        conflicts++;
      }
    }
    return conflicts;
  }

  /// Pairs the strongest half of [ranked] against the weakest half
  /// (index-for-index), searching for a rematch-free ordering of the
  /// weaker half.
  List<PetanqueMatch> _foldPair(
    List<Team> ranked, {
    required int roundNumber,
    required Set<String> history,
  }) {
    if (ranked.isEmpty) return [];
    final half = ranked.length ~/ 2;
    final upper = ranked.sublist(0, half);
    final lower = ranked.sublist(half);

    List<Team> bestLower = List.of(lower);
    int bestConflicts = _foldConflicts(upper, bestLower, history);
    for (var i = 0; i < _searchAttempts && bestConflicts > 0; i++) {
      final candidate = List.of(lower)..shuffle(_random);
      final conflicts = _foldConflicts(upper, candidate, history);
      if (conflicts < bestConflicts) {
        bestConflicts = conflicts;
        bestLower = candidate;
      }
    }
    return [
      for (var i = 0; i < upper.length; i++)
        PetanqueMatch(
          id: _uuid.v4(),
          roundNumber: roundNumber,
          teamAId: upper[i].id,
          teamBId: bestLower[i].id,
        ),
    ];
  }

  int _foldConflicts(List<Team> upper, List<Team> lower, Set<String> history) {
    var conflicts = 0;
    for (var i = 0; i < upper.length; i++) {
      if (history.contains(pairKey(upper[i].id, lower[i].id))) conflicts++;
    }
    return conflicts;
  }
}
