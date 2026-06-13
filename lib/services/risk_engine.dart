import 'dart:math';
import '../models/risk_factor.dart';
import '../models/risk_analysis_result.dart';

class RiskEngine {
  static const String currentVersion = '2.0.0';

  // Strict Layer Weights (Sum to 1.0)
  static const double weightA = 0.30; // Reputation Analysis
  static const double weightB = 0.25; // Brand Impersonation & Typosquatting
  static const double weightC = 0.20; // URL Structure Analysis
  static const double weightD = 0.10; // Credential Theft Signals
  static const double weightE = 0.05; // HTTPS & Security Signals
  static const double weightF = 0.10; // Redirect & Payload Signals

  static const List<String> blacklistDomains = [
    'phishing-test.com',
    'paypal-verify.net',
    'amazon-login-update.com',
    'google-security-update.net',
    'malicious-site.org',
    'secure-login-chase.com',
    'verify-apple-account.info'
  ];

  static const List<String> suspiciousTlds = [
    '.xyz', '.top', '.click', '.zip', '.fit', '.tk', '.cn', '.cc', '.su',
    '.work', '.download', '.site', '.gq', '.cf', '.ml', '.ga'
  ];

  static const List<String> trustedDomains = [
    'google.com',
    'apple.com',
    'microsoft.com',
    'amazon.com',
    'openai.com',
    'chat.openai.com',
    'whatsapp.com',
    'instagram.com'
  ];

  static const List<String> urlShorteners = [
    'bit.ly', 'tinyurl.com', 't.co', 'is.gd', 'buff.ly', 
    'rebrand.ly', 'adf.ly', 'goo.gl', 'ow.ly', 't.ly'
  ];

  static const List<String> protectedBrands = [
    'google', 'apple', 'microsoft', 'amazon', 'paypal', 'openai', 'chatgpt',
    'facebook', 'instagram', 'whatsapp', 'telegram', 'netflix', 'chase', 'citibank'
  ];

  static const Map<String, String> brandOfficialDomains = {
    'google': 'google.com',
    'apple': 'apple.com',
    'microsoft': 'microsoft.com',
    'amazon': 'amazon.com',
    'paypal': 'paypal.com',
    'openai': 'openai.com',
    'chatgpt': 'openai.com',
    'facebook': 'facebook.com',
    'instagram': 'instagram.com',
    'whatsapp': 'whatsapp.com',
    'telegram': 'telegram.org',
    'netflix': 'netflix.com',
    'chase': 'chase.com',
    'citibank': 'citibank.com'
  };

  static const List<String> credentialKeywords = [
    'login', 'verify', 'update', 'secure', 'account', 'password', 'confirm', 'bank', 'wallet', 'security'
  ];

  static const List<String> intentKeywords = [
    'login', 'verify', 'secure', 'update', 'account', 'password', 'bank', 'security'
  ];

  static RiskAnalysisResult analyzeUrl(String urlString, {int? realDomainAgeDays}) {
    final List<String> triggeredRules = [];
    final List<String> explanationTrace = [];

    // URL Parsing and Normalization
    String processedUrl = urlString.trim();
    if (!processedUrl.contains('://')) {
      processedUrl = 'https://$processedUrl';
    }

    Uri? uri;
    try {
      uri = Uri.parse(processedUrl);
    } catch (_) {}

    final String host = uri?.host.toLowerCase() ?? '';
    final String scheme = uri?.scheme.toLowerCase() ?? '';
    final String path = uri?.path.toLowerCase() ?? '';
    final String query = uri?.query.toLowerCase() ?? '';

    explanationTrace.add('Parsed URL: Host="$host", Scheme="$scheme", Path="$path", Query="$query"');

    // Extract host tokens for typosquatting / brand check
    final List<String> tokens = _getDomainTokens(host);
    explanationTrace.add('Extracted host tokens: $tokens');

    // Detect typosquatting and brand impersonation variables
    bool isConfirmedTyposquatting = false;
    bool brandSimilarityMatch = false;
    String matchedBrand = '';
    bool hasIntent = false;
    bool brandInSubdomain = false;
    bool brandPathCredentials = false;

    // Check intent keywords presence
    for (final keyword in intentKeywords) {
      if (host.contains(keyword) || path.contains(keyword) || query.contains(keyword)) {
        hasIntent = true;
        break;
      }
    }

    // Determine brand details
    for (final brand in protectedBrands) {
      final official = brandOfficialDomains[brand] ?? '';
      
      // If the host is official, skip brand Impersonation/typosquatting checks for this brand
      if (host == official || host.endsWith('.$official')) {
        continue;
      }

      // Check each token
      for (final token in tokens) {
        final variants = _getLeetspeakVariants(token);
        
        // Check direct brand presence
        if (token.contains(brand)) {
          brandSimilarityMatch = true;
          matchedBrand = brand;
          
          // Check brand in subdomain
          final dotParts = host.split('.');
          if (dotParts.length > 2) {
            // Find if brand is in subdomain parts (everything except main domain + TLD)
            // e.g., in sub.paypal.com, dotParts are ['sub', 'paypal', 'com']. TLD is 'com', main label is 'paypal'.
            // If the brand name matches or is in parts before the main label.
            // Let's check:
            final mainLabelIdx = dotParts.length - 2;
            for (int i = 0; i < mainLabelIdx; i++) {
              if (dotParts[i].contains(brand)) {
                brandInSubdomain = true;
              }
            }
          }
        }

        // Check typosquatting
        if (_isTyposquatted(brand, token, variants)) {
          isConfirmedTyposquatting = true;
          brandSimilarityMatch = true;
          matchedBrand = brand;
        }
      }

      // Check brand + credential path usage
      if (brandSimilarityMatch) {
        for (final kw in credentialKeywords) {
          if (path.contains(kw)) {
            brandPathCredentials = true;
            break;
          }
        }
      }
    }

    final bool hasStructuralMimicry = brandInSubdomain || brandPathCredentials;

    // Layer A: Reputation Analysis (30% weight)
    final List<String> reasonsA = [];
    double scoreA = 0.0;
    bool blacklistMatch = false;

    for (final blacklisted in blacklistDomains) {
      if (host == blacklisted || host.endsWith('.$blacklisted')) {
        blacklistMatch = true;
        break;
      }
    }

    if (blacklistMatch) {
      scoreA = 100.0;
      reasonsA.add('Domain matches known phishing blacklist');
      triggeredRules.add('blacklist_reputation_match');
    } else if (isConfirmedTyposquatting) {
      scoreA = 95.0;
      reasonsA.add('Suspicious reputation due to confirmed typosquatting');
      triggeredRules.add('reputation_typosquatting');
    } else {
      String matchedTld = '';
      bool tldMatch = false;
      for (final tld in suspiciousTlds) {
        if (host.endsWith(tld)) {
          tldMatch = true;
          matchedTld = tld;
          break;
        }
      }
      if (tldMatch) {
        scoreA = 60.0;
        reasonsA.add('Suspicious TLD used: $matchedTld');
        triggeredRules.add('reputation_suspicious_tld');
      } else {
        scoreA = 0.0;
        reasonsA.add('Clean reputation / Unknown benign domain');
      }
    }

    final layerResultA = LayerResult(
      normalizedScore: scoreA,
      weight: weightA,
      contribution: scoreA * weightA,
      reasons: reasonsA,
    );

    // Layer B: Brand Impersonation & Typosquatting (25% weight)
    final List<String> reasonsB = [];
    double scoreB = 0.0;

    if (brandSimilarityMatch) {
      if (hasIntent) {
        triggeredRules.add('brand_impersonation_detected');
        if (hasStructuralMimicry) {
          scoreB = 100.0;
          reasonsB.add('Brand impersonation of "$matchedBrand" with structural mimicry and intent signals');
          triggeredRules.add('brand_impersonation_structural_mimicry');
        } else {
          scoreB = 85.0;
          reasonsB.add('Brand impersonation of "$matchedBrand" with malicious intent signals');
        }
      } else if (isConfirmedTyposquatting) {
        scoreB = 85.0;
        reasonsB.add('Confirmed typosquatting of protected brand "$matchedBrand"');
        triggeredRules.add('confirmed_brand_typosquatting');
      } else {
        scoreB = 5.0;
        reasonsB.add('Protected brand keyword "$matchedBrand" present (low-severity context)');
      }
    } else {
      scoreB = 0.0;
      reasonsB.add('No brand impersonation or typosquatting indicators');
    }

    final layerResultB = LayerResult(
      normalizedScore: scoreB,
      weight: weightB,
      contribution: scoreB * weightB,
      reasons: reasonsB,
    );

    // Layer C: URL Structure Analysis (20% weight)
    final List<String> reasonsC = [];
    double scoreC = 0.0;

    // Subdomain count
    final dots = host.split('.').length - 1;
    if (dots > 3) {
      scoreC += 40.0;
      reasonsC.add('Excessive subdomains: $dots');
      triggeredRules.add('excessive_subdomains');
    }

    // IP-based domain
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegex.hasMatch(host)) {
      scoreC += 70.0;
      reasonsC.add('IP address used as host');
      triggeredRules.add('ip_host_detected');
    }

    // URL Shorteners
    bool shortenerMatch = false;
    for (final shortener in urlShorteners) {
      if (host == shortener || host.endsWith('.$shortener')) {
        shortenerMatch = true;
        break;
      }
    }
    if (shortenerMatch) {
      scoreC += 50.0;
      reasonsC.add('URL shortening service used');
      triggeredRules.add('shortener_domain_detected');
    }

    // Homograph/Punycode check
    if (host.startsWith('xn--')) {
      scoreC += 80.0;
      reasonsC.add('Punycode internationalized domain detected (xn--)');
      triggeredRules.add('punycode_host_detected');
    }

    // Long URL checks
    if (urlString.length > 120) {
      scoreC += 20.0;
      reasonsC.add('Unusually long URL length (${urlString.length} chars)');
    }

    // Random character strings (entropy)
    final alphanumericLength = host.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').length;
    final digitsCount = host.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (alphanumericLength > 15 && (digitsCount / alphanumericLength) > 0.45) {
      scoreC += 40.0;
      reasonsC.add('High entropy / random numeric host string');
    }

    // Typosquatting structure impact
    if (isConfirmedTyposquatting) {
      scoreC += 80.0;
      reasonsC.add('Typosquatted homograph structure anomaly');
    }

    scoreC = scoreC.clamp(0.0, 100.0);
    if (reasonsC.isEmpty) {
      reasonsC.add('URL structure is clean');
    }

    final layerResultC = LayerResult(
      normalizedScore: scoreC,
      weight: weightC,
      contribution: scoreC * weightC,
      reasons: reasonsC,
    );

    // Layer D: Credential Theft Signals (10% weight)
    final List<String> reasonsD = [];
    double scoreD = 0.0;
    bool keywordInSubdomain = false;
    bool keywordInPath = false;
    bool keywordInQuery = false;
    String matchedKeyword = '';

    bool keywordAlone = false;

    for (final keyword in credentialKeywords) {
      // Check subdomain
      final parts = host.split('.');
      if (parts.length > 2) {
        for (int i = 0; i < parts.length - 2; i++) {
          if (parts[i].contains(keyword)) {
            keywordInSubdomain = true;
            matchedKeyword = keyword;
            break;
          }
        }
      }
      // Check path
      if (path.contains(keyword)) {
        keywordInPath = true;
        matchedKeyword = keyword;
      }
      // Check query
      if (query.contains(keyword)) {
        keywordInQuery = true;
        matchedKeyword = keyword;
      }
      // Check alone (anywhere in host or query or path)
      if (host.contains(keyword) || path.contains(keyword) || query.contains(keyword)) {
        keywordAlone = true;
        if (matchedKeyword.isEmpty) {
          matchedKeyword = keyword;
        }
      }
    }

    if (keywordInSubdomain) {
      scoreD = 90.0;
      reasonsD.add('Credential harvesting keyword "$matchedKeyword" in subdomain');
      triggeredRules.add('credential_keyword_subdomain');
    } else if (keywordInPath) {
      scoreD = 50.0;
      reasonsD.add('Credential harvesting keyword "$matchedKeyword" in URL path');
      triggeredRules.add('credential_keyword_path');
    } else if (keywordInQuery) {
      scoreD = 20.0;
      reasonsD.add('Credential harvesting keyword "$matchedKeyword" in query parameters');
      triggeredRules.add('credential_keyword_query');
    } else if (keywordAlone) {
      scoreD = 20.0;
      reasonsD.add('Credential harvesting keyword "$matchedKeyword" present in domain label');
      triggeredRules.add('credential_keyword_alone');
    }

    // Boost risk if combined with brand similarity
    if (scoreD > 0 && brandSimilarityMatch) {
      scoreD += 30.0;
      reasonsD.add('Credential harvesting combined with brand similarity');
      triggeredRules.add('credential_harvesting_impersonation');
    }

    scoreD = scoreD.clamp(0.0, 100.0);
    if (reasonsD.isEmpty) {
      reasonsD.add('No credential theft signals detected');
    }

    final layerResultD = LayerResult(
      normalizedScore: scoreD,
      weight: weightD,
      contribution: scoreD * weightD,
      reasons: reasonsD,
    );

    // Layer E: HTTPS & Security Signals (5% weight)
    final List<String> reasonsE = [];
    double scoreE = 0.0;

    if (scheme == 'http') {
      scoreE = 100.0;
      reasonsE.add('Unencrypted protocol scheme (HTTP)');
      triggeredRules.add('http_scheme_detected');
    } else if (urlString.contains('invalid-ssl') || urlString.contains('expired-ssl')) {
      scoreE = 60.0;
      reasonsE.add('Invalid SSL configuration keywords detected');
    } else {
      scoreE = 0.0;
      reasonsE.add('Secure HTTPS connection');
    }

    final layerResultE = LayerResult(
      normalizedScore: scoreE,
      weight: weightE,
      contribution: scoreE * weightE,
      reasons: reasonsE,
    );

    // Layer F: Redirect & Payload Signals (10% weight)
    final List<String> reasonsF = [];
    double scoreF = 0.0;

    // Check suspicious protocol scheme
    if (scheme != 'http' && scheme != 'https') {
      scoreF += 80.0;
      reasonsF.add('Suspicious URL protocol scheme: "$scheme:"');
      triggeredRules.add('non_standard_scheme');
    }

    // Redirect parameters in query string
    final hasRedirectParams = query.contains('url=') ||
        query.contains('redirect=') ||
        query.contains('next=') ||
        query.contains('to=') ||
        query.contains('dest=');
    if (hasRedirectParams && (query.contains('http%3a%2f%2f') || query.contains('https%3a%2f%2f') || query.contains('http://') || query.contains('https://'))) {
      scoreF += 60.0;
      reasonsF.add('URL query parameters contain external redirection links');
      triggeredRules.add('redirect_parameter_detected');
    }

    // Base64 obfuscation/Script detection
    if (query.contains('<script') || path.contains('<script') || query.contains('base64') || query.contains('onload')) {
      scoreF += 90.0;
      reasonsF.add('Payload contains script elements or base64 parameters');
      triggeredRules.add('script_obfuscation_detected');
    }

    scoreF = scoreF.clamp(0.0, 100.0);
    if (reasonsF.isEmpty) {
      reasonsF.add('No redirect or payload exploits detected');
    }

    final layerResultF = LayerResult(
      normalizedScore: scoreF,
      weight: weightF,
      contribution: scoreF * weightF,
      reasons: reasonsF,
    );

    // Calculate final weighted sum
    double rawScore = layerResultA.contribution +
        layerResultB.contribution +
        layerResultC.contribution +
        layerResultD.contribution +
        layerResultE.contribution +
        layerResultF.contribution;

    int finalScore = rawScore.round().clamp(0, 100);
    explanationTrace.add('Base weighted score: $finalScore');

    // Trust System: soft trust discount
    bool trustedDomainMatch = false;
    for (final trusted in trustedDomains) {
      if (host == trusted || host.endsWith('.$trusted')) {
        trustedDomainMatch = true;
        break;
      }
    }

    if (trustedDomainMatch) {
      // NEVER override: punycode, confirmed typosquatting, credential + brand impersonation attacks
      final hasPunycode = host.startsWith('xn--');
      final hasCredentialImpersonation = brandSimilarityMatch && scoreD >= 50;

      if (!hasPunycode && !isConfirmedTyposquatting && !hasCredentialImpersonation) {
        finalScore = (finalScore * 0.1).round();
        explanationTrace.add('Soft-trust discount applied. Reduced score to $finalScore');
      } else {
        explanationTrace.add('Trusted domain matched but bypassed soft-trust due to critical indicators (Punycode/Typosquat/Impersonation)');
      }
    }

    // Critical Overrides Engine
    bool overrideApplied = false;
    final hasPunycode = host.startsWith('xn--');
    final hasTyposquatHarvesting = isConfirmedTyposquatting && scoreD >= 50;
    final hasStrongBrandImpersonation = brandSimilarityMatch && hasStructuralMimicry && hasIntent;

    if (blacklistMatch || hasPunycode || hasTyposquatHarvesting || hasStrongBrandImpersonation) {
      finalScore = max(finalScore, 85);
      overrideApplied = true;
      explanationTrace.add('Critical Override Engine activated. Elevated score to $finalScore');
      triggeredRules.add('critical_threat_override');
    }

    // Map final score to 5-Tier Verdict Scale
    String verdict;
    if (finalScore <= 20) {
      verdict = 'SAFE';
    } else if (finalScore <= 40) {
      verdict = 'LOW_RISK';
    } else if (finalScore <= 60) {
      verdict = 'SUSPICIOUS';
    } else if (finalScore <= 80) {
      verdict = 'HIGH_RISK';
    } else {
      verdict = 'DANGEROUS';
    }
    explanationTrace.add('Assigned verdict: $verdict');

    // Calculate Consistency & Confidence Score
    const int completedLayers = 6;
    double dataQuality = (host.isNotEmpty && uri != null) ? 1.0 : 0.5;
    
    // Consistency calculation (inverse of standard deviation)
    final List<double> layerScores = [scoreA, scoreB, scoreC, scoreD, scoreE, scoreF];
    final double mean = layerScores.reduce((a, b) => a + b) / 6.0;
    final double variance = layerScores.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / 6.0;
    final double stdDev = sqrt(variance);
    final double consistency = (1.0 - (stdDev / 100.0)).clamp(0.5, 1.0);

    final double rawConf = (completedLayers / 6.0) * consistency * dataQuality * 100.0;
    final int confidence = rawConf.round().clamp(0, 100);
    explanationTrace.add('Calculated confidence: $confidence%');

    // Formulate final detected factors
    final List<RiskFactor> detectedFactors = [];
    if (layerResultA.normalizedScore > 0) {
      detectedFactors.add(RiskFactor(
        id: 'reputation_analysis',
        name: 'Reputation Analysis',
        description: layerResultA.reasons.join(', '),
        scoreContribution: layerResultA.contribution,
        isDetected: true,
      ));
    }
    if (layerResultB.normalizedScore > 0) {
      detectedFactors.add(RiskFactor(
        id: 'brand_impersonation',
        name: 'Brand & Typosquatting',
        description: layerResultB.reasons.join(', '),
        scoreContribution: layerResultB.contribution,
        isDetected: true,
      ));
    }
    if (layerResultC.normalizedScore > 0) {
      detectedFactors.add(RiskFactor(
        id: 'url_structure',
        name: 'URL Structure Analysis',
        description: layerResultC.reasons.join(', '),
        scoreContribution: layerResultC.contribution,
        isDetected: true,
      ));
    }
    if (layerResultD.normalizedScore > 0) {
      detectedFactors.add(RiskFactor(
        id: 'credential_signals',
        name: 'Credential Signals',
        description: layerResultD.reasons.join(', '),
        scoreContribution: layerResultD.contribution,
        isDetected: true,
      ));
    }
    if (layerResultE.normalizedScore > 0) {
      detectedFactors.add(RiskFactor(
        id: 'https_checks',
        name: 'HTTPS & SSL Checks',
        description: layerResultE.reasons.join(', '),
        scoreContribution: layerResultE.contribution,
        isDetected: true,
      ));
    }
    if (layerResultF.normalizedScore > 0) {
      detectedFactors.add(RiskFactor(
        id: 'payload_checks',
        name: 'Redirections & Obfuscation',
        description: layerResultF.reasons.join(', '),
        scoreContribution: layerResultF.contribution,
        isDetected: true,
      ));
    }

    String threatCat = 'Safe Link';
    if (blacklistMatch) {
      threatCat = 'Blacklisted Link';
    } else if (isConfirmedTyposquatting) {
      threatCat = 'Brand Typosquatting';
    } else if (brandSimilarityMatch) {
      threatCat = 'Brand Impersonation';
    } else if (scoreD >= 50) {
      threatCat = 'Credential Harvesting';
    } else if (scoreF >= 80) {
      threatCat = 'Obfuscated Exploit Link';
    } else if (finalScore > 20) {
      threatCat = 'Suspicious URL';
    }

    return RiskAnalysisResult(
      score: finalScore,
      verdict: verdict,
      confidence: confidence,
      layerBreakdown: {
        'A': layerResultA,
        'B': layerResultB,
        'C': layerResultC,
        'D': layerResultD,
        'E': layerResultE,
        'F': layerResultF,
      },
      triggeredRules: triggeredRules,
      explanationTrace: explanationTrace,
      overrideApplied: overrideApplied,
      engineVersion: currentVersion,
      threatCategory: threatCat,
      detectedFactors: detectedFactors,
    );
  }

  // Tokenize domain label into comparable subparts (excludes TLDs)
  static List<String> _getDomainTokens(String host) {
    if (host.isEmpty) return [];
    
    // Check if IP address
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegex.hasMatch(host)) return [];

    final parts = host.split('.');
    if (parts.length <= 1) return parts;
    
    // Determine TLD size to strip
    int stripCount = 1;
    if (parts.length >= 3) {
      final last = parts[parts.length - 1];
      final secondLast = parts[parts.length - 2];
      if (last.length <= 3 && secondLast.length <= 3) {
        stripCount = 2; // double-barreled TLD
      }
    }

    final domainParts = parts.sublist(0, parts.length - stripCount);
    
    final List<String> tokens = [];
    for (final part in domainParts) {
      // Split by hyphen and underscores
      final subTokens = part.split(RegExp(r'[-_]')).where((s) => s.isNotEmpty);
      tokens.addAll(subTokens);
    }
    
    return tokens;
  }

  // Generates leetspeak normalized variations for a given token
  static List<String> _getLeetspeakVariants(String token) {
    final base = token.toLowerCase();
    String temp = base
        .replaceAll('0', 'o')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't');
    
    if (temp.contains('1')) {
      return [
        temp.replaceAll('1', 'l'),
        temp.replaceAll('1', 'i'),
      ];
    }
    return [temp];
  }

  static bool _isTyposquatted(String brand, String originalToken, List<String> normalizedVariants) {
    if (originalToken == brand) return false;
    
    // Check original token
    if (_checkTyposquattingAgreement(brand, originalToken)) {
      return true;
    }
    
    // Check leetspeak normalized variants
    for (final variant in normalizedVariants) {
      if (variant == brand) {
        return true; // Exact match after leetspeak normalization
      }
      if (_checkTyposquattingAgreement(brand, variant)) {
        return true;
      }
    }
    return false;
  }

  // Returns true if Levenshtein distance, Jaccard Similarity, or Character Overlap metrics agree on similarity
  static bool _checkTyposquattingAgreement(String brand, String token) {
    if (brand == token || brand.isEmpty || token.isEmpty) return false;

    // 1. Levenshtein Distance (40%) - threshold: Sim >= 70% and distance > 0
    final dist = _levenshtein(brand, token);
    final maxLen = brand.length > token.length ? brand.length.toDouble() : token.length.toDouble();
    final double levSim = maxLen > 0 ? 1.0 - (dist / maxLen) : 1.0;
    final bool isLev = levSim >= 0.70 && dist > 0;

    // 2. Token Jaccard Similarity of Bigrams (30%) - threshold: >= 50%
    final jacSim = _jaccardSimilarity(brand, token);
    final bool isJac = jacSim >= 0.50;

    // 3. Character Overlap Ratio (30%) - threshold: >= 75%
    final overlap = _characterOverlapRatio(brand, token);
    final bool isOverlap = overlap >= 0.75;

    // Agreement rule: at least 2 metrics must agree
    int agreeCount = (isLev ? 1 : 0) + (isJac ? 1 : 0) + (isOverlap ? 1 : 0);
    return agreeCount >= 2;
  }

  // Bigram characters Jaccard
  static double _jaccardSimilarity(String s1, String s2) {
    Set<String> getBigrams(String s) {
      final bigrams = <String>{};
      for (int i = 0; i < s.length - 1; i++) {
        bigrams.add(s.substring(i, i + 2));
      }
      return bigrams;
    }
    final set1 = getBigrams(s1);
    final set2 = getBigrams(s2);
    if (set1.isEmpty && set2.isEmpty) return 1.0;
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    if (union.isEmpty) return 0.0;
    return intersection.length / union.length;
  }

  // Character overlap count ratio
  static double _characterOverlapRatio(String s1, String s2) {
    final Map<String, int> counts1 = {};
    final Map<String, int> counts2 = {};
    for (final char in s1.split('')) {
      counts1[char] = (counts1[char] ?? 0) + 1;
    }
    for (final char in s2.split('')) {
      counts2[char] = (counts2[char] ?? 0) + 1;
    }
    int intersectionCount = 0;
    for (final char in counts1.keys) {
      if (counts2.containsKey(char)) {
        intersectionCount += counts1[char]! < counts2[char]! ? counts1[char]! : counts2[char]!;
      }
    }
    final minLen = s1.length < s2.length ? s1.length : s2.length;
    if (minLen == 0) return 0.0;
    return intersectionCount / minLen;
  }

  // Levenshtein distance
  static int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = _min3(
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        );
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[s2.length];
  }

  static int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
}
