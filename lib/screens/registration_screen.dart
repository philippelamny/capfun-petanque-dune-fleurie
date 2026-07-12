import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tournament_store.dart';
import 'round_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _teamNameController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _addTeam(TournamentStore store) async {
    final name = _teamNameController.text.trim();
    if (name.isEmpty) return;
    final added = await store.addTeam(widget.tournamentId, name);
    if (!mounted) return;
    if (added) {
      _teamNameController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une équipe nommée « $name » est déjà inscrite.')),
      );
    }
  }

  Future<void> _startTournament(TournamentStore store) async {
    await store.startTournament(widget.tournamentId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RoundScreen(tournamentId: widget.tournamentId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TournamentStore>();
    final tournament = store.tournamentById(widget.tournamentId);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tournament.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamNameController,
                    decoration: const InputDecoration(
                      labelText: "Nom de l'équipe",
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addTeam(store),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => _addTeam(store),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: tournament.teams.isEmpty
                ? Center(
                    child: Text(
                      'Aucune équipe inscrite pour le moment.',
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: tournament.teams.length,
                    itemBuilder: (context, index) {
                      final team = tournament.teams[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.secondaryContainer,
                            foregroundColor: scheme.onSecondaryContainer,
                            child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: scheme.onSurface.withValues(alpha: 0.45),
                            onPressed: () => store.removeTeam(widget.tournamentId, team.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (tournament.teams.length.isOdd && tournament.teams.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nombre impair : une équipe sera exemptée à chaque round.',
                            style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                FilledButton.icon(
                  onPressed: tournament.teams.length >= 2 ? () => _startTournament(store) : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Lancer le tournoi (${tournament.teams.length} équipes)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
