import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/supabase_config.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  final int _totalSteps = 2;
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  
  String _selectedCluster = 'CSE';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    _batchCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Complete Setup
      setState(() => _isLoading = true);
      try {
        final userId = SupabaseConfig.currentUserId;
        if (userId != null) {
          await SupabaseConfig.client.from('profiles').update({
            'full_name': _nameCtrl.text.trim(),
            'student_id': _studentIdCtrl.text.trim(),
            'batch': _batchCtrl.text.trim(),
            // Assuming section/cluster is stored in bio or skills or custom columns
            // since schema doesn't have section explicitly.
          }).eq('id', userId);
        }
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentStep / _totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: 100, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50)],
              ),
            ),
          ),
          Positioned(
            bottom: 100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50)],
              ),
            ),
          ),
          
          // Header Progress
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 4, width: double.infinity,
                    color: AppColors.surfaceContainerDark,
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      width: MediaQuery.of(context).size.width * progress,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10)],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        const Text('ClubHub', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Text('Onboarding', style: TextStyle(color: AppColors.textSecondaryDark)),
                        const SizedBox(width: 16),
                        const Icon(Icons.help_outline, color: AppColors.textSecondaryDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 100, bottom: 80, left: 24, right: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131F).withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
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
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom Navigation / Dots Indicator
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentStep >= 1 ? AppColors.primary : Colors.white24)),
                    const SizedBox(width: 12),
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentStep >= 2 ? AppColors.primary : Colors.white24)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Claim Your Identity', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
        const SizedBox(height: 8),
        const Text('Set a profile picture that represents your late-night studio energy.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
        const SizedBox(height: 48),
        
        Center(
          child: Stack(
            children: [
              Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppColors.surfaceContainerDark,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30)],
                ),
                child: const Center(child: Icon(Icons.person, size: 80, color: AppColors.textSecondaryDark)),
              ),
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceDark, width: 2),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Center(child: Text('Recommended: Square PNG or JPG, min 400px.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14))),
        const SizedBox(height: 48),
        
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('The Credentials', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
        const SizedBox(height: 8),
        const Text('Tell us where you fit in the department ecosystem.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
        const SizedBox(height: 32),
        
        Row(
          children: [
            Expanded(child: _buildTextField('Full Name', _nameCtrl, 'e.g. Alex Rivera')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Student ID', _studentIdCtrl, 'CSE-2024-001')),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Batch', _batchCtrl, '2024')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Section', _sectionCtrl, 'A1')),
          ],
        ),
        const SizedBox(height: 24),
        
        const Text('Department Cluster', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: ['CSE', 'SWE', 'EEE'].map((cluster) {
              final isSelected = _selectedCluster == cluster;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCluster = cluster),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cluster,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 48),
        
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true, fillColor: const Color(0xFF0D0D14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          TextButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondaryDark),
            label: const Text('Back', style: TextStyle(color: AppColors.textSecondaryDark)),
          )
        else
          const SizedBox(), // Placeholder to push Continue to the right
        
        const Spacer(),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          onPressed: _isLoading ? null : _nextStep,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  children: [
                    Text(_currentStep == _totalSteps ? 'Complete Setup' : 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_currentStep < _totalSteps) const SizedBox(width: 8),
                    if (_currentStep < _totalSteps) const Icon(Icons.chevron_right),
                  ],
                ),
        ),
      ],
    );
  }
}
