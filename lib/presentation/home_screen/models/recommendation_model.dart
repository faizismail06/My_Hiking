class RecommendationModel {
  final int rank;
  final int routeId;
  final String routeName;
  final String mountainName;
  final double score;
  final String risk;

  const RecommendationModel({
    required this.rank,
    required this.routeId,
    required this.routeName,
    required this.mountainName,
    required this.score,
    required this.risk,
  });

  factory RecommendationModel.fromJson(
    Map<String, dynamic> json, {
    int? fallbackRank,
  }) {
    final parsedScore = json['score'] is String
        ? double.tryParse(json['score'])
        : (json['score'] as num?)?.toDouble();

    final score = parsedScore ?? 0.0;

    final rank = json['rank'] is String
        ? int.tryParse(json['rank'])
        : (json['rank'] as num?)?.toInt();

    final routeId = json['route_id'] is String
        ? int.tryParse(json['route_id'])
        : (json['route_id'] as num?)?.toInt();

    final risk = (json['risk'] ?? '').toString().trim().toUpperCase();

    return RecommendationModel(
      rank: rank ?? (fallbackRank ?? 0),
      routeId: routeId ?? 0,
      routeName: (json['route_name'] ?? '-').toString(),
      mountainName: (json['mountain_name'] ?? '-').toString(),
      score: score,
      risk: risk.isNotEmpty ? risk : _riskFromScore(score),
    );
  }

  RecommendationModel copyWith({
    int? rank,
    int? routeId,
    String? routeName,
    String? mountainName,
    double? score,
    String? risk,
  }) {
    return RecommendationModel(
      rank: rank ?? this.rank,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      mountainName: mountainName ?? this.mountainName,
      score: score ?? this.score,
      risk: risk ?? this.risk,
    );
  }

  static String _riskFromScore(double score) {
    if (score >= 0.80) {
      return 'SAFE';
    }
    if (score >= 0.70) {
      return 'LOW';
    }
    if (score >= 0.55) {
      return 'MEDIUM';
    }
    return 'HIGH';
  }
}
