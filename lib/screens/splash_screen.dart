import 'dart:math';

import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Launch animation: the pétanque-badge rolls in from the side like a real
/// boule, settles with a little bounce, then the Cap Fun mascot pops in on
/// top before the app hands off to [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rollProgress;
  late final Animation<double> _settleBounce;
  late final Animation<double> _mascotProgress;

  // The roll + bounce + mascot pop-in only use the first part of the
  // timeline; the rest is a still hold before handing off to the home
  // screen, all driven by the same controller so a single `pump(duration)`
  // in tests (or a single Ticker in production) drives the whole sequence.
  static const _totalDuration = Duration(milliseconds: 2250);
  static const _reducedMotionDuration = Duration(milliseconds: 300);
  static const _rollCurveEnd = 0.47;

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion ? _reducedMotionDuration : _totalDuration,
    );

    _rollProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, _rollCurveEnd, curve: Curves.easeOutCubic),
    );
    _settleBounce = CurvedAnimation(
      parent: _controller,
      curve: const Interval(_rollCurveEnd, _rollCurveEnd + 0.17, curve: Curves.easeOutBack),
    );
    _mascotProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.44, 0.7, curve: Curves.easeOutBack),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _goHome();
    });
    _controller.forward();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: const HomeScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF1C140D) : const Color(0xFFFBF3E4);
    final screenWidth = MediaQuery.of(context).size.width;
    const badgeSize = 220.0;

    return Scaffold(
      backgroundColor: background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final startX = -(screenWidth / 2 + badgeSize);
          final rollX = startX + (0 - startX) * _rollProgress.value;
          final bounceScale = 1.0 + sin(_settleBounce.value * pi) * 0.06;
          // A whole number of turns so the badge always lands upright
          // (not physically exact, but reads as "designed" rather than a
          // random tilt once it stops).
          final rotation = -_rollProgress.value * 4 * pi;

          return Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: Offset(rollX, 0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: bounceScale,
                      child: Image.asset(
                        'assets/logo/capfun_petanque_icon.png',
                        width: badgeSize,
                        height: badgeSize,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -badgeSize * 0.62 + (1 - _mascotProgress.value) * 40),
                  child: Opacity(
                    opacity: _mascotProgress.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * _mascotProgress.value.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: -0.07,
                        child: Image.asset(
                          'assets/logo/capfun_bizouquet.png',
                          width: badgeSize * 1.42,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
