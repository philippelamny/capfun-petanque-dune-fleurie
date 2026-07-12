import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/match.dart';
import '../models/tournament.dart';
import '../theme/app_theme.dart';

const int _maxPetanqueScore = 13;

/// Returns (scoreA, scoreB) or null if cancelled.
Future<(int, int)?> showScoreEntryDialog({
  required BuildContext context,
  required Tournament tournament,
  required PetanqueMatch match,
}) {
  final teamA = tournament.teamById(match.teamAId);
  final teamB = tournament.teamById(match.teamBId!);
  int scoreA = match.scoreA ?? 0;
  int scoreB = match.scoreB ?? 0;

  return showDialog<(int, int)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Score du match'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ScoreWheel(
                label: teamA.name,
                initialValue: scoreA,
                onChanged: (v) => setState(() => scoreA = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 46),
              child: Text(
                'vs',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ),
            Expanded(
              child: _ScoreWheel(
                label: teamB.name,
                initialValue: scoreB,
                onChanged: (v) => setState(() => scoreB = v),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (scoreA == scoreB) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Il ne peut pas y avoir d\'égalité, une équipe doit gagner.')),
                );
                return;
              }
              Navigator.pop(context, (scoreA, scoreB));
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    ),
  );
}

/// A roulette of boules, from 0 to 13 (pétanque's winning score) — you spin
/// to the score instead of typing it, so nothing outside that range is
/// reachable. Styled as steel boules rolling down a sandy lane, with the
/// selection marked by a red band, like a boule stopped mid-lane.
class _ScoreWheel extends StatefulWidget {
  const _ScoreWheel({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<_ScoreWheel> createState() => _ScoreWheelState();
}

class _ScoreWheelState extends State<_ScoreWheel> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          height: 176,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.sand, AppColors.sandDeep],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.steel, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
          ),
          clipBehavior: Clip.antiAlias,
          child: CupertinoPicker(
            scrollController: _controller,
            itemExtent: 52,
            diameterRatio: 1.15,
            useMagnifier: true,
            magnification: 1.12,
            selectionOverlay: const _LaneSelectionOverlay(),
            onSelectedItemChanged: widget.onChanged,
            children: [for (var i = 0; i <= _maxPetanqueScore; i++) _Boule(number: i)],
          ),
        ),
      ],
    );
  }
}

/// The red band marking the chosen score, like a boule that has come to
/// rest in the middle of the lane.
class _LaneSelectionOverlay extends StatelessWidget {
  const _LaneSelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.capfunRed.withValues(alpha: 0.85), width: 2),
          ),
          color: AppColors.capfunRed.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _Boule extends StatelessWidget {
  const _Boule({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final isMax = number == _maxPetanqueScore;
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: isMax
                ? [AppColors.spark, AppColors.sandDeep, const Color(0xFF8A5A16)]
                : [AppColors.steelLight, AppColors.steel, AppColors.steelDark],
            stops: const [0, 0.55, 1],
          ),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 17),
        ),
      ),
    );
  }
}
