import 'risk_analysis_result.dart';

class ScanResult {
  final String url;
  final String status;
  final int score;
  final double confidence;
  final List<String> reasons;
  final String recommendation;
  final SecurityFeatures features;
  final DateTime timestamp;
  final RiskAnalysisResult? riskAnalysis;

  ScanResult({
    required this.url,
    required this.status,
    required this.score,
    required this.confidence,
    required this.reasons,
    required this.recommendation,
    required this.features,
    this.riskAnalysis,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // Handle simplified backend response
    final url = json['url'] ?? '';
    final status = json['status'] ?? 'UNKNOWN';
    final score = json['score'] ?? 0;
    final confidence = (json['confidence'] ?? 0.85).toDouble();
    final reasons = List<String>.from(json['reasons'] ?? []);
    final recommendation = json['recommendation'] ?? '';
    
    // Create default security features if not provided
    SecurityFeatures features;
    if (json['features'] != null) {
      features = SecurityFeatures.fromJson(json['features']);
    } else {
      // Create basic features from the URL and status
      features = SecurityFeatures(
        hasHttps: url.startsWith('https://'),
        hasIp: RegExp(r'^https?://\d+\.\d+\.\d+\.\d+').hasMatch(url),
        longUrl: url.length > 75,
        suspiciousKeyword: status.toUpperCase() == 'PHISHING' || status.toUpperCase() == 'SUSPICIOUS',
      );
    }

    final riskAnalysis = json['risk_analysis'] != null
        ? RiskAnalysisResult.fromJson(Map<String, dynamic>.from(json['risk_analysis']))
        : null;
    
    return ScanResult(
      url: url,
      status: status,
      score: score,
      confidence: confidence,
      reasons: reasons,
      recommendation: recommendation,
      features: features,
      riskAnalysis: riskAnalysis,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'status': status,
      'score': score,
      'confidence': confidence,
      'reasons': reasons,
      'recommendation': recommendation,
      'features': features.toJson(),
      'risk_analysis': riskAnalysis?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  ScanResult copyWith({
    String? url,
    String? status,
    int? score,
    double? confidence,
    List<String>? reasons,
    String? recommendation,
    SecurityFeatures? features,
    RiskAnalysisResult? riskAnalysis,
    DateTime? timestamp,
  }) {
    return ScanResult(
      url: url ?? this.url,
      status: status ?? this.status,
      score: score ?? this.score,
      confidence: confidence ?? this.confidence,
      reasons: reasons ?? this.reasons,
      recommendation: recommendation ?? this.recommendation,
      features: features ?? this.features,
      riskAnalysis: riskAnalysis ?? this.riskAnalysis,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isSafe => status.toUpperCase() == 'SAFE';
  bool get isSuspicious => status.toUpperCase() == 'SUSPICIOUS' || status.toUpperCase() == 'LOW_RISK';
  bool get isPhishing => status.toUpperCase() == 'PHISHING' || status.toUpperCase() == 'DANGEROUS';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanResult &&
        other.url == url &&
        other.status == status &&
        other.score == score &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return url.hashCode ^
        status.hashCode ^
        score.hashCode ^
        confidence.hashCode;
  }

  @override
  String toString() {
    return 'ScanResult(url: $url, status: $status, score: $score, confidence: $confidence)';
  }
}

class SecurityFeatures {
  final bool hasHttps;
  final bool hasIp;
  final bool longUrl;
  final bool suspiciousKeyword;

  SecurityFeatures({
    required this.hasHttps,
    required this.hasIp,
    required this.longUrl,
    required this.suspiciousKeyword,
  });

  factory SecurityFeatures.fromJson(Map<String, dynamic> json) {
    return SecurityFeatures(
      hasHttps: json['has_https'] ?? false,
      hasIp: json['has_ip'] ?? false,
      longUrl: json['long_url'] ?? false,
      suspiciousKeyword: json['suspicious_keyword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_https': hasHttps,
      'has_ip': hasIp,
      'long_url': longUrl,
      'suspicious_keyword': suspiciousKeyword,
    };
  }

  SecurityFeatures copyWith({
    bool? hasHttps,
    bool? hasIp,
    bool? longUrl,
    bool? suspiciousKeyword,
  }) {
    return SecurityFeatures(
      hasHttps: hasHttps ?? this.hasHttps,
      hasIp: hasIp ?? this.hasIp,
      longUrl: longUrl ?? this.longUrl,
      suspiciousKeyword: suspiciousKeyword ?? this.suspiciousKeyword,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityFeatures &&
        other.hasHttps == hasHttps &&
        other.hasIp == hasIp &&
        other.longUrl == longUrl &&
        other.suspiciousKeyword == suspiciousKeyword;
  }

  @override
  int get hashCode {
    return hasHttps.hashCode ^
        hasIp.hashCode ^
        longUrl.hashCode ^
        suspiciousKeyword.hashCode;
  }

  @override
  String toString() {
    return 'SecurityFeatures(hasHttps: $hasHttps, hasIp: $hasIp, longUrl: $longUrl, suspiciousKeyword: $suspiciousKeyword)';
  }
}
