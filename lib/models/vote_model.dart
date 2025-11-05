class Vote {
  final String userId;
  final int jornada;
  final String matchId;
  final DateTime timestamp;

  Vote({
    required this.userId,
    required this.jornada,
    required this.matchId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'jornada': jornada,
    'matchId': matchId,
    'timestamp': timestamp.toIso8601String(),
  };

  static Vote fromJson(Map<String, dynamic> json) => Vote(
    userId: json['userId'] as String,
    jornada: (json['jornada'] as num).toInt(),
    matchId: json['matchId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  String toString() =>
      'Vote(userId: $userId, jornada: $jornada, matchId: $matchId, timestamp: $timestamp)';
}
