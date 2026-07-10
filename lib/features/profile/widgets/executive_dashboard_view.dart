import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/user_profile.dart';

class ExecutiveDashboardView extends ConsumerWidget {
  final UserProfile profile;

  const ExecutiveDashboardView({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXECUTIVE MANAGEMENT SUITE',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.managedClubId != null
                            ? 'Club Lead: ${profile.managedClubId!.toUpperCase()}'
                            : 'Department Club Executive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF4CAF50)),
                    SizedBox(width: 6),
                    Text('ACTIVE LEADERSHIP', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          // 6 Dashboard Metrics Grid
          const Text('Club Performance & Analytics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.6,
            children: [
              _buildMetricCard('Member Count', '248', Icons.group, const Color(0xFF2196F3), '+12 this month'),
              _buildMetricCard('Total Events', '14', Icons.calendar_month, const Color(0xFF4CAF50), '3 upcoming'),
              _buildMetricCard('Total Posts', '36', Icons.article, const Color(0xFFFF9800), '98% reach'),
              _buildMetricCard('Attendees', '1,420', Icons.confirmation_number, const Color(0xFF9C27B0), 'Average 101/ev'),
              _buildMetricCard('Engagement Rate', '84.2%', Icons.trending_up, const Color(0xFFE91E63), 'Top 5% on campus'),
              _buildMetricCard('Pending Approvals', '0', Icons.rule, const Color(0xFF00BCD4), 'All caught up!'),
            ],
          ),
          const SizedBox(height: 28),

          // 7 Management Actions
          const Text('Executive Action Center', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionChip(
                context,
                icon: Icons.add_circle,
                label: 'Create Club Event',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.createEvent),
              ),
              _buildActionChip(
                context,
                icon: Icons.campaign,
                label: 'Publish Club Announcement',
                color: const Color(0xFFFF9800),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Post creation for Club Announcements...')),
                  );
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.manage_accounts,
                label: 'Manage Club Members',
                color: const Color(0xFF2196F3),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing member roster for ${profile.managedClubId ?? "CSE Club"}...')),
                  );
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.edit,
                label: 'Edit Club Details',
                color: const Color(0xFF9C27B0),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Club settings editor...')),
                  );
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.fact_check,
                label: 'Review Event RSVPs',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Displaying verified RSVP checklist...')),
                  );
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.file_download,
                label: 'Export Attendance List',
                color: const Color(0xFF00BCD4),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance CSV exported safely to documents folder.')),
                  );
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.admin_panel_settings,
                label: 'Request Admin Approval',
                color: const Color(0xFFE91E63),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Priority request sent to Super Admin desk.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
