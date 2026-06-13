import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service_new.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _torchEnabled = false;
  String? _scannedUrl;
  bool _isProcessing = false;
  
  // Scan lock protection
  bool _isProcessingScan = false;

  // Session deduplication
  final Set<String> _processedScans = {};

  // Stream subscription reference
  StreamSubscription<BarcodeCapture>? _subscription;

  late AnimationController _scanLineController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Subscribe only in initState
    _subscription = controller.barcodes.listen(_onDetect);
  }

  void _initializeAnimations() {
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanLineController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    // Cancel subscription and dispose controller
    _subscription?.cancel();
    controller.dispose();
    _scanLineController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing || _isProcessingScan) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    
    // Basic validation - check if it looks like a URL
    if (code == null || code.trim().isEmpty) return;
    
    final String scanValue = code.trim();

    // Session deduplication
    if (_processedScans.contains(scanValue)) {
      return;
    }
    
    // Try to parse as URL, but also accept text that might be URLs
    final uri = Uri.tryParse(scanValue);
    bool isUrl = false;
    
    if (uri != null && uri.hasScheme) {
      isUrl = uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } else {
      // Check if it looks like a URL without scheme
      final urlPattern = RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
      isUrl = urlPattern.hasMatch(scanValue);
    }
    
    if (!isUrl) return;

    print("SCAN DETECTED");

    // Stop scanning and process
    setState(() {
      _scannedUrl = scanValue;
      _isScanning = false;
      _isProcessing = true;
    });

    // Pause the scanner stream and stop camera to prevent multiple scans
    _subscription?.pause();
    controller.stop();

    _processScannedUrl(scanValue);
  }

  Future<void> _processScannedUrl(String url) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    try {
      // Ensure we have a proper URL format
      String processedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        processedUrl = 'https://$url';
      }
      
      print('Processing URL: $processedUrl'); // Debug log
      final result = await ApiService.scanUrl(processedUrl);
      
      // Add scan to processed scans set upon successful processing
      _processedScans.add(url);
      
      if (mounted) {
        // Use pushNamed and await navigation to resume scanner when returning
        await Navigator.pushNamed(
          context,
          '/result',
          arguments: result,
        );
        _resumeScanning();
      }
    } catch (e) {
      print('Scan error: $e'); // Debug log
      if (mounted) {
        _showErrorDialog('Failed to analyze URL: ${e.toString()}');
        _resumeScanning();
      }
    } finally {
      _isProcessingScan = false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    controller.toggleTorch();
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _scannedUrl = null;
      _isProcessing = false;
      _isProcessingScan = false;
    });
    
    // Restart stream and camera
    _subscription?.resume();
    controller.start();
  }

  // Test method for debugging - call this from a button or in debug mode
  Future<void> _testApiCall() async {
    try {
      print('Testing API call...');
      final result = await ApiService.scanUrl('https://example.com');
      print('API test successful: $result');
      
      if (mounted) {
        await Navigator.pushNamed(
          context,
          '/result',
          arguments: result,
        );
        _resumeScanning();
      }
    } catch (e) {
      print('API test failed: $e');
      if (mounted) {
        _showErrorDialog('API Test Failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text('QR Scanner'),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          // Debug test button (remove in production)
          IconButton(
            onPressed: _testApiCall,
            icon: const Icon(
              Icons.bug_report,
              color: Colors.green,
            ),
            tooltip: 'Test API',
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _torchEnabled ? Icons.flash_on : Icons.flash_off,
                    color: _torchEnabled ? AppTheme.warningOrange : AppTheme.textPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: controller,
            ),

            // Scan frame overlay
            Center(
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final double scanFrameSize = screenWidth * 0.75 > 280.0 ? 280.0 : screenWidth * 0.75;
                  final double halfFrameSize = scanFrameSize / 2;
                  
                  return Container(
                    width: scanFrameSize,
                    height: scanFrameSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryCyan,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated scan line
                        AnimatedBuilder(
                          animation: _scanLineAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: halfFrameSize + ((halfFrameSize - 10) * _scanLineAnimation.value),
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryCyan,
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.primaryCyan,
                                      AppTheme.primaryCyan,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Corner decorations
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppTheme.primaryCyan, width: 4),
                                left: BorderSide(color: AppTheme.primaryCyan, width: 4),
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppTheme.primaryCyan, width: 4),
                                right: BorderSide(color: AppTheme.primaryCyan, width: 4),
                              ),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.primaryCyan, width: 4),
                                left: BorderSide(color: AppTheme.primaryCyan, width: 4),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.primaryCyan, width: 4),
                                right: BorderSide(color: AppTheme.primaryCyan, width: 4),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),

            // Instructions
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Text(
                _isProcessing ? 'Analyzing URL...' : 'Position QR code within frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.primaryCyan),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Scanning for threats...',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scannedUrl ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
