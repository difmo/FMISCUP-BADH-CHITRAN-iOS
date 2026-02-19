import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmiscupaap3/DebugmodeScreen.dart';
import 'package:fmiscupaap3/dashboardscreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const MethodChannel platformForDebug = MethodChannel(
    'com.techwings.fmiscupaap3',
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      checkDeveloperMode(context);
    });
  }

  Future<void> checkDeveloperMode(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        final bool isEnabled = await platformForDebug.invokeMethod(
          'isDeveloperModeEnabled',
        );
        if (isEnabled) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DebugModeScreen()),
          );
        } else {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } on PlatformException catch (e) {
        print("Failed to check developer mode: ${e.message}");
        // Fallback to dashboard if error occurs
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      // On iOS or Web, default to DashboardScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFbddffa), // Solid background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF66b5f8),
              Colors.white.withOpacity(0.0),
              const Color(0xFF4fabf6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset('assets/image/up.png', height: 150),
              const SizedBox(height: 5),
              Image.asset('assets/image/logo.png', height: 250),
              const SizedBox(height: 10),
              const Text(
                'Flood Management Information System Centre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Irrigation & Water Resources Department\nUttar Pradesh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset('assets/image/district.png', height: 300),
            ],
          ),
        ),
      ),
    );
  }
}
