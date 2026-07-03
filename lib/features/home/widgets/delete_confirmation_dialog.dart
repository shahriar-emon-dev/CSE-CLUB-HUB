import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

Future<bool?> showDeleteConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return const DeleteConfirmationDialog();
    },
  );
}

class DeleteConfirmationDialog extends StatefulWidget {
  const DeleteConfirmationDialog({super.key});

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool _isDeleting = false;

  void _handleDelete() async {
    setState(() => _isDeleting = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 40),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Atmospheric Accent Glow
              Positioned(
                top: -20, right: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(color: Colors.transparent)),
                ),
              ),

              // Studio Identity Marker
              Positioned(
                top: 0, left: 0, bottom: 0,
                child: Container(width: 4, color: AppColors.error.withValues(alpha: 0.4)),
              ),

              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.delete_forever, color: AppColors.error, size: 32),
                    ),
                    const SizedBox(height: 24),

                    // Content
                    const Text('Delete Post?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'This action cannot be undone. This will permanently remove the post from the feed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 8,
                          shadowColor: AppColors.error.withValues(alpha: 0.5),
                        ),
                        child: _isDeleting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isDeleting ? null : () => context.pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
