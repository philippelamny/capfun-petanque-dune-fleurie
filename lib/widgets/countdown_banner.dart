import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Colour-coded round countdown: calm green while there's time, warm gold
/// inside the last 5 minutes, brand red inside the last 2 minutes
/// ("dernière mène"), and a deep red once time is up.
class CountdownBanner extends StatelessWidget {
  const CountdownBanner({super.key, required this.endsAt});

  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final remaining = endsAt.difference(DateTime.now());
    final Color color;
    final IconData icon;
    final String label;
    if (remaining.isNegative) {
      color = RoundClockColors.expired;
      icon = Icons.timer_off_outlined;
      label = 'Temps écoulé — entrez les scores';
    } else if (remaining.inSeconds <= 120) {
      color = RoundClockColors.urgent;
      icon = Icons.sports_bar_outlined;
      label = 'Dernière mène ! ${_format(remaining)}';
    } else if (remaining.inSeconds <= 300) {
      color = RoundClockColors.warning;
      icon = Icons.timer_outlined;
      label = 'Plus que quelques minutes ! ${_format(remaining)}';
    } else {
      color = RoundClockColors.calm;
      icon = Icons.timer_outlined;
      label = 'Temps restant : ${_format(remaining)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
