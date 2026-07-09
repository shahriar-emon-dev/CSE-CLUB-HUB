import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../../../models/content_report.dart';

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(moderationActionProvider, (previous, next) {
      next.whenOrNull(
        error: (e, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Moderation action failed: $e'), backgroundColor: AppColors.error),
          );
        },
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Action executed successfully.'), backgroundColor: AppColors.primary),
            );
          }
        },
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(ref),
          const SizedBox(height: 32),
          _buildStatsBar(context, ref),
          const SizedBox(height: 32),
          _buildModerationQueue(ref),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final currentFilter = ref.watch(moderationFilterProvider);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Content Moderation', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5)),
              SizedBox(height: 8),
              Text('Review reported activity across all campus hubs. Act with precision to maintain community standards.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF2b1c16), // surface-container
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterButton('All', currentFilter, ref),
              _buildFilterButton('Posts', currentFilter, ref),
              _buildFilterButton('Events', currentFilter, ref),
              _buildFilterButton('Comments', currentFilter, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String currentFilter, WidgetRef ref) {
    final isSelected = label == currentFilter;
    return InkWell(
      onTap: () => ref.read(moderationFilterProvider.notifier).state = label,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF412D00) : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(moderationStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      error: (e, st) => Center(child: Text('Error loading stats: $e', style: const TextStyle(color: AppColors.error))),
      data: (stats) {
        return GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard('In Queue', stats['inQueue'].toString(), AppColors.tertiary, borderLeftColor: AppColors.tertiary),
            _buildStatCard('High Risk', stats['highRisk'].toString(), AppColors.error, borderLeftColor: AppColors.error),
            _buildStatCard('Resolved Today', (stats['resolvedToday'] ?? 0).toString(), Colors.white),
            _buildStatCard('Avg. Response', '${stats['avgResponseMinutes'] ?? 0}m', Colors.white),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor, {Color? borderLeftColor}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2b1c16).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (borderLeftColor != null)
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 4, color: borderLeftColor),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(value, style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).wrapWithBlur(20, 12);
  }

  Widget _buildModerationQueue(WidgetRef ref) {
    final reportsAsync = ref.watch(contentReportsProvider);
    final isActionLoading = ref.watch(moderationActionProvider).isLoading;

    return reportsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator(color: AppColors.tertiary))),
      error: (e, st) => Center(child: Padding(padding: const EdgeInsets.all(48.0), child: Text('Failed to load queue: $e', style: const TextStyle(color: AppColors.error)))),
      data: (reports) {
        if (reports.isEmpty) {
          return _buildEmptyState();
        }
        
        return Column(
          children: reports.map((report) => _buildReportItem(report, ref, isActionLoading)).toList(),
        );
      },
    );
  }

  Widget _buildReportItem(ContentReport report, WidgetRef ref, bool isActionLoading) {
    final isHighRisk = report.severity == 'high';
    final isRoutine = report.severity == 'low';
    
    Color borderColor = AppColors.tertiary; // Default to medium
    if (isHighRisk) borderColor = AppColors.error;
    if (isRoutine) borderColor = const Color(0xFF5a4136); // outline-variant

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2b1c16).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: isHighRisk ? [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.15), blurRadius: 20)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 4, color: borderColor),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Content Meta & Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meta tags
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHighRisk ? AppColors.error.withValues(alpha: 0.2) : (isRoutine ? Colors.transparent : AppColors.tertiary.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isHighRisk ? AppColors.error.withValues(alpha: 0.3) : (isRoutine ? Colors.white.withValues(alpha: 0.1) : AppColors.tertiary.withValues(alpha: 0.3))),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isHighRisk) const Icon(Icons.warning, color: AppColors.error, size: 14),
                                      if (isHighRisk) const SizedBox(width: 4),
                                      Text(
                                        isHighRisk ? 'High Risk' : (isRoutine ? 'Routine Check' : 'Medium Risk'),
                                        style: TextStyle(color: isHighRisk ? AppColors.error : (isRoutine ? AppColors.textSecondaryDark : AppColors.tertiary), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF41312A), borderRadius: BorderRadius.circular(16)),
                                  child: Text(report.contentType.toUpperCase(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, color: AppColors.textSecondaryDark, size: 14),
                                    const SizedBox(width: 4),
                                    Text(timeago.format(report.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Content Body
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(report.authorAvatar ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(report.authorName ?? "Unknown")}&background=1d100a&color=e9c176'),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(report.authorName ?? 'Unknown Author', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(report.reporterName != null ? 'Reported by: ${report.reporterName}' : 'System Flagged', style: const TextStyle(color: AppColors.tertiary, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (report.contentTitle != null && report.contentTitle!.isNotEmpty)
                                  Text(report.contentTitle!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                if (report.contentText != null)
                                  Text('"${report.contentText!}"', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right Actions
                  Container(
                    width: 250,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(isHighRisk ? Icons.flag : Icons.visibility, color: isHighRisk ? AppColors.error : AppColors.textSecondaryDark, size: 18),
                            const SizedBox(width: 8),
                            Text(isHighRisk ? 'Multiple Reports' : 'Awaiting Review', style: TextStyle(color: isHighRisk ? AppColors.error : AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Reason: ${report.reason}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isActionLoading ? null : () {
                                  ref.read(moderationActionProvider.notifier).handleReport(report.reportId, 'approve', report.contentType, report.entityId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.tertiary,
                                  foregroundColor: const Color(0xFF412D00),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: isActionLoading ? null : () {
                                ref.read(moderationActionProvider.notifier).handleReport(report.reportId, 'delete', report.contentType, report.entityId);
                              },
                              icon: const Icon(Icons.delete),
                              color: AppColors.error,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.error.withValues(alpha: 0.2))),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).wrapWithBlur(20, 16);
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: const Color(0xFF2b1c16).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid), // Dart doesn't support dashed border natively easily without custom painter, using solid.
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user, color: AppColors.tertiary, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Queue is Clear', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('All reported content has been reviewed.\nThe community is currently compliant with guidelines.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
        ],
      ),
    ).wrapWithBlur(20, 24);
  }
}

extension _BlurExtension on Widget {
  Widget wrapWithBlur(double sigma, [double radius = 16.0]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: this,
      ),
    );
  }
}
