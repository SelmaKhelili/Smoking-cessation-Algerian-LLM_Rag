import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

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
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background color
          Container(color: Colors.white),

          // Animated clouds layer 1
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                left: -MediaQuery.of(context).size.width +
                    (_controller1.value * MediaQuery.of(context).size.width * 2),
                top: 50,
                child: Opacity(
                  opacity: 0.6,
                  child: Image.asset(
                    'assets/images/Clouds_orange.png',
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
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/images/Clouds_orange.png',
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
                  opacity: 0.4,
                  child: Image.asset(
                    'assets/images/Clouds_orange.png',
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              );
            },
          ),

          // Logo in the center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Sai_orange.png',
                  width: 200,
                  height: 200,
                ),
              ],
            ),
          ),

          // Buttons at the bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 120,
            child: Column(
              children: [
                // Log In button
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8025),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign Up button
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE15A),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.signup);
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
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