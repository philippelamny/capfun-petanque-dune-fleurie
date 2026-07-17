import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/match.dart';
import '../models/team.dart';
import '../models/tournament.dart';

/// Builds the pairings for each round of a tournament.
///
/// Round 1 is either a random draw or teams paired in registration order,
/// depending on [Tournament.firstRoundMode]. From round 2 onward, teams are
/// grouped into "score groups" by number of wins (winners with winners,
/// losers with losers) and fold-paired within each group (best vs worst of
/// the group). When a score group has an odd number of teams, its weakest
/// team "floats down" and is paired against the best team of the next group
/// down — the classic Swiss-tournament pairdown rule. A randomized local
/// search is used to avoid rematches (two teams that already played each
/// other) whenever a rematch-free pairing exists.
///
/// Odd team counts get one team a bye each round. A team that has already
/// had a bye is never given another one.
class PairingService {
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  static const int _searchAttempts = 400;

  List<PetanqueMatch> generateRound1(Tournament tournament) {
    final ordered = List<Team>.from(tournament.teams);
    if (tournament.firstRoundMode == FirstRoundMode.random) {
      ordered.shuffle(_random);
    }
    // No history yet in round 1, so any team can take the bye; with
    // registration order it's the last-registered team that sits out.
    final bye = ordered.length.isOdd ? ordered.removeLast() : null;
    final matches = [
      for (var i = 0; i + 1 < ordered.length; i += 2)
        PetanqueMatch(
          id: _uuid.v4(),
          roundNumber: 1,
          teamAId: ordered[i].id,
          teamBId: ordered[i + 1].id,
        ),
    ];
    if (bye != null) matches.add(_byeMatch(bye, 1));
    return matches;
  }

  /// Generates any round from round 2 onward, pairing teams within their
  /// current win-count group (see class doc for the pairdown rule).
  List<PetanqueMatch> generateRound(Tournament tournament, {required int roundNumber}) {
    final standings = tournament.computeStandings();
    // Ranked strongest (most wins, best point diff) to weakest.
    final ranked = [for (final s in standings) s.team];
    final winsById = {for (final s in standings) s.team.id: s.wins};

    Team? bye;
    if (ranked.length.isOdd) {
      final alreadyByed = tournament.teamsWithBye();
      final eligible = ranked.where((t) => !alreadyByed.contains(t.id)).toList();
      // `eligible` should never be empty for a valid tournament: team count
      // is fixed for the whole tournament, so an odd count needs at most as
      // many distinct bye recipients as there are rounds. The full `ranked`
      // fallback only guards against that invariant somehow not holding.
      final pool = eligible.isNotEmpty ? eligible : ranked;
      bye = pool.last; // weakest team among those still eligible for a bye
      ranked.remove(bye);
    }

    final history = tournament.playedPairKeys();
    final matches = _swissPair(ranked, winsById, roundNumber: roundNumber, history: history);
    if (bye != null) matches.add(_byeMatch(bye, roundNumber));
    return matches;
  }

  // -- helpers --------------------------------------------------------

  /// Splits [ranked] into consecutive score groups (equal win count) and
  /// pairs within each group, floating a group's weakest team down to pair
  /// against the best team of the next group whenever a group is odd.
  List<PetanqueMatch> _swissPair(
    List<Team> ranked,
    Map<String, int> winsById, {
    required int roundNumber,
    required Set<String> history,
  }) {
    final groups = <List<Team>>[];
    for (final team in ranked) {
      if (groups.isNotEmpty && winsById[groups.last.first.id] == winsById[team.id]) {
        groups.last.add(team);
      } else {
        groups.add([team]);
      }
    }

    final matches = <PetanqueMatch>[];
    Team? carry;
    for (final group in groups) {
      final pool = List<Team>.from(group);
      if (carry != null) {
        final opponent = _bestAvailable(carry, pool, history);
        pool.remove(opponent);
        matches.add(_makeMatch(carry, opponent, roundNumber));
        carry = null;
      }
      if (pool.length.isOdd) {
        carry = pool.removeLast(); // weakest of this group floats down
      }
      matches.addAll(_foldPair(pool, roundNumber: roundNumber, history: history));
    }
    return matches;
  }

  /// Picks the best-ranked team in [pool] (assumed sorted best to worst)
  /// that [seeking] hasn't already played, falling back to the very best
  /// if every candidate would be a rematch.
  Team _bestAvailable(Team seeking, List<Team> pool, Set<String> history) {
    for (final candidate in pool) {
      if (!history.contains(pairKey(seeking.id, candidate.id))) return candidate;
    }
    return pool.first;
  }

  PetanqueMatch _makeMatch(Team a, Team b, int roundNumber) => PetanqueMatch(
        id: _uuid.v4(),
        roundNumber: roundNumber,
        teamAId: a.id,
        teamBId: b.id,
      );

  PetanqueMatch _byeMatch(Team team, int roundNumber) => PetanqueMatch(
        id: _uuid.v4(),
        roundNumber: roundNumber,
        teamAId: team.id,
      );

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
      for (var i = 0; i < upper.length; i++) _makeMatch(upper[i], bestLower[i], roundNumber),
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
