import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _obscurePass = true;
  bool _termsAccepted = false;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 0.8).animate(_glowController);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must accept the terms first.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Try extracting ID from the email (name.id@smuct.ac.bd)
    String? extractedId;
    final email = _emailCtrl.text.trim();
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2) {
      extractedId = parts.last; // Assume the last part before @ is the ID
    }

    await ref.read(authNotifierProvider.notifier).signUp(
      email: email,
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      studentId: extractedId,
      batch: null,
    );
    
    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppColors.error),
      );
    } else if (!state.hasError && mounted) {
      context.go(AppRoutes.emailVerification);
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
          // Atmospheric Background Elements
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50, right: -50,
                    child: Opacity(
                      opacity: _glowAnimation.value,
                      child: Container(
                        width: 400, height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 80, spreadRadius: 40)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50, left: -50,
                    child: Opacity(
                      opacity: _glowAnimation.value,
                      child: Container(
                        width: 300, height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 80, spreadRadius: 40)],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Header Navigation Shell
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark.withValues(alpha: 0.8),
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        const Text('ClubHub', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Main Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 80, bottom: 32, left: 24, right: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131F).withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15))],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Stack(
                        children: [
                          // Branding Accent
                          Positioned(
                            left: 0, top: 100, bottom: 100,
                            child: Container(
                              width: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
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
                                  const Text('Initialize Profile', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                                  const SizedBox(height: 8),
                                  const Text('Join the late-night engineering ecosystem.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                                  const SizedBox(height: 32),
                                  
                                  _buildTextField(
                                    controller: _nameCtrl,
                                    label: 'Full Name',
                                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  _buildTextField(
                                    controller: _emailCtrl,
                                    label: 'University Email',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Email is required';
                                      // Validate name.id@smuct.ac.bd
                                      final regex = RegExp(r'^.+?\.[a-zA-Z0-9]+@smuct\.ac\.bd$');
                                      if (!regex.hasMatch(v)) {
                                        return 'Please use a valid name.id@smuct.ac.bd domain';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  StatefulBuilder(
                                    builder: (context, setPassState) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildTextField(
                                            controller: _passCtrl,
                                            label: 'Secret Key (Password)',
                                            obscureText: _obscurePass,
                                            onChanged: (_) => setPassState(() {}),
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondaryDark),
                                              onPressed: () => setPassState(() => _obscurePass = !_obscurePass),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) return 'Password is required';
                                              if (v.length < 6) return 'Minimum 6 characters';
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStrengthIndicator(_passCtrl.text),
                                        ],
                                      );
                                    }
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Terms Checkbox
                                  InkWell(
                                    onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 24, height: 24,
                                          child: Checkbox(
                                            value: _termsAccepted,
                                            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                                            activeColor: AppColors.primary,
                                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'I accept the ',
                                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                                              children: [
                                                const TextSpan(text: 'Department Protocol', style: TextStyle(color: AppColors.primary)),
                                                const TextSpan(text: ' and '),
                                                const TextSpan(text: 'Privacy Terms', style: TextStyle(color: AppColors.primary)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // CTA
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
                                          : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Already registered? ', style: TextStyle(color: AppColors.textSecondaryDark)),
                                      InkWell(
                                        onTap: () => context.go(AppRoutes.login),
                                        child: const Row(
                                          children: [
                                            Text('Access Login', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward, size: 16, color: AppColors.secondary),
                                          ],
                                        ),
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
          
          // Context Info
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Center(
              child: Text(
                'CSE DEPARTMENT GATEWAY | VERSION 4.0.2',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        filled: true,
        fillColor: AppColors.bgDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildStrengthIndicator(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8 && RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;

    int fillCount = strength == 0 ? 0 : strength;
    String text = strength == 0 ? '' : strength == 1 ? 'Weak' : strength == 2 ? 'Moderate Strength' : strength == 3 ? 'Good' : 'Strong';
    Color color = strength < 2 ? AppColors.error : strength < 4 ? AppColors.primary : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index < fillCount ? color : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        if (text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
