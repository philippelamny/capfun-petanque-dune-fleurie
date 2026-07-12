import 'match.dart';

class Round {
  final int roundNumber;
  final List<PetanqueMatch> matches;
  DateTime? startedAt;
  final int durationMinutes;

  Round({
    required this.roundNumber,
    required this.matches,
    required this.durationMinutes,
    this.startedAt,
  });

  bool get allMatchesFinished => matches.every((m) => m.finished);

  DateTime? get endsAt =>
      startedAt?.add(Duration(minutes: durationMinutes));

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'matches': matches.map((m) => m.toJson()).toList(),
        'startedAt': startedAt?.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        roundNumber: json['roundNumber'] as int,
        matches: (json['matches'] as List)
            .map((m) => PetanqueMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        durationMinutes: json['durationMinutes'] as int,
      );
}
