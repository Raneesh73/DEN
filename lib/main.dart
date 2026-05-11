import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SplashScreen()));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Connecting...';
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception("Connection timed out. Please check your internet.");
        });
      }
      
      // Artificial delay for smooth splash experience
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Connection failed.\nTap to retry.';
          _hasError = true;
        });
      }
      // Startup errors are silently handled; UI shows retry option.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return const DenApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0E17), // Premium dark blue/black
        body: Center(
          child: GestureDetector(
            onTap: _hasError ? () {
              setState(() {
                _status = 'Connecting...';
                _hasError = false;
              });
              _initFirebase();
            } : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing DEN Logo Simulation
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E2A38),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'DEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_hasError)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 2,
                    ),
                  ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _hasError ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _hasError ? Colors.redAccent : Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
