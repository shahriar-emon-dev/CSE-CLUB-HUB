import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'profile_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  List<String> _skills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(currentProfileProvider.future);
    if (profile != null && mounted) {
      _nameCtrl.text = profile.fullName;
      _bioCtrl.text = profile.bio ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _githubCtrl.text = profile.githubUrl ?? '';
      _linkedinCtrl.text = profile.linkedinUrl ?? '';
      _portfolioCtrl.text = profile.portfolioUrl ?? '';
      setState(() => _skills = List.from(profile.skills));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _phoneCtrl.dispose();
    _githubCtrl.dispose(); _linkedinCtrl.dispose(); _portfolioCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.currentUserId!;
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(userId, {
        'full_name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'github_url': _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
        'linkedin_url': _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'portfolio_url': _portfolioCtrl.text.trim().isEmpty ? null : _portfolioCtrl.text.trim(),
        'skills': _skills,
      });

      ref.invalidate(currentProfileProvider);
      ref.invalidate(profileProvider(null));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveSuccess), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(AppStrings.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_nameCtrl, 'Full Name', Icons.person_outline, required: true),
            const SizedBox(height: 16),
            _field(_phoneCtrl, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Text('Social Links', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _field(_githubCtrl, 'GitHub URL', Icons.code),
            const SizedBox(height: 12),
            _field(_linkedinCtrl, 'LinkedIn URL', Icons.work_outline),
            const SizedBox(height: 12),
            _field(_portfolioCtrl, 'Portfolio URL', Icons.language),
            const SizedBox(height: 24),
            Text('Skills', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillCtrl,
                    decoration: const InputDecoration(hintText: 'Add skill...', prefixIcon: Icon(Icons.star_outline)),
                    onFieldSubmitted: (v) {
                      if (v.isNotEmpty && !_skills.contains(v)) {
                        setState(() => _skills.add(v));
                        _skillCtrl.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: () {
                    final v = _skillCtrl.text.trim();
                    if (v.isNotEmpty && !_skills.contains(v)) {
                      setState(() => _skills.add(v));
                      _skillCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _skills.map((s) => Chip(
                  label: Text(s),
                  onDeleted: () => setState(() => _skills.remove(s)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    bool required = false, TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
    );
  }
}
