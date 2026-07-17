import 'round.dart';
import 'team.dart';

enum TournamentStatus { registration, playing, finished }

/// How round 1 pairings are formed: a random draw, or teams paired in the
/// order they registered (team 1 vs team 2, team 3 vs team 4, ...).
enum FirstRoundMode { random, registrationOrder }

const int kMinRounds = 3;
const int kMaxRounds = 8;
const int kDefaultRounds = 3;

class TeamStanding {
  final Team team;
  int wins = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  TeamStanding(this.team);

  int get diff => pointsFor - pointsAgainst;
}

class Tournament {
  final String id;
  String name;
  int matchDurationMinutes;
  final DateTime createdAt;
  TournamentStatus status;
  final List<Team> teams;
  final List<Round> rounds;
  final FirstRoundMode firstRoundMode;
  final int numberOfRounds;

  Tournament({
    required this.id,
    required this.name,
    this.matchDurationMinutes = 35,
    required this.createdAt,
    this.status = TournamentStatus.registration,
    List<Team>? teams,
    List<Round>? rounds,
    this.firstRoundMode = FirstRoundMode.random,
    this.numberOfRounds = kDefaultRounds,
  })  : teams = teams ?? [],
        rounds = rounds ?? [];

  Round? get currentRound => rounds.isEmpty ? null : rounds.last;

  Team teamById(String id) => teams.firstWhere((t) => t.id == id);

  /// Standings computed from all finished matches so far, sorted by
  /// wins desc, then point difference desc, then name.
  List<TeamStanding> computeStandings() {
    final standings = {for (final t in teams) t.id: TeamStanding(t)};
    for (final round in rounds) {
      for (final m in round.matches) {
        if (!m.finished) continue;
        final a = standings[m.teamAId]!;
        if (m.isBye) {
          a.wins += 1;
          continue;
        }
        final b = standings[m.teamBId]!;
        a.pointsFor += m.scoreA ?? 0;
        a.pointsAgainst += m.scoreB ?? 0;
        b.pointsFor += m.scoreB ?? 0;
        b.pointsAgainst += m.scoreA ?? 0;
        if (m.winnerId == a.team.id) {
          a.wins += 1;
          b.losses += 1;
        } else {
          b.wins += 1;
          a.losses += 1;
        }
      }
    }
    final list = standings.values.toList();
    list.sort((x, y) {
      final winsCmp = y.wins.compareTo(x.wins);
      if (winsCmp != 0) return winsCmp;
      final diffCmp = y.diff.compareTo(x.diff);
      if (diffCmp != 0) return diffCmp;
      return x.team.name.compareTo(y.team.name);
    });
    return list;
  }

  /// Set of "teamIdA|teamIdB" (sorted) keys for every non-bye match already
  /// played, used to avoid rematches when generating later rounds.
  Set<String> playedPairKeys() {
    final keys = <String>{};
    for (final round in rounds) {
      for (final m in round.matches) {
        if (m.isBye) continue;
        keys.add(pairKey(m.teamAId, m.teamBId!));
      }
    }
    return keys;
  }

  /// Teams that already had a bye, so future byes can prefer someone else.
  Set<String> teamsWithBye() {
    final ids = <String>{};
    for (final round in rounds) {
      for (final m in round.matches) {
        if (m.isBye) ids.add(m.teamAId);
      }
    }
    return ids;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'matchDurationMinutes': matchDurationMinutes,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'teams': teams.map((t) => t.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'firstRoundMode': firstRoundMode.name,
        'numberOfRounds': numberOfRounds,
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        name: json['name'] as String,
        matchDurationMinutes: json['matchDurationMinutes'] as int? ?? 35,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: _statusFromJson(json['status'] as String),
        teams: (json['teams'] as List)
            .map((t) => Team.fromJson(t as Map<String, dynamic>))
            .toList(),
        rounds: (json['rounds'] as List)
            .map((r) => Round.fromJson(r as Map<String, dynamic>))
            .toList(),
        firstRoundMode: FirstRoundMode.values.firstWhere(
          (m) => m.name == json['firstRoundMode'],
          orElse: () => FirstRoundMode.random,
        ),
        numberOfRounds: json['numberOfRounds'] as int? ?? kDefaultRounds,
      );

  /// Older saved tournaments predate the generic `playing` status and used
  /// one enum value per round (`round1`, `round2`, `round3`); map those to
  /// `playing` so old JSON on a user's device keeps loading.
  static TournamentStatus _statusFromJson(String name) {
    switch (name) {
      case 'round1':
      case 'round2':
      case 'round3':
        return TournamentStatus.playing;
      default:
        return TournamentStatus.values.firstWhere(
          (s) => s.name == name,
          orElse: () => TournamentStatus.registration,
        );
    }
  }
}

String pairKey(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}|${sorted[1]}';
}
