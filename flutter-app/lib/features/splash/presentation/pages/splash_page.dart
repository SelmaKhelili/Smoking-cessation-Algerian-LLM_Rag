import 'package:flutter/material.dart';
import 'welcome_page.dart'; // Make sure this matches your actual file path

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Create three controllers with different durations for variety
    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _controller2 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _controller3 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    // Pulse animation for "Tap to start" text
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8025), // Orange background
      body: GestureDetector(
        onTap: _navigateToWelcome,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Orange background
            Container(color: const Color(0xFFFF8025)),

            // Animated clouds layer 1
            AnimatedBuilder(
              animation: _controller1,
              builder: (context, child) {
                return Positioned(
                  left: -MediaQuery.of(context).size.width +
                      (_controller1.value * MediaQuery.of(context).size.width * 2),
                  top: 50,
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/Clouds_white.png',
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                );
              },
            ),

            // Animated clouds layer 2 (moves slower)
            AnimatedBuilder(
              animation: _controller2,
              builder: (context, child) {
                return Positioned(
                  left: -MediaQuery.of(context).size.width +
                      (_controller2.value * MediaQuery.of(context).size.width * 2),
                  top: 200,
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.asset(
                      'assets/images/Clouds_white.png',
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                );
              },
            ),

            // Animated clouds layer 3
            AnimatedBuilder(
              animation: _controller3,
              builder: (context, child) {
                return Positioned(
                  left: -MediaQuery.of(context).size.width +
                      (_controller3.value * MediaQuery.of(context).size.width * 2),
                  top: 500,
                  child: Opacity(
                    opacity: 0.2,
                    child: Image.asset(
                      'assets/images/Clouds_white.png',
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                );
              },
            ),

            // Logo in the center
            Center(
              child: Image.asset(
                'assets/images/Sai_white.png',
                width: 200,
                height: 200,
              ),
            ),

            // "Tap to start" text at the bottom with pulse animation
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.6 + (_pulseController.value * 0.4),
                    child: const Center(
                      child: Text(
                        'Tap to start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2.0,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}