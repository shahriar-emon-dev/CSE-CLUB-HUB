import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../shared/widgets/main_bottom_nav.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;

  late final TabController _tabController;

  bool _loadingRole = true;
  bool _isAdmin = false;
  bool _busy = false;

  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _clubs = const [];
  List<Map<String, dynamic>> _posts = const [];
  List<Map<String, dynamic>> _events = const [];

  int _totalUsers = 0;
  int _totalPosts = 0;
  int _totalEvents = 0;
  int _totalRsvps = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loadingRole = false;
        _isAdmin = false;
      });
      return;
    }

    final profile = await _client.from('profiles').select('role').eq('id', user.id).maybeSingle();
    final role = profile?['role']?.toString() ?? 'student';

    if (!mounted) return;

    setState(() {
      _isAdmin = role == 'admin';
      _loadingRole = false;
    });

    if (_isAdmin) {
      await _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _busy = true;
    });

    try {
      final usersFuture = _client
          .from('profiles')
          .select('id, email, full_name, role, role_request, student_id')
          .order('created_at', ascending: false)
          .limit(200);

      final clubsFuture = _client
          .from('clubs')
          .select('id, name, description, is_active')
          .order('name', ascending: true)
          .limit(200);

      final postsFuture = _client
          .from('posts')
          .select('id, title, content, author_id, club:clubs(name), is_deleted, created_at')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(120);

      final eventsFuture = _client
          .from('events')
          .select('id, title, event_datetime, venue, is_cancelled, club:clubs(name)')
          .eq('is_cancelled', false)
          .order('event_datetime', ascending: true)
          .limit(120);

      final usersCountFuture = _client.from('profiles').select('id').count(CountOption.exact);
      final postsCountFuture = _client.from('posts').select('id').eq('is_deleted', false).count(CountOption.exact);
      final eventsCountFuture = _client.from('events').select('id').eq('is_cancelled', false).count(CountOption.exact);
      final rsvpCountFuture = _client.from('rsvps').select('id').count(CountOption.exact);

      final users = await usersFuture;
      final clubs = await clubsFuture;
      final posts = await postsFuture;
      final events = await eventsFuture;
      final usersCount = await usersCountFuture;
      final postsCount = await postsCountFuture;
      final eventsCount = await eventsCountFuture;
      final rsvpCount = await rsvpCountFuture;

      if (!mounted) return;

      setState(() {
        _users = users.cast<Map<String, dynamic>>();
        _clubs = clubs.cast<Map<String, dynamic>>();
        _posts = posts.cast<Map<String, dynamic>>();
        _events = events.cast<Map<String, dynamic>>();
        _totalUsers = usersCount.count;
        _totalPosts = postsCount.count;
        _totalEvents = eventsCount.count;
        _totalRsvps = rsvpCount.count;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _setRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role, 'role_request': false}).eq('id', userId);
    await _refreshAll();
  }

  Future<void> _createClub(String name, String description) async {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    await _client.from('clubs').insert({
      'slug': slug,
      'name': name,
      'description': description,
      'is_active': true,
    });

    await _refreshAll();
  }

  Future<void> _updateClub(String clubId, String name, String description) async {
    await _client.from('clubs').update({
      'name': name,
      'description': description,
    }).eq('id', clubId);

    await _refreshAll();
  }

  Future<void> _softDeleteClub(String clubId) async {
    await _client.from('clubs').update({'is_active': false}).eq('id', clubId);
    await _refreshAll();
  }

  Future<void> _deletePost(String postId) async {
    await _client.from('posts').update({'is_deleted': true}).eq('id', postId);
    await _refreshAll();
  }

  Future<void> _deleteEvent(String eventId) async {
    await _client.from('events').update({'is_cancelled': true}).eq('id', eventId);
    await _refreshAll();
  }

  Future<void> _showCreateClubDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Club'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Club name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              if (name.isEmpty || description.isEmpty) return;
              Navigator.of(context).pop();
              await _createClub(name, description);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: const SafeArea(
          child: Center(
            child: Text(
              'Access denied. Admin role required.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        bottomNavigationBar: const MainBottomNav(activeRoute: AppRoutes.profileDashboard),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Clubs'),
            Tab(text: 'Moderation'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(),
                  _buildClubsTab(),
                  _buildModerationTab(),
                  _buildStatsTab(),
                ],
              ),
      ),
      bottomNavigationBar: const MainBottomNav(activeRoute: AppRoutes.profileDashboard),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = _users[index];
          final role = user['role']?.toString() ?? 'student';

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user['full_name']?.toString().trim().isNotEmpty == true
                      ? user['full_name'].toString()
                      : user['email']?.toString() ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(user['email']?.toString() ?? ''),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: role == 'executive'
                          ? null
                          : () => _setRole(user['id'].toString(), 'executive'),
                      child: const Text('Promote Executive'),
                    ),
                    FilledButton.tonal(
                      onPressed: role == 'student'
                          ? null
                          : () => _setRole(user['id'].toString(), 'student'),
                      child: const Text('Demote Student'),
                    ),
                    FilledButton.tonal(
                      onPressed: role == 'admin'
                          ? null
                          : () => _setRole(user['id'].toString(), 'admin'),
                      child: const Text('Promote Admin'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClubsTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          FilledButton.icon(
            onPressed: _showCreateClubDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add New Club'),
          ),
          const SizedBox(height: 12),
          ..._clubs.map((club) {
            final id = club['id'].toString();
            final active = (club['is_active'] as bool?) ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    club['name']?.toString() ?? 'Club',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    club['description']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => _updateClub(
                          id,
                          club['name']?.toString() ?? '',
                          club['description']?.toString() ?? '',
                        ),
                        child: const Text('Edit'),
                      ),
                      FilledButton.tonal(
                        onPressed: !active ? null : () => _softDeleteClub(id),
                        child: const Text('Soft Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModerationTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Posts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._posts.map((post) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                post['title']?.toString().trim().isNotEmpty == true
                    ? post['title'].toString()
                    : (post['club']?['name']?.toString() ?? 'Post'),
              ),
              subtitle: Text(
                post['content']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deletePost(post['id'].toString()),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Events',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._events.map((event) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(event['title']?.toString() ?? 'Event'),
              subtitle: Text(event['club']?['name']?.toString() ?? 'Club'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteEvent(event['id'].toString()),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final postsByClub = <String, int>{};
    final eventsByClub = <String, int>{};

    for (final row in _posts) {
      final clubName = row['club']?['name']?.toString() ?? 'Unknown';
      postsByClub[clubName] = (postsByClub[clubName] ?? 0) + 1;
    }

    for (final row in _events) {
      final clubName = row['club']?['name']?.toString() ?? 'Unknown';
      eventsByClub[clubName] = (eventsByClub[clubName] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _StatTile(label: 'Total Users', value: _totalUsers),
          _StatTile(label: 'Total Posts', value: _totalPosts),
          _StatTile(label: 'Total Events', value: _totalEvents),
          _StatTile(label: 'Total RSVPs', value: _totalRsvps),
          const SizedBox(height: 12),
          const Text(
            'Posts per Club',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...postsByClub.entries.map((e) => _StatTile(label: e.key, value: e.value)),
          const SizedBox(height: 12),
          const Text(
            'Events per Club',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...eventsByClub.entries.map((e) => _StatTile(label: e.key, value: e.value)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
