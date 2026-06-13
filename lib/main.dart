import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen_new.dart';
import 'screens/scan_screen_new.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'models/scan_result.dart';

void main() {
  runApp(const QRShieldApp());
}

class QRShieldApp extends StatelessWidget {
  const QRShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Anti-Phishing QR Scanner",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/scan': (context) => const ScanScreen(),
        '/result': (context) {
          final result = ModalRoute.of(context)?.settings.arguments as ScanResult?;
          if (result == null) {
            return const HomeScreen(); // Fallback to home if no result
          }
          return ResultScreen(result: result);
        },
        '/history': (context) => const HistoryScreen(),
      },
      onGenerateRoute: (settings) {
        // Add smooth transitions for named routes
        if (settings.name == '/scan') {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ScanScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        }
        if (settings.name == '/result') {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              final result = settings.arguments as ScanResult?;
              if (result == null) return const HomeScreen();
              return ResultScreen(result: result);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          );
        }
        if (settings.name == '/history') {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HistoryScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}