import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmiscupaap3/DebugmodeScreen.dart';
import 'dashboardscreen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const platformForDebug = MethodChannel('com.techwings.fmiscupaap3');
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      checkDeveloperMode(context);
    });
  }
  static Future<void> checkDeveloperMode(BuildContext context) async {
    try {
      final bool isEnabled = await platformForDebug.invokeMethod(
        'isDeveloperModeEnabled',
      );
      if (isEnabled) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DebugModeScreen(),
          ), // Replace with your target screen
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>  DashboardScreen(),
          ), // Replace with your target screen
        );
      }
    } on PlatformException catch (e) {
      print("Failed to check developer mode: ${e.message}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFbddffa), // Light blue solid background
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration( // Removed `const`
          gradient: LinearGradient(
            colors: [
              Color(0xFF66b5f8),
              Colors.white.withOpacity(0.0), // ✅ Now allowed
              Color(0xFF4fabf6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/image/up.png',
                height: 150,
              ),
              const SizedBox(height: 5),
              Image.asset(
                'assets/image/logo.png',
                height: 250,
              ),
              const SizedBox(height: 10),
              // const Text('सिंचनेन समृद्धि भवति',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.red,
              //   ),
              // ),
              // const SizedBox(height: 10),
              const Text(
                'Flood Management Information System Centre',
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
              //   const SizedBox(height: 10),
              Image.asset(
                'assets/image/district.png',
                height: 300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
