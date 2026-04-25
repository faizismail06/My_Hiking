class RecommendationModel {
  final int rank;
  final int routeId;
  final String routeName;
  final String mountainName;
  final double score;
  final String risk;
  final String explanation;
  final String keyFactor;
  final bool warning;

  const RecommendationModel({
    required this.rank,
    required this.routeId,
    required this.routeName,
    required this.mountainName,
    required this.score,
    required this.risk,
    this.explanation = '',
    this.keyFactor = '',
    this.warning = false,
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

    // Support both old 'risk' field and new 'risk_level' field
    final rawRisk = (json['risk_level'] ?? json['risk'] ?? '').toString();
    final risk = _normalizeRisk(rawRisk);

    return RecommendationModel(
      rank: rank ?? (fallbackRank ?? 0),
      routeId: routeId ?? 0,
      routeName: (json['route_name'] ?? '-').toString(),
      mountainName: (json['mountain_name'] ?? '-').toString(),
      score: score,
      risk: risk.isNotEmpty ? risk : _riskFromScore(score),
      explanation: (json['explanation'] ?? '').toString(),
      keyFactor: (json['key_factor'] ?? '').toString(),
      warning: json['warning'] is bool
          ? json['warning'] as bool
          : (json['warning']?.toString().toLowerCase() == 'true'),
    );
  }

  RecommendationModel copyWith({
    int? rank,
    int? routeId,
    String? routeName,
    String? mountainName,
    double? score,
    String? risk,
    String? explanation,
    String? keyFactor,
    bool? warning,
  }) {
    return RecommendationModel(
      rank: rank ?? this.rank,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      mountainName: mountainName ?? this.mountainName,
      score: score ?? this.score,
      risk: risk ?? this.risk,
      explanation: explanation ?? this.explanation,
      keyFactor: keyFactor ?? this.keyFactor,
      warning: warning ?? this.warning,
    );
  }

  static String _riskFromScore(double score) {
    if (score >= 0.80) return 'SAFE';
    if (score >= 0.70) return 'LOW';
    if (score >= 0.55) return 'MEDIUM';
    return 'HIGH';
  }

  static String _normalizeRisk(String raw) {
    final value = raw.trim().toUpperCase();
    if (value == 'HIGH_RISK') return 'HIGH';
    if (value == 'CAUTION') return 'MEDIUM';
    if (['SAFE', 'LOW', 'MEDIUM', 'HIGH'].contains(value)) return value;
    return '';
  }
}
