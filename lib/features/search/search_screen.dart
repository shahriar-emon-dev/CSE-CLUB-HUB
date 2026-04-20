import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../shared/widgets/main_bottom_nav.dart';

// ==========================================
// GLOBAL CONSTANTS AND CONFIGURATION
// ==========================================

const _debounceDuration = Duration(milliseconds: 300);

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _isSearching = false;
  String _query = '';

  List<Map<String, dynamic>> _postResults = const [];
  List<Map<String, dynamic>> _eventResults = const [];
  List<Map<String, dynamic>> _clubResults = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _query = '';
        _postResults = const [];
        _eventResults = const [];
        _clubResults = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _query = query;
    });

    final pattern = '%$query%';

    try {
      final postFuture = _client
          .from('posts')
          .select('id, title, content, created_at, club:clubs(name)')
          .eq('is_deleted', false)
          .or('title.ilike.$pattern,content.ilike.$pattern')
          .order('created_at', ascending: false)
          .limit(20);

      final eventFuture = _client
          .from('events')
          .select('id, title, event_datetime, venue, club:clubs(name)')
          .eq('is_cancelled', false)
          .ilike('title', pattern)
          .order('event_datetime', ascending: true)
          .limit(20);

      final clubFuture = _client
          .from('clubs')
          .select('id, name, description, is_active')
          .eq('is_active', true)
          .ilike('name', pattern)
          .order('name', ascending: true)
          .limit(20);

      final results = await Future.wait([postFuture, eventFuture, clubFuture]);

      if (!mounted) return;

      setState(() {
        _postResults = (results[0] as List).cast<Map<String, dynamic>>();
        _eventResults = (results[1] as List).cast<Map<String, dynamic>>();
        _clubResults = (results[2] as List).cast<Map<String, dynamic>>();
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _postResults = const [];
        _eventResults = const [];
        _clubResults = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _postResults.isNotEmpty || _eventResults.isNotEmpty || _clubResults.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onQueryChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search posts, events, clubs',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_query.isEmpty)
                    const _EmptyStateText(
                      title: 'Start searching',
                      subtitle: 'Type at least one character to search posts, events, and clubs.',
                    )
                  else if (!hasResults)
                    const _EmptyStateText(
                      title: 'No results found',
                      subtitle: 'Try different keywords for posts, events, or clubs.',
                    )
                  else ...[
                    _SearchGroup(
                      title: 'Posts',
                      count: _postResults.length,
                      children: _postResults
                          .map(
                            (row) => _ResultTile(
                              title: (row['title']?.toString().trim().isNotEmpty ?? false)
                                  ? row['title'].toString()
                                  : (row['club']?['name']?.toString() ?? 'Post'),
                              subtitle: row['content']?.toString() ?? '',
                              trailing: _formatDate(row['created_at']?.toString()),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _SearchGroup(
                      title: 'Events',
                      count: _eventResults.length,
                      children: _eventResults
                          .map(
                            (row) => _ResultTile(
                              title: row['title']?.toString() ?? 'Event',
                              subtitle:
                                  '${row['club']?['name']?.toString() ?? 'Club'} • ${row['venue']?.toString() ?? 'Venue TBA'}',
                              trailing: _formatDateTime(row['event_datetime']?.toString()),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _SearchGroup(
                      title: 'Clubs',
                      count: _clubResults.length,
                      children: _clubResults
                          .map(
                            (row) => _ResultTile(
                              title: row['name']?.toString() ?? 'Club',
                              subtitle: row['description']?.toString() ?? '',
                              trailing: 'Active',
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(activeRoute: AppRoutes.search),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}

class _SearchGroup extends StatelessWidget {
  const _SearchGroup({
    required this.title,
    required this.count,
    required this.children,
  });

  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (children.isEmpty)
            const Text(
              'No matches',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          trailing,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
