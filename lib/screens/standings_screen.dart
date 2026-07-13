import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tournament.dart';
import '../providers/tournament_store.dart';
import '../theme/app_theme.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TournamentStore>();
    final tournament = store.tournamentById(tournamentId);
    final standings = tournament.computeStandings();
    final scheme = Theme.of(context).colorScheme;
    final isFinal = tournament.status == TournamentStatus.finished;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tournament.name} — ${isFinal ? 'Classement' : 'Classement provisoire'}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        itemCount: standings.length,
        itemBuilder: (context, index) {
          final s = standings[index];
          final medal = isFinal ? _medalColor(index) : null;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: medal ?? scheme.surfaceContainerHighest,
                foregroundColor: medal != null ? Colors.white : scheme.onSurface.withValues(alpha: 0.6),
                child: isFinal && index == 0
                    ? const Icon(Icons.emoji_events, size: 20)
                    : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              title: Text(s.team.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${s.wins} victoire(s) · ${s.losses} défaite(s) · '
                '${s.pointsFor} pts marqués / ${s.pointsAgainst} encaissés',
              ),
              trailing: Text(
                '${s.diff >= 0 ? '+' : ''}${s.diff}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: s.diff >= 0 ? const Color(0xFF3F8F5F) : scheme.error,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color? _medalColor(int index) => switch (index) {
        0 => AppColors.spark,
        1 => AppColors.steel,
        2 => AppColors.cochonnet,
        _ => null,
      };
}
