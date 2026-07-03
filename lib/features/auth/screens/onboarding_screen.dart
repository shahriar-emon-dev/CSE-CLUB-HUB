import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Carousel
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: [
              _buildSlide1(),
              _buildSlide2(),
              _buildSlide3(),
              _buildSlide4(),
            ],
          ),
          
          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        const Text('ClubHub', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_currentIndex < 3)
                      TextButton(
                        onPressed: () => _pageController.animateToPage(3, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                        child: const Text('Skip', style: TextStyle(color: AppColors.textSecondaryDark)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Indicators
          if (_currentIndex < 3)
            Positioned(
              bottom: 48, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentIndex == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlide1() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Orbit rings
        AnimatedBuilder(
          animation: _orbitController,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(0.785)
                ..rotateZ(_orbitController.value * 2 * math.pi),
              child: child,
            );
          },
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orbitController,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(0.785)
                ..rotateZ(-_orbitController.value * 2 * math.pi * 1.5),
              child: child,
            );
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 1),
            ),
          ),
        ),
        
        // Center Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Wrap(
                 spacing: 16,
                 runSpacing: 16,
                 alignment: WrapAlignment.center,
                 children: [
                   _buildGlassIcon(Icons.terminal, AppColors.primary, true),
                   _buildGlassIcon(Icons.memory, AppColors.accent, false),
                   _buildGlassIcon(Icons.shield, AppColors.success, false),
                   _buildGlassIcon(Icons.psychology, AppColors.primary, false),
                   _buildGlassIcon(Icons.data_usage, AppColors.accent, false),
                   _buildGlassIcon(Icons.cloud, AppColors.info, false),
                 ],
               ),
               const SizedBox(height: 48),
               Text('Unified Pulse', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               Text('One place for all 6 CSE club updates. Stay synced with the heart of our tech ecosystem.', 
                 textAlign: TextAlign.center,
                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryDark),
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassIcon(IconData icon, Color color, bool glow) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Icon(icon, color: color, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide2() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               SizedBox(
                 height: 200,
                 child: Stack(
                   alignment: Alignment.center,
                   children: [
                     Positioned(
                       left: 20, top: 40,
                       child: Transform.rotate(
                         angle: -0.1,
                         child: _buildNotificationMock(Icons.event, AppColors.primary, 'Hackathon this Friday', 'Don\'t miss out'),
                       ),
                     ),
                     Positioned(
                       right: 10, bottom: 40,
                       child: Transform.rotate(
                         angle: 0.05,
                         child: _buildNotificationMock(Icons.notifications_active, AppColors.accent, 'New Notice Posted', 'Check out the new rules'),
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 32),
               Text('Real-Time Precision', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               Text('Never miss an event or notice. Our smart notification engine ensures you\'re always in the loop.', 
                 textAlign: TextAlign.center,
                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryDark),
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationMock(IconData icon, Color color, String t1, String t2) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
               CircleAvatar(
                 backgroundColor: color,
                 child: Icon(icon, color: Colors.white, size: 20),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Container(height: 8, width: 100, color: Colors.white.withValues(alpha: 0.3)),
                     const SizedBox(height: 6),
                     Container(height: 8, width: 60, color: Colors.white.withValues(alpha: 0.1)),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide3() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 100, right: -50,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 80, spreadRadius: 40)],
            ),
          ),
        ),
        Positioned(
          bottom: 100, left: -50,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.info.withValues(alpha: 0.1),
              boxShadow: [BoxShadow(color: AppColors.info.withValues(alpha: 0.1), blurRadius: 80, spreadRadius: 40)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 50,
                      child: _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuDqf_bqNACS74w-EiQoP4igQcvEouwSIZ61JuTd_NveL9B-61WMaeI-EGcqgnNAjWxLVBYCHi_5Eyt2NTM9ZnSzdHG_bUyAAW2_4sl37eiun7cWzNSHBgvnRv9aspuGp83DrM1zgz5ZS3o1WvgdVxPBLKBE5xG0r_hoWsrOmXGaosRlKrna46XUvKU2O15iT6X5r7r3IGhAlMMTaE3sC5-8ISMQT4YyF37ptDo7oEdu8G-eu_vUJgjwgt9HneilRl5Gco7_aYMEV1I', 70),
                    ),
                    Positioned(
                      right: 50,
                      child: _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuDntPjDSJnzF0rnJ93Y1xsM0CUVgpVboG0yCZxIxyZOg0oaW6YrIqYrTgm2mD3WYHYdpcb8XUXHnHmUPP_aAmwUn6ruUXa8_ux7Nnv7Jz1GqX2UC2YfNC1VmQ8Pu-AIZNYRKgxD8cIX2o39xj46xS-wREhkVz5aNkGammwpgb_V7jROVhe5EqX_lduC0MrtFv2IWQtf-PXHUIv_HYIPxrCSfH2lTcEUlkT-6pZd2zDdMhAOaHg11AXxNWF_b4LVNpVXNr-A0tnRlTw', 70),
                    ),
                    Positioned(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
                        ),
                        child: _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuBRfso0SamxehcKsFoxfOVSRYqWeDKfekRTa3IutXiMFoYV2RoQ6CkAufl9VHwHlDVvOtH8gYgOhWBhDZkfnqwoeIx4KXDHF0xza4hdjE8cM0TqhDBB9Yhc3nVxyHL59EjmEfUwZtyQsmJwo3Ymvq1fGyqztFiV2WqjoW2GVkgCaHQPsXmHEraueKNwp-BTv8g6HExpiB2Mq8Z9crqRLh8fhZUQwTsQjrIuJFV-RQXZJI0tROlNLccjrNS4OC-bszicSDwh6nz0xjM', 90),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text('Digital Kinship', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Connect with your tech community. Forge bonds with builders, creators, and innovators in your department.', 
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String url, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bgDark, width: 4),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSlide4() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Enter the Hub.', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Your executive gateway to everything CSE is ready. Join the movement today.', 
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text('I already have an account', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
