import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/match.dart';
import '../models/round.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../services/notification_service.dart';
import '../services/pairing_service.dart';
import '../services/storage_service.dart';

/// Single source of truth for every tournament, backed by local JSON
/// storage. All screens read/write through this store so state changes
/// (scores, round advances, team edits) are persisted immediately.
class TournamentStore extends ChangeNotifier {
  TournamentStore({
    StorageService? storage,
    PairingService? pairing,
    NotificationService? notifications,
  })  : _storage = storage ?? StorageService(),
        _pairing = pairing ?? PairingService(),
        _notifications = notifications ?? NotificationService();

  final StorageService _storage;
  final PairingService _pairing;
  final NotificationService _notifications;
  final _uuid = const Uuid();

  List<Tournament> tournaments = [];
  bool loading = true;

  Future<void> init() async {
    await _notifications.init();
    tournaments = await _storage.loadAll();
    loading = false;
    notifyListeners();
  }

  Tournament tournamentById(String id) =>
      tournaments.firstWhere((t) => t.id == id);

  Future<void> _persist() async {
    await _storage.saveAll(tournaments);
    notifyListeners();
  }

  Future<Tournament> createTournament({
    required String name,
    int matchDurationMinutes = 35,
  }) async {
    final tournament = Tournament(
      id: _uuid.v4(),
      name: name,
      matchDurationMinutes: matchDurationMinutes,
      createdAt: DateTime.now(),
    );
    tournaments.add(tournament);
    await _persist();
    return tournament;
  }

  Future<void> deleteTournament(String id) async {
    tournaments.removeWhere((t) => t.id == id);
    await _persist();
  }

  /// Adds a team, trimming leading/trailing whitespace. Returns false
  /// without adding it if another team already has the same name (once
  /// both names are trimmed).
  Future<bool> addTeam(String tournamentId, String name) async {
    final tournament = tournamentById(tournamentId);
    final trimmed = name.trim();
    if (trimmed.isEmpty || _hasDuplicateName(tournament, trimmed)) {
      return false;
    }
    tournament.teams.add(Team(id: _uuid.v4(), name: trimmed));
    await _persist();
    return true;
  }

  Future<void> removeTeam(String tournamentId, String teamId) async {
    final tournament = tournamentById(tournamentId);
    tournament.teams.removeWhere((t) => t.id == teamId);
    await _persist();
  }

  /// Renames a team, trimming leading/trailing whitespace. Returns false
  /// without renaming it if another team already has the same name (once
  /// both names are trimmed).
  Future<bool> renameTeam(String tournamentId, String teamId, String newName) async {
    final tournament = tournamentById(tournamentId);
    final trimmed = newName.trim();
    if (trimmed.isEmpty || _hasDuplicateName(tournament, trimmed, excludingTeamId: teamId)) {
      return false;
    }
    tournament.teams.firstWhere((t) => t.id == teamId).name = trimmed;
    await _persist();
    return true;
  }

  bool _hasDuplicateName(Tournament tournament, String trimmedName, {String? excludingTeamId}) {
    return tournament.teams.any(
      (t) => t.id != excludingTeamId && t.name.trim() == trimmedName,
    );
  }

  Future<void> updateMatchDuration(String tournamentId, int minutes) async {
    final tournament = tournamentById(tournamentId);
    tournament.matchDurationMinutes = minutes;
    await _persist();
  }

  Future<void> startTournament(String tournamentId) async {
    final tournament = tournamentById(tournamentId);
    if (tournament.teams.length < 2) return;
    final matches = _pairing.generateRound1(tournament);
    await _startRound(tournament, 1, matches);
  }

  Future<void> submitScore(
    String tournamentId,
    String matchId,
    int scoreA,
    int scoreB,
  ) async {
    final tournament = tournamentById(tournamentId);
    final round = tournament.currentRound;
    if (round == null) return;
    final match = round.matches.firstWhere((m) => m.id == matchId);
    match.submitScore(scoreA, scoreB);
    await _persist();
  }

  bool canAdvance(Tournament tournament) {
    final round = tournament.currentRound;
    if (round == null) return false;
    if (tournament.status == TournamentStatus.finished) return false;
    return round.allMatchesFinished;
  }

  Future<void> advanceRound(String tournamentId) async {
    final tournament = tournamentById(tournamentId);
    if (!canAdvance(tournament)) return;

    switch (tournament.status) {
      case TournamentStatus.round1:
        final matches = _pairing.generateRound2(tournament);
        await _startRound(tournament, 2, matches);
      case TournamentStatus.round2:
        final matches = _pairing.generateRound3(tournament);
        await _startRound(tournament, 3, matches);
      case TournamentStatus.round3:
        tournament.status = TournamentStatus.finished;
        await _notifications.cancelRoundReminders();
        await _persist();
      case TournamentStatus.registration:
      case TournamentStatus.finished:
        break;
    }
  }

  Future<void> _startRound(
    Tournament tournament,
    int roundNumber,
    List<PetanqueMatch> matches,
  ) async {
    final round = Round(
      roundNumber: roundNumber,
      matches: matches,
      durationMinutes: tournament.matchDurationMinutes,
      startedAt: DateTime.now(),
    );
    tournament.rounds.add(round);
    tournament.status = TournamentStatus.values[roundNumber];
    await _notifications.scheduleRoundReminders(roundEnd: round.endsAt!);
    await _persist();
  }
}
