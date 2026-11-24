
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import '/../widgets/starry_sky.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _splashController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late final List<Star> _stars;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: Curves.easeIn,
      ),
    );

    _splashController.forward();

    final random = Random(42);

    _stars = List.generate(
      75,
      (i) => Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 1.8 + 0.6,
        speed: random.nextDouble() * 0.2 + 0.1,
        seed: i,
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const LoginScreen();
          },
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );

            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(
              CurveTween(curve: Curves.easeIn),
            );

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _splashController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060409),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarrySkyPainter(
                  animationValue: _starController.value,
                  stars: _stars,
                ),
              );
            },
          ),

          Center(
            child: AnimatedBuilder(
              animation: _splashController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              final position =
                                  _shimmerController.value;

                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: const [
                                      Color(0xFF3B82F6),
                                      Color(0xFF8B5CF6),
                                      Colors.white,
                                      Color(0xFF8B5CF6),
                                      Color(0xFF3B82F6),
                                    ],
                                    stops: [
                                      0.0,
                                      (position - 0.2).clamp(0.0, 1.0),
                                      position,
                                      (position + 0.2).clamp(0.0, 1.0),
                                      1.0,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'VOCA TECHXPO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 38,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'EVENT WIRAUSAHA MAHASISWA MARKETPLACE BOOTH',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF00E699),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
