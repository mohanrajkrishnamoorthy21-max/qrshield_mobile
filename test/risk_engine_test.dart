import 'package:flutter_test/flutter_test.dart';
import 'package:qrshield_mobile/services/risk_engine.dart';
import 'package:qrshield_mobile/models/risk_analysis_result.dart';

void main() {
  group('Phishing Detection Engine Tests', () {
    test('https://google.com should be SAFE', () {
      final result = RiskEngine.analyzeUrl('https://google.com');
      
      print('=== https://google.com ===');
      print('Score: ${result.score}');
      print('Verdict: ${result.verdict}');
      print('Triggered Rules: ${result.triggeredRules}');
      print('Trace:\n${result.explanationTrace.join('\n')}');

      expect(result.verdict, equals('SAFE'));
      expect(result.score, lessThanOrEqualTo(20));
      expect(result.overrideApplied, isFalse);
    });

    test('http://paypa1-account-verify.xyz/login should be DANGEROUS (with override)', () {
      final result = RiskEngine.analyzeUrl('http://paypa1-account-verify.xyz/login');
      
      print('\n=== http://paypa1-account-verify.xyz/login ===');
      print('Score: ${result.score}');
      print('Verdict: ${result.verdict}');
      print('Triggered Rules: ${result.triggeredRules}');
      print('Trace:\n${result.explanationTrace.join('\n')}');

      expect(result.verdict, equals('DANGEROUS'));
      expect(result.score, greaterThanOrEqualTo(85));
      expect(result.overrideApplied, isTrue);
    });

    test('https://chatgptt.com should be HIGH_RISK or DANGEROUS', () {
      final result = RiskEngine.analyzeUrl('https://chatgptt.com');
      
      print('\n=== https://chatgptt.com ===');
      print('Score: ${result.score}');
      print('Verdict: ${result.verdict}');
      print('Triggered Rules: ${result.triggeredRules}');
      print('Trace:\n${result.explanationTrace.join('\n')}');

      expect(['HIGH_RISK', 'DANGEROUS'], contains(result.verdict));
    });

    test('https://amaz0n-security.com should be DANGEROUS', () {
      final result = RiskEngine.analyzeUrl('https://amaz0n-security.com');
      
      print('\n=== https://amaz0n-security.com ===');
      print('Score: ${result.score}');
      print('Verdict: ${result.verdict}');
      print('Triggered Rules: ${result.triggeredRules}');
      print('Trace:\n${result.explanationTrace.join('\n')}');

      expect(result.verdict, equals('DANGEROUS'));
      expect(result.score, greaterThanOrEqualTo(85));
    });

    test('https://xn--googl-1sa.com should be DANGEROUS (with override)', () {
      final result = RiskEngine.analyzeUrl('https://xn--googl-1sa.com');
      
      print('\n=== https://xn--googl-1sa.com ===');
      print('Score: ${result.score}');
      print('Verdict: ${result.verdict}');
      print('Triggered Rules: ${result.triggeredRules}');
      print('Trace:\n${result.explanationTrace.join('\n')}');

      expect(result.verdict, equals('DANGEROUS'));
      expect(result.score, greaterThanOrEqualTo(85));
      expect(result.overrideApplied, isTrue);
    });

    test('myamazonblog.com should avoid false positive (SAFE)', () {
      final result = RiskEngine.analyzeUrl('https://myamazonblog.com');
      
      print('\n=== https://myamazonblog.com ===');
      print('Score: ${result.score}');
      print('Verdict: ${result.verdict}');
      print('Triggered Rules: ${result.triggeredRules}');

      expect(result.verdict, equals('SAFE'));
    });
  });
}
