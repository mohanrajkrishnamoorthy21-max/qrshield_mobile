import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {

  bool isProcessing = false;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  void resetScanner() {
    setState(() {
      isProcessing = false;
    });
    controller.start();
  }

  Future<void> openLink(String url) async {

    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Could not open $url");
    }
  }

  void handleScan(String url) async {

    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    await controller.stop();

    /// Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final data = await ApiService.checkUrl(url);

    if (mounted) Navigator.pop(context);

    String prediction = data["prediction"] ?? "safe";
    int riskScore = data["risk_score"] ?? 0;
    double confidence = (data["confidence"] ?? 0).toDouble();

    bool isPhishing = prediction == "phishing";

    Color statusColor = isPhishing ? Colors.red : Colors.green;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        title: const Text(
          "Security Result",
          textAlign: TextAlign.center,
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
              isPhishing ? Icons.gpp_bad : Icons.verified,
              size: 70,
              color: statusColor,
            ),

            const SizedBox(height: 15),

            Text(
              isPhishing
                  ? "Dangerous Website"
                  : "Safe Website",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 15),

            Text("Risk Score: $riskScore%"),
            Text("Confidence: ${(confidence * 100).toStringAsFixed(1)}%"),
          ],
        ),

        actionsAlignment: MainAxisAlignment.center,

        actions: [

          if (isPhishing)

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                resetScanner();
              },
              child: const Text("Close"),
            )

          else ...[

            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetScanner();
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                openLink(url);
                resetScanner();
              },
              child: const Text("Open Link"),
            ),
          ]
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("QR Code Scanner"),
      ),

      body: Stack(
        children: [

          MobileScanner(
            controller: controller,
            onDetect: (capture) {

              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;

              if (code != null) {
                handleScan(code);
              }

            },
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              "Align QR Code inside the frame",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}