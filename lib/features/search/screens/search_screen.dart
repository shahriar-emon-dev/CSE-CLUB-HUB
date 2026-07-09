import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_profile.dart';
import '../../../models/event.dart';
import '../../../models/blog.dart';
import '../../../models/club.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../repositories/search_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _isSearching = false;
  bool _isFocused = false;
  
  List<UserProfile> _members = [];
  List<Club> _clubs = [];
  List<Event> _events = [];
  List<Blog> _blogs = [];
  
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Posts', 'Events', 'Clubs', 'Users'];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _members = []; _clubs = []; _events = []; _blogs = []; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final repo = SearchRepository();
      final bundle = await repo.searchPlatform(q, limit: 10);

      setState(() {
        _members = bundle.users;
        _clubs = bundle.clubs;
        _events = bundle.events;
        _blogs = bundle.blogs;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasResults = _query.isNotEmpty && (_members.isNotEmpty || _clubs.isNotEmpty || _events.isNotEmpty || _blogs.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14).withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('ClubHub', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark),
            onPressed: () {},
          ),
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: const Center(child: Text('JD', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.05), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isFocused ? AppColors.primary : Colors.white.withValues(alpha: 0.1)),
                boxShadow: _isFocused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20)] : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Search for clubs, events, or students',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textSecondaryDark), onPressed: () {
                              _ctrl.clear();
                              setState(() { _query = ''; _members = []; _events = []; _blogs = []; });
                            })
                          : Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('⌘K', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontFamily: 'monospace')),
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: (v) {
                      setState(() => _query = v);
                      _search(v);
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_query.isEmpty) ...[
              _buildRecentSearches(),
              const SizedBox(height: 32),
              _buildTrendingClubs(),
            ] else ...[
              _buildFilterTabs(),
              const SizedBox(height: 24),
              if (_isSearching)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)))
              else if (!hasResults)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No results found.', style: TextStyle(color: AppColors.textSecondaryDark))))
              else
                _buildResultsList(),
            ],
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Searches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton(onPressed: () {}, child: const Text('Clear All', style: TextStyle(color: AppColors.primary))),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['CSE', 'Algorithms', 'Hackathon'].map((s) => InkWell(
            onTap: () {
              _ctrl.text = s;
              setState(() => _query = s);
              _search(s);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Text(s, style: const TextStyle(color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTrendingClubs() {
    final clubsAsync = ref.watch(clubsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trending Clubs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        clubsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, _) => const Text('Failed to load trending clubs', style: TextStyle(color: Colors.red)),
          data: (clubs) {
            if (clubs.isEmpty) {
              return const Text('No clubs available', style: TextStyle(color: AppColors.textSecondaryDark));
            }
            final trendingClubs = clubs.take(3).toList();
            return Column(
              children: trendingClubs.map((club) {
                Color color = AppColors.primary;
                if (club.colorHex != null) {
                  try {
                    final hexCode = club.colorHex!.replaceAll('#', '');
                    color = Color(int.parse('FF$hexCode', radix: 16));
                  } catch (_) {}
                }
                
                IconData icon = Icons.group;
                if (club.iconName == 'psychology') { icon = Icons.psychology; }
                else if (club.iconName == 'terminal') { icon = Icons.terminal; }
                else if (club.iconName == 'memory') { icon = Icons.memory; }
                else if (club.iconName == 'brush') { icon = Icons.brush; }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTrendingClubCard(
                    title: club.name,
                    members: club.memberCount.toString(),
                    tag: club.categories.isNotEmpty ? club.categories.first : 'Club',
                    icon: icon,
                    color: color,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingClubCard({
    required String title,
    required String members,
    required String tag,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(8),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      if (tag == 'Hot') ...[
                        Icon(Icons.trending_up, color: color, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(tag, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.groups, size: 14, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 4),
                          Text('$members members', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: color, width: 1.5),
                  ),
                ),
                onPressed: () {},
                child: const Text('View Club', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.asMap().entries.map((e) {
          final isSelected = e.key == _selectedFilterIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = e.key),
            child: Container(
              padding: const EdgeInsets.only(bottom: 16, right: 24),
              child: Column(
                children: [
                  Text(
                    e.value,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 12.0),
                      height: 3, width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, -2))],
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        // Event Row
        if (_events.isNotEmpty && (_selectedFilterIndex == 0 || _selectedFilterIndex == 2))
          ..._events.map((e) => _buildEventCard(e)),
          
        // Club Row
        if (_clubs.isNotEmpty && (_selectedFilterIndex == 0 || _selectedFilterIndex == 3))
          ..._clubs.map((c) => _buildClubCard(c)),
          
        // User Row
        if (_members.isNotEmpty && (_selectedFilterIndex == 0 || _selectedFilterIndex == 4))
          ..._members.map((m) => _buildUserCard(m)),
          
        // Post Row
        if (_blogs.isNotEmpty && (_selectedFilterIndex == 0 || _selectedFilterIndex == 1))
          ..._blogs.map((b) => _buildPostCard(b)),
      ],
    );
  }

  Widget _buildClubCard(Club c) {
    return GestureDetector(
      onTap: () => context.push('/clubs/${c.slug.isNotEmpty ? c.slug : c.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.surfaceContainerHighDark, borderRadius: BorderRadius.circular(12)),
              child: c.logoUrl != null && c.logoUrl!.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: c.logoUrl!, fit: BoxFit.cover))
                  : const Icon(Icons.group, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${c.category} • ${c.followersCount} followers', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event e) {
    return GestureDetector(
      onTap: () => context.push('/events/${e.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: e.coverImageUrl != null && e.coverImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: e.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(Icons.event, color: AppColors.textSecondaryDark, size: 32),
                        errorWidget: (context, url, error) => const Icon(Icons.event, color: AppColors.textSecondaryDark, size: 32),
                      ),
                    )
                  : const Icon(Icons.event, color: AppColors.textSecondaryDark, size: 32),
            ),
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('EVENT', style: TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(DateFormat('MMM d, yyyy h:mm a').format(e.eventDate.toLocal()), style: const TextStyle(color: AppColors.primary, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 4),
                    Expanded(child: Text(e.venue ?? 'TBD', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildUserCard(UserProfile m) {
    return GestureDetector(
      onTap: () => context.push('/members/${m.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHighDark),
                  child: const Icon(Icons.person, color: AppColors.textSecondaryDark),
                ),
                if (m.isAdmin)
                  Positioned(
                    bottom: -2, right: -2,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF13131F), width: 2)),
                      child: const Icon(Icons.verified, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(m.role.displayName, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${m.studentId} • Batch ${m.batch}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textSecondaryDark),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Blog b) {
    return GestureDetector(
      onTap: () => context.push('/blogs/${b.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                      child: const Icon(Icons.campaign, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Text('Posted in ', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    Text(b.category.displayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(DateFormat('MMM d, yyyy').format(b.createdAt.toLocal()), style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(b.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.textSecondaryDark),
                const SizedBox(width: 4),
                const Text('0', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined, size: 16, color: AppColors.textSecondaryDark),
                const SizedBox(width: 4),
                const Text('0', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
