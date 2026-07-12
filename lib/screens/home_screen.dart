import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tournament.dart';
import '../providers/tournament_store.dart';
import 'create_tournament_screen.dart';
import 'registration_screen.dart';
import 'round_screen.dart';
import 'standings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openTournament(BuildContext context, Tournament tournament) {
    final Widget screen = switch (tournament.status) {
      TournamentStatus.registration => RegistrationScreen(tournamentId: tournament.id),
      TournamentStatus.round1 ||
      TournamentStatus.round2 ||
      TournamentStatus.round3 =>
        RoundScreen(tournamentId: tournament.id),
      TournamentStatus.finished => StandingsScreen(tournamentId: tournament.id),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmDelete(BuildContext context, Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce tournoi ?'),
        content: Text('« ${tournament.name} » sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TournamentStore>().deleteTournament(tournament.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TournamentStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            _AppBarBadge(),
            SizedBox(width: 10),
            Text('Tournois Pétanque Cap Fun'),
          ],
        ),
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.tournaments.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
                  itemCount: store.tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = store.tournaments[store.tournaments.length - 1 - index];
                    return _TournamentCard(
                      tournament: tournament,
                      onTap: () => _openTournament(context, tournament),
                      onDelete: () => _confirmDelete(context, tournament),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTournamentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau tournoi'),
      ),
    );
  }
}

class _AppBarBadge extends StatelessWidget {
  const _AppBarBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/logo/capfun_petanque_icon.png',
        width: 30,
        height: 30,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.onTap,
    required this.onDelete,
  });

  final Tournament tournament;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor(scheme, tournament.status),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 15, color: scheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${tournament.teams.length} équipe(s)',
                          style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(width: 10),
                        _StatusChip(status: tournament.status),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: scheme.onSurface.withValues(alpha: 0.45),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, TournamentStatus status) => switch (status) {
        TournamentStatus.registration => scheme.secondary,
        TournamentStatus.round1 || TournamentStatus.round2 || TournamentStatus.round3 => scheme.primary,
        TournamentStatus.finished => scheme.tertiary,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      TournamentStatus.registration => ('Inscriptions', scheme.secondaryContainer, scheme.onSecondaryContainer),
      TournamentStatus.round1 => ('Round 1 / 3', scheme.primaryContainer, scheme.onPrimaryContainer),
      TournamentStatus.round2 => ('Round 2 / 3', scheme.primaryContainer, scheme.onPrimaryContainer),
      TournamentStatus.round3 => ('Round 3 / 3', scheme.primaryContainer, scheme.onPrimaryContainer),
      TournamentStatus.finished => ('Terminé 🏆', scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/capfun_petanque_icon.png', width: 140),
            const SizedBox(height: 24),
            Text(
              'Aucun tournoi pour le moment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez-en un avec le bouton ci-dessous.',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
