import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'create_club_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D0D14),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          const SizedBox(height: 48),
          _buildStatGrid(context, ref),
          const SizedBox(height: 48),
          _buildQuickActions(context),
          const SizedBox(height: 48),
          _buildSystemFeed(ref),
          const SizedBox(height: 48),
          _buildFooter(),
        ],
      ),
    ));
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF362720), // surface-container-high
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.tertiary.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'System Control',
            style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5),
          ),
          SizedBox(height: 8),
          Text(
            'Platform integrity verified. All systems operational within department nodes. Managed access active for session SA-2024-X.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 18, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(dashboardStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return statsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      error: (error, stack) => Center(child: Text('Error loading stats: $error', style: const TextStyle(color: AppColors.error))),
      data: (stats) {
        return GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              icon: Icons.person_add,
              badge: '+12%',
              label: 'Total Students',
              value: stats.totalStudents.toString(),
              progressWidget: Container(
                height: 4,
                decoration: BoxDecoration(color: AppColors.surfaceVariantDark, borderRadius: BorderRadius.circular(2)),
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
              ),
            ),
            _buildStatCard(
              icon: Icons.hub,
              badgeText: '6 CSE Depts',
              label: 'Active Clubs',
              value: stats.activeClubs.toString(),
              progressWidget: Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.tertiary, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.5), blurRadius: 8)]))),
                  const SizedBox(width: 4),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.tertiary, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.5), blurRadius: 8)]))),
                  const SizedBox(width: 4),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.surfaceVariantDark, borderRadius: BorderRadius.circular(2)))),
                ],
              ),
            ),
            _buildStatCard(
              icon: Icons.calendar_month,
              badgeText: '32 Upcoming',
              label: 'Total Events',
              value: stats.totalEvents.toString(),
              progressWidget: Row(
                children: [
                  _buildStackedAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuB2QPbH948w53xf7g69OkyjauaM4OGmUrBq1_x90rLD-oYMy26GuTyFy2C3ejdh1MU1DKQRa0713bz4CSuW9OL9IuU81CLj716cKMCH36JArFkPZGSd9Mos7QigEwSFB-MlC7HcgfjYLhBgLBENHhhFw4LlQq6kVlAXAZZBWpW8t4oBci9KsaHtqPizmiUl_7aNoRMO-ZWBU6e5M-ArO9wwt9fd74oARp1JK2wi_K4UjeT7C_2qvLphVZpNkHxozE2VlDywpR0vZUc', 0),
                  Transform.translate(offset: const Offset(-8, 0), child: _buildStackedAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuBYWJTQI298HWxO--ChDJCe4JNw5PxydETByOubObAq412cRBxIZ5j4jv9E-L1r9wa_YBx0Q-buSxvDEPuI6qmI4gD8rBG3WGhr5hPVCB70ab3FbinTzTRdtC7QyfycxqmXcW4nVCmdTM5TqHKuAFrJ7ZILO3VxkvSHb10W1AJqUbqOS9k7uv35685_Gh8gmGTGrDx9GLcjeotkVxlRDshmIKSxZsQNBg_C9JfiHdxCrFyaVnON3OsoKquDx7HPQ80DnmaXQeRlfkc', 1)),
                  Transform.translate(
                    offset: const Offset(-16, 0),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiary, border: Border.all(color: const Color(0xFF1D100A), width: 2)),
                      child: const Center(child: Text('+30', style: TextStyle(color: Color(0xFF412D00), fontSize: 10, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatCard(
              icon: Icons.report_problem,
              iconColor: AppColors.error,
              badgeText: 'Urgent',
              isUrgent: true,
              label: 'Pending Reports',
              value: '12', // Mocked pending reports
              progressWidget: Row(
                children: const [
                  Text('Review Queue', style: TextStyle(color: AppColors.tertiary, fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: AppColors.tertiary, size: 14),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStackedAvatar(String url, int index) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1D100A), width: 2),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    String? badge,
    String? badgeText,
    required String label,
    required String value,
    required Widget progressWidget,
    Color iconColor = AppColors.tertiary,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(4),
          bottomLeft: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: const TextStyle(color: AppColors.tertiary, fontSize: 14)),
                )
              else if (badgeText != null)
                Row(
                  children: [
                    if (isUrgent)
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error), margin: const EdgeInsets.only(right: 4)),
                    Text(badgeText, style: TextStyle(color: isUrgent ? AppColors.error : AppColors.textSecondaryDark, fontSize: 14, fontStyle: isUrgent ? FontStyle.normal : FontStyle.italic)),
                  ],
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1)),
            ],
          ),
                progressWidget,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('EXECUTIVE CONTROLS', style: TextStyle(color: AppColors.tertiary, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const CreateClubScreen()));
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New Club'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: const Color(0xFF1D100A),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 12,
                shadowColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage Executives'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: const Color(0xFF412D00),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 12,
                shadowColor: AppColors.tertiary.withValues(alpha: 0.5),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.security),
              label: const Text('Moderate Content'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tertiary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: AppColors.tertiary, width: 2),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings_suggest),
              label: const Text('System Config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF362720),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemFeed(WidgetRef ref) {
    final activityAsync = ref.watch(systemActivityStreamProvider);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF261812), // surface-container-low
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF362720).withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.analytics, color: AppColors.tertiary),
                    SizedBox(width: 12),
                    Text('System Activity Feed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Text('Live Updates', style: TextStyle(color: AppColors.tertiary, fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: activityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
              error: (e, st) => Center(child: Text('Error loading feed: $e', style: const TextStyle(color: AppColors.error))),
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(child: Text('No recent system activities.', style: TextStyle(color: AppColors.textSecondaryDark)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    
                    // Determine icon and color based on entityType or actionType
                    IconData icon;
                    Color color;
                    
                    if (activity.entityType == 'user' || activity.entityType == 'role') {
                      icon = Icons.verified_user;
                      color = AppColors.primary;
                    } else if (activity.entityType == 'event') {
                      icon = Icons.event;
                      color = AppColors.secondary;
                    } else if (activity.entityType == 'system' || activity.entityType == 'security') {
                      icon = Icons.security_update_warning;
                      color = AppColors.error;
                    } else {
                      icon = Icons.smart_toy;
                      color = AppColors.tertiary;
                    }

                    return _buildFeedItem(
                      icon,
                      color,
                      activity.actorName,
                      ' ${activity.actionType} ${activity.entityType}',
                      timeago.format(activity.createdAt),
                      activity.description,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(IconData icon, Color color, String boldText, String normalText, String time, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF41312A),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: boldText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                            TextSpan(text: normalText, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    Text(time, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          const Text('© 2024 ClubCentral Enterprise Admin Portal', style: TextStyle(color: AppColors.tertiary, fontSize: 12)),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: const [
              Text('System Status', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              Text('Security Policy', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              Text('Support', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              Text('API Docs', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
