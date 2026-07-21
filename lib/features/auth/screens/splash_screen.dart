import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';

/// First screen shown when the app opens. Purely presentational — it does
/// no app initialization itself (Supabase is already initialized in main()
/// before runApp) and always hands off to the login screen after a fixed
/// delay, letting the router's existing redirect logic take over from there
/// unchanged (a logged-in user lands on login for a beat and the existing
/// `isLoggedIn && isAuthRoute` rule bounces them to home).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 2600);
  static const _messages = [
    'Initializing…',
    'Loading clubs…',
    'Syncing events…',
    'Preparing your workspace…',
    'Almost ready…',
  ];

  late final AnimationController _introController;
  late final AnimationController _driftController;
  late final AnimationController _floatController;
  Timer? _messageTimer;
  Timer? _navigateTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    _driftController = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    final messageInterval = Duration(milliseconds: _totalDuration.inMilliseconds ~/ _messages.length);
    _messageTimer = Timer.periodic(messageInterval, (timer) {
      if (!mounted) return;
      if (_messageIndex >= _messages.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _messageIndex++);
    });

    _navigateTimer = Timer(_totalDuration, () {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _navigateTimer?.cancel();
    _introController.dispose();
    _driftController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuroraBackground(),
          AnimatedBuilder(
            animation: _driftController,
            builder: (context, child) => _DriftingGlows(t: _driftController.value),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: isCompact ? 16 : 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
                    child: ScaleTransition(
                      scale: CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
                      child: AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          final dy = math.sin(_floatController.value * math.pi) * 6;
                          return Transform.translate(offset: Offset(0, dy), child: child);
                        },
                        child: const _GlowLogoCard(),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 20 : 32),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _introController, curve: const Interval(0.25, 0.85, curve: Curves.easeOut)),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _introController, curve: const Interval(0.25, 0.85, curve: Curves.easeOut))),
                      child: Semantics(
                        header: true,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, AppColors.textSecondaryDark],
                          ).createShader(bounds),
                          child: Text(
                            'ClubHub',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCompact ? 34 : 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _introController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
                    child: Text(
                      'Build · Learn · Connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _introController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
                    child: Column(
                      children: [
                        const _GradientLoadingBar(),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 20,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            ),
                            child: Text(
                              _messages[_messageIndex],
                              key: ValueKey(_messageIndex),
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
                              semanticsLabel: _messages[_messageIndex],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 28),
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _introController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
                    child: Text(
                      'Version 2.0 · Powered by ClubHub · University CSE Community',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.28), letterSpacing: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static deep-navy → indigo base gradient. Kept as a `const`-friendly
/// stateless widget so it never rebuilds with the animated layers above it.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgDark, Color(0xFF131B33), AppColors.bgDark],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// Three soft, slowly-drifting glow blobs (royal blue, purple accent, cyan)
/// that read as an aurora/mesh gradient without a custom shader — cheap
/// enough to animate continuously per the "lightweight animations" goal.
class _DriftingGlows extends StatelessWidget {
  final double t;
  const _DriftingGlows({required this.t});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final angle = t * 2 * math.pi;

    Offset orbit(double phase, double radiusX, double radiusY) {
      return Offset(
        math.cos(angle + phase) * radiusX,
        math.sin(angle + phase) * radiusY,
      );
    }

    Widget blob(Color color, Alignment base, Offset drift, double blobSize) {
      return Align(
        alignment: base,
        child: Transform.translate(
          offset: drift,
          child: Container(
            width: blobSize,
            height: blobSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0.0)]),
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Stack(
          children: [
            blob(AppColors.primary, Alignment.topLeft, orbit(0, 40, 30), size.shortestSide * 0.9),
            blob(AppColors.accent, Alignment.bottomRight, orbit(2.1, 35, 45), size.shortestSide * 0.85),
            blob(AppColors.info, Alignment.center, orbit(4.2, 50, 20), size.shortestSide * 0.6),
          ],
        ),
      ),
    );
  }
}

class _GlowLogoCard extends StatelessWidget {
  const _GlowLogoCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ClubHub logo',
      image: true,
      child: Container(
        width: 112,
        height: 112,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.accent.withValues(alpha: 0.9), AppColors.info.withValues(alpha: 0.9)],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 4),
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 60, spreadRadius: 8),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: AppColors.bgDark.withValues(alpha: 0.65),
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indeterminate gradient loading line — replaces a generic spinner.
class _GradientLoadingBar extends StatefulWidget {
  const _GradientLoadingBar();

  @override
  State<_GradientLoadingBar> createState() => _GradientLoadingBarState();
}

class _GradientLoadingBarState extends State<_GradientLoadingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: 140,
        height: 3.5,
        color: Colors.white.withValues(alpha: 0.08),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Align(
              alignment: Alignment(-1.6 + 3.2 * _controller.value, 0),
              child: FractionallySizedBox(
                widthFactor: 0.4,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent, AppColors.info]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
