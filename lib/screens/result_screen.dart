import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/scan_result.dart';
import '../models/risk_analysis_result.dart';
import '../models/risk_factor.dart';
import '../services/database_service.dart';
import '../services/risk_engine.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult result;

  const ResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late RiskAnalysisResult _riskAnalysis;

  @override
  void initState() {
    super.initState();
    // Fetch cached/parsed risk analysis result or compute it deterministically
    _riskAnalysis = widget.result.riskAnalysis ?? RiskEngine.analyzeUrl(widget.result.url);
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: AnimatedBuilder(
            animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildPremiumHeader(),
                        
                        const SizedBox(height: 24),
                        
                        // Status Card
                        _buildPremiumStatusCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Circular Risk Meter Card
                        _buildPremiumRiskScoreCard(),
                        
                        const SizedBox(height: 24),

                        // Detailed Risk Explanation Panel (Triggered factors lists)
                        RiskExplanationPanel(analysis: _riskAnalysis),
                        
                        const SizedBox(height: 24),
                        
                        // Scanned URL Card
                        _buildPremiumUrlCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Security Checks Pass/Fail Card
                        _buildPremiumSecurityChecksCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Security Action Recommendation Card
                        if (widget.result.recommendation.isNotEmpty) _buildPremiumRecommendationCard(),
                        
                        const SizedBox(height: 32),
                        
                        // Navigation Buttons
                        _buildPremiumActionButtons(),
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryCyan.withOpacity(0.2),
                  AppTheme.primaryBlue.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryCyan.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.primaryCyan,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Scan Results',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumStatusCard() {
    final statusColor = AppTheme.getRiskScoreColor(_riskAnalysis.score);
    IconData statusIcon;
    String statusDesc;
    
    switch (_riskAnalysis.verdict.toUpperCase()) {
      case 'SAFE':
        statusIcon = Icons.verified;
        statusDesc = 'This URL is safe to browse.';
        break;
      case 'LOW_RISK':
        statusIcon = Icons.info_outline;
        statusDesc = 'Low threat score. Proceed with standard caution.';
        break;
      case 'SUSPICIOUS':
        statusIcon = Icons.warning_amber_rounded;
        statusDesc = 'Caution advised. Verify credentials before entering details.';
        break;
      case 'DANGEROUS':
      default:
        statusIcon = Icons.dangerous;
        statusDesc = 'Highly dangerous phishing threat. Avoid connecting.';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _riskAnalysis.verdict.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusDesc,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRiskScoreCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground.withOpacity(0.9),
            AppTheme.cardBackground.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threat Assessment',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryCyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 24),
            
            // Custom Animated Circular Meter
            AnimatedRiskMeter(
              score: _riskAnalysis.score,
              confidence: _riskAnalysis.confidence / 100.0,
              threatCategory: _riskAnalysis.threatCategory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUrlCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground.withOpacity(0.9),
            AppTheme.cardBackground.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanned URL',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryCyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryCyan.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.result.url,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PremiumSecondaryButton(
                    title: '',
                    icon: Icons.copy,
                    onPressed: _copyUrl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSecurityChecksCard() {
    // Determine check passes based on deterministic factors
    final hasNoHttps = _riskAnalysis.detectedFactors.any((f) => f.id == 'no_https');
    final hasIp = _riskAnalysis.detectedFactors.any((f) => f.id == 'ip_based_domain');
    final hasLongUrl = widget.result.url.length > 75;
    final hasBrandImpersonation = _riskAnalysis.detectedFactors.any((f) => f.id == 'brand_impersonation');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground.withOpacity(0.9),
            AppTheme.cardBackground.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Checks',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryCyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildSecurityCheckItem('HTTPS Encryption', !hasNoHttps),
            const SizedBox(height: 12),
            _buildSecurityCheckItem('Domain IP Validation', !hasIp),
            const SizedBox(height: 12),
            _buildSecurityCheckItem('URL Length Heuristic', !hasLongUrl),
            const SizedBox(height: 12),
            _buildSecurityCheckItem('Brand Legitimacy check', !hasBrandImpersonation),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCheckItem(String title, bool isSecure) {
    final statusColor = isSecure ? AppTheme.safeGreen : AppTheme.dangerRed;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            isSecure ? Icons.check : Icons.close,
            color: statusColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isSecure ? 'PASS' : 'FAIL',
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumRecommendationCard() {
    final statusColor = AppTheme.getRiskScoreColor(_riskAnalysis.score);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recommendation',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              _getVerdictRecommendation(_riskAnalysis.verdict),
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.95),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVerdictRecommendation(String verdict) {
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

  Widget _buildPremiumActionButtons() {
    return Column(
      children: [
        // Visit Website Button (only for safe URLs)
        if (_riskAnalysis.verdict.toUpperCase() == 'SAFE') ...[
          PremiumPrimaryButton(
            title: 'Visit Website',
            icon: Icons.launch,
            onPressed: _launchUrl,
          ),
          const SizedBox(height: 16),
        ],
        
        Row(
          children: [
            Expanded(
              child: PremiumSecondaryButton(
                title: 'Scan Again',
                icon: Icons.qr_code_scanner,
                onPressed: () => Navigator.pushReplacementNamed(context, '/scan'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PremiumSecondaryButton(
                title: 'Go Home',
                icon: Icons.home_outlined,
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.result.url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'URL copied to clipboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.primaryCyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(widget.result.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Animated Circular Risk Meter
class AnimatedRiskMeter extends StatefulWidget {
  final int score;
  final double confidence;
  final String threatCategory;

  const AnimatedRiskMeter({
    super.key,
    required this.score,
    required this.confidence,
    required this.threatCategory,
  });

  @override
  State<AnimatedRiskMeter> createState() => _AnimatedRiskMeterState();
}

class _AnimatedRiskMeterState extends State<AnimatedRiskMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _percentAnimation;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _percentAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score / 100.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scoreAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = AppTheme.getRiskScoreColor(widget.score);

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom Painter for Gradient Arc
                AnimatedBuilder(
                  animation: _percentAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(160, 160),
                      painter: GradientArcPainter(
                        percent: _percentAnimation.value,
                      ),
                    );
                  },
                ),
                // Score Text with Count up
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _scoreAnimation,
                      builder: (context, child) {
                        return Text(
                          _scoreAnimation.value.toString(),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                            letterSpacing: -1.0,
                          ),
                        );
                      },
                    ),
                    Text(
                      'RISK SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Threat Category Label and Confidence Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scoreColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                widget.threatCategory.toUpperCase(),
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryCyan.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 13,
                    color: AppTheme.primaryCyan.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(widget.confidence * 100).toInt()}% CONF',
                    style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Custom Painter for circular meter with Multi-color Gradient
class GradientArcPainter extends CustomPainter {
  final double percent;

  GradientArcPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw background track
    final trackPaint = Paint()
      ..color = AppTheme.borderColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (percent <= 0) return;

    // Draw progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          AppTheme.safeGreen,
          AppTheme.warningOrange,
          AppTheme.dangerRed,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-3.14159 / 2 - 0.2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.14159 / 2,
      2 * 3.14159 * percent,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GradientArcPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}

// Expandable detailed Risk Explanation Panel
class RiskExplanationPanel extends StatefulWidget {
  final RiskAnalysisResult analysis;

  const RiskExplanationPanel({
    super.key,
    required this.analysis,
  });

  @override
  State<RiskExplanationPanel> createState() => _RiskExplanationPanelState();
}

class _RiskExplanationPanelState extends State<RiskExplanationPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final detectedFactors = widget.analysis.detectedFactors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground.withOpacity(0.9),
            AppTheme.cardBackground.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(24)),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Risk Analysis Details',
                          style: TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${detectedFactors.length} threat indicators detected',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryCyan,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppTheme.borderColor),
                  const SizedBox(height: 16),
                  
                  // Versioning info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Engine Version: v${widget.analysis.engineVersion}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Analyzed: ${DateFormat('h:mm a, MMM d').format(widget.analysis.analysisTimestamp)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (detectedFactors.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.safeGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Clean Scan: URL has no common threat features.',
                              style: TextStyle(
                                color: AppTheme.safeGreen.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...detectedFactors.map((factor) => _buildFactorItem(factor)).toList(),

                  const SizedBox(height: 16),
                  
                  // Info Footer explaining weights
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Weights: Reputation (30%), Brand (25%), Structure (20%), Credentials (10%), HTTPS (5%), Redirect & Payload (10%)',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(RiskFactor factor) {
    final points = factor.scoreContribution.round();
    final isNegative = points > 0;
    final pointsText = isNegative ? '+$points' : '0';
    final pointsColor = isNegative ? AppTheme.dangerRed : AppTheme.safeGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative ? AppTheme.dangerRed.withOpacity(0.15) : AppTheme.safeGreen.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNegative ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: pointsColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        factor.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pointsText,
                      style: TextStyle(
                        color: pointsColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  factor.description,
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Premium Primary Button Widget
class PremiumPrimaryButton extends StatefulWidget {
  final String title;
  final IconData? icon;
  final VoidCallback onPressed;

  const PremiumPrimaryButton({
    super.key,
    required this.title,
    this.icon,
    required this.onPressed,
  });

  @override
  State<PremiumPrimaryButton> createState() => _PremiumPrimaryButtonState();
}

class _PremiumPrimaryButtonState extends State<PremiumPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onPressed();
            },
            onTapCancel: () => _controller.reverse(),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryCyan,
                    AppTheme.primaryBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Premium Secondary Button Widget
class PremiumSecondaryButton extends StatefulWidget {
  final String title;
  final IconData? icon;
  final VoidCallback onPressed;

  const PremiumSecondaryButton({
    super.key,
    required this.title,
    this.icon,
    required this.onPressed,
  });

  @override
  State<PremiumSecondaryButton> createState() => _PremiumSecondaryButtonState();
}

class _PremiumSecondaryButtonState extends State<PremiumSecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title.isEmpty) {
      // Icon-only button
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) {
                _controller.reverse();
                widget.onPressed();
              },
              onTapCancel: () => _controller.reverse(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: AppTheme.primaryCyan,
                    size: 18,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onPressed();
            },
            onTapCancel: () => _controller.reverse(),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryCyan.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: AppTheme.primaryCyan,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryCyan,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
