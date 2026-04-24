import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validation/input_validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _confirmPasswordValidator(String? value) {
    final confirmedPassword = value ?? '';
    if (confirmedPassword.isEmpty) return 'Confirm password is required';

    if (confirmedPassword != _passwordController.text) {
      // Why: We validate in UI first to avoid unnecessary auth requests when passwords differ.
      return 'Passwords do not match';
    }

    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Create Account',
                        subtitle: 'Use your university email to join CSE Club Hub',
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: 'University Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                        validator: InputValidators.email,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        label: 'Password',
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        validator: InputValidators.password,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        validator: _confirmPasswordValidator,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Text(
                          'All new accounts start as Student. Executive access is assigned only by an admin after review.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (authState.errorMessage != null)
                        Text(
                          authState.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (authState.errorMessage != null)
                        const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Continue',
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
