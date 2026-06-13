import 'risk_factor.dart';

class LayerResult {
  final double normalizedScore;
  final double weight;
  final double contribution;
  final List<String> reasons;

  LayerResult({
    required this.normalizedScore,
    required this.weight,
    required this.contribution,
    required this.reasons,
  });

  factory LayerResult.fromJson(Map<String, dynamic> json) {
    return LayerResult(
      normalizedScore: (json['normalized_score'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      contribution: (json['contribution'] ?? 0.0).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'normalized_score': normalizedScore,
      'weight': weight,
      'contribution': contribution,
      'reasons': reasons,
    };
  }
}

class RiskAnalysisResult {
  final int score;
  final String verdict; // 'SAFE', 'LOW_RISK', 'SUSPICIOUS', 'HIGH_RISK', 'DANGEROUS'
  final int confidence; // 0-100
  final Map<String, LayerResult> layerBreakdown;
  final List<String> triggeredRules;
  final List<String> explanationTrace;
  final bool overrideApplied;
  final String engineVersion;
  final DateTime analysisTimestamp;
  final List<RiskFactor> detectedFactors;
  final String threatCategory;

  RiskAnalysisResult({
    required this.score,
    required this.verdict,
    required this.confidence,
    required this.layerBreakdown,
    required this.triggeredRules,
    required this.explanationTrace,
    required this.overrideApplied,
    required this.engineVersion,
    required this.threatCategory,
    required this.detectedFactors,
    DateTime? analysisTimestamp,
  }) : this.analysisTimestamp = analysisTimestamp ?? DateTime.now();

  factory RiskAnalysisResult.fromJson(Map<String, dynamic> json) {
    var breakdownJson = json['layer_breakdown'] as Map? ?? json['layerBreakdown'] as Map? ?? {};
    Map<String, LayerResult> breakdown = {};
    breakdownJson.forEach((key, val) {
      breakdown[key.toString()] = LayerResult.fromJson(Map<String, dynamic>.from(val));
    });

    var factorsList = json['detected_factors'] as List? ?? json['detectedFactors'] as List? ?? [];
    List<RiskFactor> factors = factorsList
        .map((f) => RiskFactor.fromJson(Map<String, dynamic>.from(f)))
        .toList();

    return RiskAnalysisResult(
      score: json['score'] ?? 0,
      verdict: json['verdict'] ?? 'SAFE',
      confidence: json['confidence'] ?? 85,
      layerBreakdown: breakdown,
      triggeredRules: List<String>.from(json['triggered_rules'] ?? json['triggeredRules'] ?? []),
      explanationTrace: List<String>.from(json['explanation_trace'] ?? json['explanationTrace'] ?? []),
      overrideApplied: json['override_applied'] ?? json['overrideApplied'] ?? false,
      engineVersion: json['engine_version'] ?? json['engineVersion'] ?? '1.0.0',
      threatCategory: json['threat_category'] ?? json['threatCategory'] ?? 'General',
      detectedFactors: factors,
      analysisTimestamp: json['analysis_timestamp'] != null
          ? DateTime.parse(json['analysis_timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'verdict': verdict,
      'confidence': confidence,
      'layerBreakdown': layerBreakdown.map((k, v) => MapEntry(k, v.toJson())),
      'layer_breakdown': layerBreakdown.map((k, v) => MapEntry(k, v.toJson())),
      'triggeredRules': triggeredRules,
      'triggered_rules': triggeredRules,
      'explanationTrace': explanationTrace,
      'explanation_trace': explanationTrace,
      'overrideApplied': overrideApplied,
      'override_applied': overrideApplied,
      'engineVersion': engineVersion,
      'engine_version': engineVersion,
      'threatCategory': threatCategory,
      'threat_category': threatCategory,
      'detectedFactors': detectedFactors.map((f) => f.toJson()).toList(),
      'detected_factors': detectedFactors.map((f) => f.toJson()).toList(),
      'analysisTimestamp': analysisTimestamp.toIso8601String(),
      'analysis_timestamp': analysisTimestamp.toIso8601String(),
    };
  }
}
