import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _obscurePass = true;
  bool _showError = false;
  String _errorMsg = '';
  
  late AnimationController _glowController;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    

    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _showError = false);
    
    await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    
    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      setState(() {
        _showError = true;
        _errorMsg = state.error.toString();
      });
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Bottom gradient decoration
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height / 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.primary.withValues(alpha: 0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131F).withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: Border.all(color: _showError ? AppColors.error.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: _showError ? AppColors.error.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: _showError ? 15 : 20,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Stack(
                          children: [
                            // Top right blur glow
                            Positioned(
                              top: -64, right: -64,
                              child: Container(
                                width: 128, height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 20)],
                                ),
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Mobile brand header
                                    Row(
                                      children: [
                                        const Icon(Icons.hub_rounded, color: AppColors.primary, size: 32),
                                        const SizedBox(width: 8),
                                        const Text('ClubHub', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    const Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                                    const SizedBox(height: 8),
                                    const Text('Enter your studio credentials to continue.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                                    const SizedBox(height: 32),
                                    
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4, bottom: 8),
                                      child: Text('Academic Email', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w500)),
                                    ),
                                    _buildTextField(
                                      controller: _emailCtrl,
                                      hint: 'name@cse.edu',
                                      prefixIcon: Icons.alternate_email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Email is required';
                                        if (!v.contains('@')) return 'Enter a valid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Text('Password', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w500)),
                                        ),
                                        InkWell(
                                          onTap: () => context.push(AppRoutes.forgotPassword),
                                          child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    StatefulBuilder(
                                      builder: (context, setPassState) {
                                        return _buildTextField(
                                          controller: _passCtrl,
                                          hint: '••••••••',
                                          prefixIcon: Icons.lock_outline,
                                          obscureText: _obscurePass,
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondaryDark),
                                            onPressed: () => setPassState(() => _obscurePass = !_obscurePass),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Password is required';
                                            return null;
                                          },
                                        );
                                      }
                                    ),
                                    const SizedBox(height: 32),
                                    
                                    // Submit CTA
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 8,
                                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                        ),
                                        onPressed: isLoading ? null : _submit,
                                        child: isLoading
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('Log In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                  SizedBox(width: 8),
                                                  Icon(Icons.login, size: 20),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('New here? ', style: TextStyle(color: AppColors.textSecondaryDark)),
                                        InkWell(
                                          onTap: () => context.push(AppRoutes.register),
                                          child: const Text('Create account', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Error Alert Float
          if (_showError)
            Positioned(
              bottom: 40, left: 24, right: 24,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 10.0, end: 0.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: child,
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131F).withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
                      boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.15), blurRadius: 15)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Authentication Failed', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(_errorMsg, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondaryDark, size: 16),
                          onPressed: () => setState(() => _showError = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
        prefixIcon: Icon(prefixIcon, color: AppColors.textSecondaryDark),
        filled: true,
        fillColor: AppColors.bgDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
