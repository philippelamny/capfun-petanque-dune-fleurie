import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tournament.dart';
import '../providers/tournament_store.dart';
import '../widgets/countdown_banner.dart';
import '../widgets/match_card.dart';
import 'score_entry_dialog.dart';
import 'standings_screen.dart';

class RoundScreen extends StatefulWidget {
  const RoundScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Ticks the UI every second so the countdown banner stays live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _openScoreDialog(TournamentStore store, Tournament tournament, String matchId) async {
    final round = tournament.currentRound!;
    final match = round.matches.firstWhere((m) => m.id == matchId);
    if (match.isBye) return;
    final result = await showScoreEntryDialog(context: context, tournament: tournament, match: match);
    if (result != null) {
      await store.submitScore(tournament.id, matchId, result.$1, result.$2);
    }
  }

  Future<void> _advance(TournamentStore store, Tournament tournament) async {
    final wasRound3 = tournament.status == TournamentStatus.round3;
    await store.advanceRound(tournament.id);
    if (!mounted) return;
    if (wasRound3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StandingsScreen(tournamentId: tournament.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TournamentStore>();
    final tournament = store.tournamentById(widget.tournamentId);
    final round = tournament.currentRound!;
    final roundNumber = round.roundNumber;
    final canAdvance = store.canAdvance(tournament);
    // Ranks only mean something once round 1 has produced results.
    final standings = roundNumber >= 2 ? tournament.computeStandings() : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tournament.name} — Round $roundNumber / 3'),
        actions: [
          if (roundNumber >= 2)
            IconButton(
              icon: const Icon(Icons.leaderboard_outlined),
              tooltip: 'Classement',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StandingsScreen(tournamentId: tournament.id)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (round.endsAt != null) CountdownBanner(endsAt: round.endsAt!),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: round.matches.length,
              itemBuilder: (context, index) {
                final match = round.matches[index];
                return MatchCard(
                  match: match,
                  tournament: tournament,
                  onTap: () => _openScoreDialog(store, tournament, match.id),
                  standings: standings,
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: canAdvance ? () => _advance(store, tournament) : null,
              icon: Icon(roundNumber == 3 ? Icons.emoji_events : Icons.arrow_forward),
              label: Text(
                canAdvance
                    ? (roundNumber == 3 ? 'Terminer le tournoi et voir le classement' : 'Passer au round ${roundNumber + 1}')
                    : 'Entrez tous les scores pour continuer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
