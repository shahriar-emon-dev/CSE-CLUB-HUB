import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/events_provider.dart';

class CancelEventDialog extends ConsumerWidget {
  final String eventId;
  final int rsvpCount;

  const CancelEventDialog({
    super.key,
    required this.eventId,
    required this.rsvpCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifierState = ref.watch(eventNotifierProvider);
    final isLoading = notifierState.isLoading;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(4),
          bottomLeft: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: const Color(0xFF13131F).withValues(alpha: 0.8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              children: [
                // Atmospheric Glow
                Positioned(
                  top: -64,
                  right: -64,
                  child: Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.15),
                          blurRadius: 60,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                            ),
                            child: const Center(
                              child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
                            ),
                          ),
                          IconButton(
                            onPressed: isLoading ? null : () => context.pop(),
                            icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cancel Event?',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          text: 'This will notify all ',
                          style: GoogleFonts.firaSans(
                            color: AppColors.textSecondaryDark,
                            fontSize: 18,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: '$rsvpCount registered student${rsvpCount == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: ' and remove the event from the calendar. This action cannot be undone.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                try {
                                  await ref.read(eventNotifierProvider.notifier).cancelEvent(eventId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Event cancelled successfully.')),
                                    );
                                    context.pop(true); // Return true to indicate success
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to cancel event: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB00020),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                elevation: 8,
                                shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                              ),
                              child: isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Cancel Event', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : () => context.pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text('Keep Event', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
