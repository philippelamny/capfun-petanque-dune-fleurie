class PetanqueMatch {
  final String id;
  final int roundNumber;
  final String teamAId;
  final String? teamBId; // null means teamA has a bye this round
  int? scoreA;
  int? scoreB;
  String? winnerId;
  bool finished;

  PetanqueMatch({
    required this.id,
    required this.roundNumber,
    required this.teamAId,
    this.teamBId,
    this.scoreA,
    this.scoreB,
    this.winnerId,
    this.finished = false,
  }) {
    if (isBye) {
      finished = true;
      winnerId = teamAId;
    }
  }

  bool get isBye => teamBId == null;

  void submitScore(int scoreA, int scoreB) {
    this.scoreA = scoreA;
    this.scoreB = scoreB;
    winnerId = scoreA > scoreB ? teamAId : teamBId;
    finished = true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundNumber': roundNumber,
        'teamAId': teamAId,
        'teamBId': teamBId,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'winnerId': winnerId,
        'finished': finished,
      };

  factory PetanqueMatch.fromJson(Map<String, dynamic> json) => PetanqueMatch(
        id: json['id'] as String,
        roundNumber: json['roundNumber'] as int,
        teamAId: json['teamAId'] as String,
        teamBId: json['teamBId'] as String?,
        scoreA: json['scoreA'] as int?,
        scoreB: json['scoreB'] as int?,
        winnerId: json['winnerId'] as String?,
        finished: json['finished'] as bool? ?? false,
      );
}
