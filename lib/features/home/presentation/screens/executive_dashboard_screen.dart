import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/event_card_widget.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../../../../shared/widgets/modal_dialog.dart';
import '../../../../shared/widgets/post_card_widget.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stats_card.dart';

class ExecutiveDashboardScreen extends StatelessWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Executive Dashboard',
                    subtitle: 'Operate your club with posts, events, and branding.',
                    trailing: const RoleBadge(
                      label: 'Executive',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 3 : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 3.7 : 1.5,
                        children: const [
                          StatsCard(
                            label: 'Total posts',
                            value: '128',
                            icon: Icons.post_add_outlined,
                          ),
                          StatsCard(
                            label: 'Total events',
                            value: '24',
                            icon: Icons.event_outlined,
                          ),
                          StatsCard(
                            label: 'Followers',
                            value: '2.4K',
                            icon: Icons.groups_2_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Create content and updates from one place.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'Create Post',
                          icon: Icons.post_add_outlined,
                          isPrimary: true,
                          onPressed: () => _showActionDialog(
                            context,
                            title: 'Create Post',
                            message: 'Hook this action to the existing post creation flow when available.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          label: 'Create Event',
                          icon: Icons.event_available_outlined,
                          onPressed: () => _showCreateEventSheet(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Manage Posts',
                    subtitle: 'Pin, edit, or delete posts for your club.',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'CSE Club',
                    club: 'Executive Feed',
                    content: 'Tech talk this Friday with limited seats. Register from the events tab.',
                    timestamp: 'Pinned',
                  ),
                  const SizedBox(height: 12),
                  const PostCardWidget(
                    author: 'CSE Club',
                    club: 'Executive Feed',
                    content: 'New mentorship program applications are now open for first-year students.',
                    timestamp: '2h ago',
                  ),
                  const SizedBox(height: 12),
                  ActionButton(
                    label: 'Edit / Delete / Pin',
                    icon: Icons.tune,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Manage Events',
                    subtitle: 'Keep your club calendar current and easy to scan.',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Tech Talk: AI in Campus Life',
                    date: '22 Apr • 3:00 PM',
                    venue: 'Auditorium A',
                  ),
                  const SizedBox(height: 12),
                  const EventCardWidget(
                    title: 'Project Showcase',
                    date: '29 Apr • 11:00 AM',
                    venue: 'Innovation Lab',
                  ),
                  const SizedBox(height: 12),
                  ActionButton(
                    label: 'Edit / Cancel',
                    icon: Icons.edit_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Club Management',
                    subtitle: 'Update branding, messaging, and club details.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSE Club',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Logo, cover image, and description editor placeholders are ready for the connected form.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Empty State Preview',
                    subtitle: 'Useful when no moderation items are waiting.',
                  ),
                  const SizedBox(height: 12),
                  const EmptyState(
                    title: 'No pending executive tasks',
                    message: 'Everything looks up to date. New posts, events, or reports will appear here.',
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Loading State Preview',
                    subtitle: 'Reusable skeletons for future async data.',
                  ),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 96),
                  const SizedBox(height: 12),
                  const LoadingSkeleton(height: 96),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        activeRoute: AppRoutes.profileDashboard,
      ),
    );
  }

  void _showActionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ModalDialog(
          title: title,
          message: message,
          primaryLabel: 'Close',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(),
          icon: Icons.info_outline,
        );
      },
    );
  }
}

class _ClubOption {
  const _ClubOption({required this.id, required this.name});

  final String id;
  final String name;
}

Future<void> _showCreateEventSheet(BuildContext context) async {
  final client = Supabase.instance.client;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();

  try {
    final clubsResponse = await client
        .from('clubs')
        .select('id,name')
        .order('name', ascending: true);

    final clubs = (clubsResponse as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((row) => _ClubOption(
              id: row['id'].toString(),
              name: row['name']?.toString() ?? 'Club',
            ))
        .toList();

    if (!context.mounted) return;

    if (clubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clubs available for event creation.')),
      );
      return;
    }

    String selectedClubId = clubs.first.id;
    DateTime? selectedDateTime;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: sheetContext,
                firstDate: now,
                lastDate: DateTime(now.year + 5),
                initialDate: selectedDateTime ?? now,
              );

              if (!sheetContext.mounted) return;
              if (pickedDate == null) return;

              final pickedTime = await showTimePicker(
                context: sheetContext,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
              );

              if (!sheetContext.mounted) return;
              if (pickedTime == null) return;

              setSheetState(() {
                selectedDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            Future<void> submit() async {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final venue = venueController.text.trim();

              if (title.isEmpty || description.isEmpty || venue.isEmpty || selectedDateTime == null) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields before creating the event.')),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);

              try {
                await client.from('events').insert({
                  'title': title,
                  'description': description,
                  'event_datetime': selectedDateTime!.toUtc().toIso8601String(),
                  'venue': venue,
                  'club_id': selectedClubId,
                  'created_by': client.auth.currentUser!.id,
                });

                if (!sheetContext.mounted) return;

                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Event created successfully.')),
                );
              } catch (error) {
                if (!sheetContext.mounted) return;

                setSheetState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text('Failed to create event: $error')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter event title',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Write event description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue',
                        hintText: 'Enter event venue',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedClubId,
                      decoration: const InputDecoration(labelText: 'Club'),
                      items: clubs
                          .map(
                            (club) => DropdownMenuItem<String>(
                              value: club.id,
                              child: Text(club.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedClubId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isSubmitting ? null : pickDateTime,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        selectedDateTime == null
                            ? 'Select event date & time'
                            : 'Selected: ${selectedDateTime!.toLocal()}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting ? null : submit,
                            child: Text(isSubmitting ? 'Creating...' : 'Create Event'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to load clubs: $error')),
    );
  } finally {
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
  }
}
