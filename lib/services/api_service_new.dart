import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/risk_engine.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String scanEndpoint = '/api/scan/';
  static const String historyEndpoint = '/api/history/';

  static Future<ScanResult> scanUrl(String url) async {
    print("ANALYSIS STARTED");
    // 1. Check local cache (SQLite) first to see if URL has been scanned within 24h
    try {
      final cachedResult = await DatabaseService.getScanResultByUrl(url);
      if (cachedResult != null) {
        print('Cache HIT: Reusing previous analysis for URL: $url');
        return cachedResult;
      }
    } catch (e) {
      print('Cache lookup failed: $e');
    }

    print('Cache MISS: Scanning URL: $url');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$scanEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'url': url}),
      ).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Parse result from API
        var apiResult = ScanResult.fromJson(data);
        
        // Enrich with client-side deterministic RiskEngine analysis
        // This ensures identical scoring metrics and factor checklists are computed.
        final localAnalysis = RiskEngine.analyzeUrl(url);
        
        final enrichedResult = apiResult.copyWith(
          score: localAnalysis.score,
          status: localAnalysis.verdict,
          riskAnalysis: localAnalysis,
        );

        // Save locally to cache and history
        await DatabaseService.insertScanResult(enrichedResult);
        return enrichedResult;
      } else {
        print('API returned status code: ${response.statusCode}. Falling back to local engine...');
        return _runLocalFallback(url);
      }
    } catch (e) {
      print('Network or API exception: $e. Running local deterministic engine...');
      return _runLocalFallback(url);
    }
  }

  // Runs local deterministic fallback scoring engine when API is unreachable
  static Future<ScanResult> _runLocalFallback(String url) async {
    final localAnalysis = RiskEngine.analyzeUrl(url);
    
    final features = SecurityFeatures(
      hasHttps: url.startsWith('https://'),
      hasIp: RegExp(r'^https?://\d+\.\d+\.\d+\.\d+').hasMatch(url),
      longUrl: url.length > 75,
      suspiciousKeyword: localAnalysis.verdict == 'SUSPICIOUS' || localAnalysis.verdict == 'DANGEROUS',
    );
    
    final fallbackResult = ScanResult(
      url: url,
      status: localAnalysis.verdict,
      score: localAnalysis.score,
      confidence: localAnalysis.confidence / 100.0,
      reasons: localAnalysis.detectedFactors.map((f) => f.description).toList(),
      recommendation: _getVerdictRecommendation(localAnalysis.verdict),
      features: features,
      riskAnalysis: localAnalysis,
      timestamp: DateTime.now(),
    );

    // Save fallback result locally so subsequent scans of this URL hit the cache instantly
    await DatabaseService.insertScanResult(fallbackResult);
    return fallbackResult;
  }

  static String _getVerdictRecommendation(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'SAFE':
        return 'This URL appears safe to visit. No threat indicators detected.';
      case 'LOW_RISK':
        return 'Low threat score. Proceed with standard caution.';
      case 'SUSPICIOUS':
        return 'Proceed with caution - verify the website validity before entering details.';
      case 'DANGEROUS':
      default:
        return 'Do not visit this website - it has been flagged as a dangerous phishing threat.';
    }
  }

  static Future<List<ScanResult>> getHistory() async {
    // Return history from SQLite DB since it represents our local storage
    return await DatabaseService.getAllScanResults();
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearHistory() async {
    await DatabaseService.clearAllHistory();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}
