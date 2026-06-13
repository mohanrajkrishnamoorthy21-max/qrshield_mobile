class RiskFactor {
  final String id;
  final String name;
  final String description;
  final double scoreContribution;
  final bool isDetected;

  RiskFactor({
    required this.id,
    required this.name,
    required this.description,
    required this.scoreContribution,
    required this.isDetected,
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      scoreContribution: (json['score_contribution'] ?? 0.0).toDouble(),
      isDetected: json['is_detected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'score_contribution': scoreContribution,
      'is_detected': isDetected,
    };
  }
}
