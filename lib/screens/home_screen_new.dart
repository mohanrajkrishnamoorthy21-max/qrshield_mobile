import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/scan_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _securityStatusSlideAnimation;
  late Animation<Offset> _scanCardSlideAnimation;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<Offset> _recentActivitySlideAnimation;
  late Animation<Offset> _riskPreviewSlideAnimation;
  late Animation<Offset> _featuresSlideAnimation;

  // Dashboard Data State
  int _totalScans = 0;
  int _safeScans = 0;
  int _blockedScans = 0;
  ScanResult? _lastScanResult;
  bool _realTimeProtection = true;
  String _dbUpdatedTime = "Today, 09:15 AM";

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPreferences();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Staggered slide animations
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _securityStatusSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    ));

    _scanCardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _statsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
    ));

    _recentActivitySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    ));

    _riskPreviewSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
    ));

    _featuresSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
    ));

    _mainController.forward();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _realTimeProtection = prefs.getBool('realtime_protection') ?? true;
      });
    } catch (e) {
      // SharedPreferences not initialized or failed
    }
  }

  Future<void> _toggleRealTimeProtection(bool value) async {
    setState(() {
      _realTimeProtection = value;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('realtime_protection', value);
    } catch (e) {
      // Silent fail
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Real-time protection is now ACTIVE'
                : 'Warning: Real-time protection is now INACTIVE',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: value ? AppTheme.safeGreen : AppTheme.dangerRed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await DatabaseService.getScanStats();
      final lastScan = await DatabaseService.getLastScanResult();
      
      final now = DateTime.now();
      // Generate a stable database update timestamp (e.g. 15 minutes before current time)
      final formatter = DateFormat('MMM dd, yyyy - hh:mm a');
      final dbTime = formatter.format(now.subtract(const Duration(minutes: 15)));

      if (mounted) {
        setState(() {
          _totalScans = stats['total'] ?? 0;
          _safeScans = stats['safe'] ?? 0;
          _blockedScans = stats['blocked'] ?? 0;
          _lastScanResult = lastScan;
          _dbUpdatedTime = dbTime;
        });
      }
    } catch (e) {
      // Default fallback
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final double verticalSpacing = constraints.maxHeight < 600 ? 16.0 : 24.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      SlideTransition(
                        position: _headerSlideAnimation,
                        child: const PremiumHeader(),
                      ),
                      
                      SizedBox(height: verticalSpacing),

                      // Security Status Card
                      SlideTransition(
                        position: _securityStatusSlideAnimation,
                        child: SecurityStatusCard(
                          isActive: _realTimeProtection,
                          dbUpdatedTime: _dbUpdatedTime,
                          onToggle: _toggleRealTimeProtection,
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),

                      // Scan QR Card
                      SlideTransition(
                        position: _scanCardSlideAnimation,
                        child: PremiumScanCard(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/scan');
                            _loadDashboardData();
                          },
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),

                      // Scan Statistics Section
                      SlideTransition(
                        position: _statsSlideAnimation,
                        child: PremiumStatsSection(
                          total: _totalScans,
                          safe: _safeScans,
                          blocked: _blockedScans,
                          onHistoryTap: () async {
                            await Navigator.pushNamed(context, '/history');
                            _loadDashboardData();
                          },
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),

                      // Recent Activity Section
                      SlideTransition(
                        position: _recentActivitySlideAnimation,
                        child: RecentActivitySection(
                          lastScan: _lastScanResult,
                          onHistoryTap: () async {
                            await Navigator.pushNamed(context, '/history');
                            _loadDashboardData();
                          },
                          onScanTap: (scan) async {
                            await Navigator.pushNamed(
                              context,
                              '/result',
                              arguments: scan,
                            );
                            _loadDashboardData();
                          },
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),

                      // Risk Detection Preview
                      SlideTransition(
                        position: _riskPreviewSlideAnimation,
                        child: const RiskDetectionPreview(),
                      ),

                      SizedBox(height: verticalSpacing),

                      // Features Section
                      SlideTransition(
                        position: _featuresSlideAnimation,
                        child: const PremiumFeaturesSection(),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Premium Header Section Widget
class PremiumHeader extends StatelessWidget {
  const PremiumHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Smart Security',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryCyan,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const PremiumAppLogo(),
      ],
    );
  }
}

// Premium App Logo Widget
class PremiumAppLogo extends StatelessWidget {
  const PremiumAppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryCyan,
            AppTheme.primaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.qr_code_scanner,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

// Security Status Card
class SecurityStatusCard extends StatefulWidget {
  final bool isActive;
  final String dbUpdatedTime;
  final ValueChanged<bool> onToggle;

  const SecurityStatusCard({
    super.key,
    required this.isActive,
    required this.dbUpdatedTime,
    required this.onToggle,
  });

  @override
  State<SecurityStatusCard> createState() => _SecurityStatusCardState();
}

class _SecurityStatusCardState extends State<SecurityStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isActive ? AppTheme.safeGreen : AppTheme.dangerRed;
    final statusText = widget.isActive ? 'System Protected' : 'Protection Disabled';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground,
            AppTheme.cardBackground.withOpacity(0.8),
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
            color: statusColor.withOpacity(0.05),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // Shield Icon with Pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isActive ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: statusColor.withOpacity(0.2),
                                blurRadius: 10 * _pulseAnimation.value,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.isActive ? Icons.verified_user : Icons.gpp_maybe,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'DB Updated: ${widget.dbUpdatedTime}',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Switch Toggle
            Switch.adaptive(
              value: widget.isActive,
              activeColor: AppTheme.safeGreen,
              activeTrackColor: AppTheme.safeGreen.withOpacity(0.2),
              inactiveThumbColor: AppTheme.textSecondary,
              inactiveTrackColor: AppTheme.borderColor,
              onChanged: widget.onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Hero Scan Card Widget (Optimized spacing)
class PremiumScanCard extends StatefulWidget {
  final VoidCallback onPressed;

  const PremiumScanCard({
    super.key,
    required this.onPressed,
  });

  @override
  State<PremiumScanCard> createState() => _PremiumScanCardState();
}

class _PremiumScanCardState extends State<PremiumScanCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppTheme.cardBackground,
                  AppTheme.cardBackground.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.04),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Scanner Preview Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryCyan.withOpacity(0.08),
                          AppTheme.primaryBlue.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.primaryCyan.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryCyan.withOpacity(0.05),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 50,
                          color: AppTheme.primaryCyan,
                        ),
                        // Scanner line effect
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            final double topOffset = 12 + (76 * _scanAnimation.value);
                            return Positioned(
                              top: topOffset,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryCyan.withOpacity(0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    'Scan QR Code',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Text(
                    'AI-powered threat detection',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Primary Action Button
                  PremiumPrimaryButton(
                    title: 'Scan QR Now',
                    icon: Icons.qr_code_scanner_outlined,
                    onPressed: widget.onPressed,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Premium Primary Action Button Widget (Glow + Animations + No Overflow)
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
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.95 : 1.0;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final glowMultiplier = _isHovered ? 1.4 : 1.0;
              final glowIntensity = _glowAnimation.value * 0.35 * glowMultiplier;
              
              return Container(
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
                      color: AppTheme.primaryCyan.withOpacity(glowIntensity),
                      blurRadius: 16 * _glowAnimation.value * glowMultiplier,
                      spreadRadius: 2 * _glowAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
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
}

// Premium Stats Section Widget (3 Columns, Overflow-proof)
class PremiumStatsSection extends StatelessWidget {
  final int total;
  final int safe;
  final int blocked;
  final VoidCallback onHistoryTap;

  const PremiumStatsSection({
    super.key,
    required this.total,
    required this.safe,
    required this.blocked,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Security Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryCyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: onHistoryTap,
              child: const Row(
                children: [
                  Text(
                    'History',
                    style: TextStyle(
                      color: AppTheme.primaryCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.primaryCyan,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Total Scans Card
            Expanded(
              child: PremiumStatMiniCard(
                icon: Icons.history,
                iconColor: AppTheme.primaryBlue,
                value: total.toString(),
                label: 'Total Scans',
              ),
            ),
            const SizedBox(width: 12),
            // Safe Scans Card
            Expanded(
              child: PremiumStatMiniCard(
                icon: Icons.check_circle_outline,
                iconColor: AppTheme.safeGreen,
                value: safe.toString(),
                label: 'Safe QR',
              ),
            ),
            const SizedBox(width: 12),
            // Blocked threats card
            Expanded(
              child: PremiumStatMiniCard(
                icon: Icons.gpp_bad_outlined,
                iconColor: AppTheme.dangerRed,
                value: blocked.toString(),
                label: 'Threats Blocked',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Premium Individual Mini Stat Card Widget
class PremiumStatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const PremiumStatMiniCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Recent Activity Section (Dynamic & Premium)
class RecentActivitySection extends StatelessWidget {
  final ScanResult? lastScan;
  final VoidCallback onHistoryTap;
  final ValueChanged<ScanResult> onScanTap;

  const RecentActivitySection({
    super.key,
    required this.lastScan,
    required this.onHistoryTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryCyan,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (lastScan == null)
          // Empty State Placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 44,
                  color: AppTheme.textSecondary.withOpacity(0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  'No scan history found',
                  style: TextStyle(
                    color: AppTheme.textPrimary.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan a QR code to run your first security check.',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Last Scan Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onScanTap(lastScan!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      // Status Avatar Indicator
                      _buildStatusIcon(lastScan!.status),
                      const SizedBox(width: 16),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lastScan!.url,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Tiny status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getStatusColor(lastScan!.status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.getStatusColor(lastScan!.status).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    lastScan!.status.toUpperCase(),
                                    style: TextStyle(
                                      color: AppTheme.getStatusColor(lastScan!.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Timestamp
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppTheme.textSecondary.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimestamp(lastScan!.timestamp),
                                  style: TextStyle(
                                    color: AppTheme.textSecondary.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    final color = AppTheme.getStatusColor(status);
    IconData iconData;
    switch (status.toUpperCase()) {
      case 'SAFE':
        iconData = Icons.gpp_good;
        break;
      case 'SUSPICIOUS':
        iconData = Icons.gpp_maybe;
        break;
      case 'PHISHING':
        iconData = Icons.gpp_bad;
        break;
      default:
        iconData = Icons.help_outline;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 22,
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}

// Risk Detection Preview Guide
class RiskDetectionPreview extends StatelessWidget {
  const RiskDetectionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Threat Classifications',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRiskBadge(
                  label: 'Safe',
                  scoreRange: '0 - 30',
                  color: AppTheme.safeGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRiskBadge(
                  label: 'Suspicious',
                  scoreRange: '31 - 60',
                  color: AppTheme.warningOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRiskBadge(
                  label: 'Dangerous',
                  scoreRange: '61 - 100',
                  color: AppTheme.dangerRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge({
    required String label,
    required String scoreRange,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scoreRange,
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Premium Features Section Widget (Optimized)
class PremiumFeaturesSection extends StatelessWidget {
  const PremiumFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Core Features',
              style: TextStyle(
                color: AppTheme.primaryCyan,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            
            PremiumFeatureItem(
              icon: Icons.security,
              title: 'Advanced ML Scan',
              description: 'Real-time phishing analysis powered by on-device and backend models',
            ),
            
            const SizedBox(height: 20),
            
            PremiumFeatureItem(
              icon: Icons.speed,
              title: 'Instant Threat Score',
              description: 'Receive a structured risk score and full breakdown of threat vectors',
            ),
            
            const SizedBox(height: 20),
            
            PremiumFeatureItem(
              icon: Icons.analytics,
              title: 'Actionable Insights',
              description: 'Clear details on SSL validity, domain age, and keywords',
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Individual Feature Item Widget (Optimized)
class PremiumFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const PremiumFeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Icon Container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryCyan.withOpacity(0.12),
                AppTheme.primaryBlue.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryCyan.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCyan.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: AppTheme.primaryCyan,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Premium Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
