import 'package:flutter/material.dart';

import '../models/match.dart';
import '../models/tournament.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.tournament,
    required this.onTap,
  });

  final PetanqueMatch match;
  final Tournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final teamA = tournament.teamById(match.teamAId);
    final teamB = match.teamBId != null ? tournament.teamById(match.teamBId!) : null;

    if (match.isBye) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.tertiaryContainer,
            child: Icon(Icons.spa_outlined, color: scheme.onTertiaryContainer),
          ),
          title: Text(teamA.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Exempt — victoire automatique'),
        ),
      );
    }

    final aWon = match.winnerId == teamA.id;
    final bWon = match.winnerId == teamB!.id;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      teamA.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: aWon ? FontWeight.w800 : FontWeight.w500,
                        color: aWon ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ),
                  _ScorePill(value: match.finished ? '${match.scoreA}' : '–', highlight: aWon),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('vs', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45), fontSize: 12)),
                  ),
                  _ScorePill(value: match.finished ? '${match.scoreB}' : '–', highlight: bWon),
                  Expanded(
                    child: Text(
                      teamB.name,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: bWon ? FontWeight.w800 : FontWeight.w500,
                        color: bWon ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    match.finished ? Icons.check_circle : Icons.timer_outlined,
                    size: 14,
                    color: match.finished ? const Color(0xFF3F8F5F) : scheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    match.finished ? 'Terminé' : 'Appuyez pour saisir le score',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.value, required this.highlight});

  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: highlight ? scheme.onPrimaryContainer : scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
