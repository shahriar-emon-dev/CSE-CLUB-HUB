import 'package:flutter/material.dart';

import '../../../feed/data/feed_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import 'post_card.dart';

// ==========================================
// LIVE HOME FEED SECTION
// ==========================================

enum _FeedMode {
  global('global'),
  personalized('personalized');

  const _FeedMode(this.value);
  final String value;
}

class LiveHomeFeedSection extends StatefulWidget {
  const LiveHomeFeedSection({super.key});

  @override
  State<LiveHomeFeedSection> createState() => _LiveHomeFeedSectionState();
}

class _LiveHomeFeedSectionState extends State<LiveHomeFeedSection> {
  final FeedRepository _feedRepository = FeedRepository();

  _FeedMode _selectedMode = _FeedMode.global;
  bool _hasFollowedClubs = false;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _feedRows = const [];

  @override
  void initState() {
    super.initState();
    _initializeFeed();
  }

  Future<void> _initializeFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final followCount = await _feedRepository.getFollowedClubCount();
      final effectiveMode = await _feedRepository.getEffectiveFeedMode();
      final mode = effectiveMode == _FeedMode.personalized.value && followCount > 0
          ? _FeedMode.personalized
          : _FeedMode.global;

      final feed = await _feedRepository.getHomeFeed(mode: mode.value);

      if (!mounted) return;

      setState(() {
        _hasFollowedClubs = followCount > 0;
        _selectedMode = mode;
        _feedRows = feed;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _switchMode(_FeedMode mode) async {
    if (!_hasFollowedClubs && mode == _FeedMode.personalized) return;

    setState(() {
      _selectedMode = mode;
      _isLoading = true;
      _error = null;
    });

    try {
      await _feedRepository.setFeedPreference(mode.value);
      final feed = await _feedRepository.getHomeFeed(mode: mode.value);

      if (!mounted) return;

      setState(() {
        _feedRows = feed;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Live Feed',
          subtitle: 'Global is default until you follow clubs, then you can switch to personalized.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Global'),
              selected: _selectedMode == _FeedMode.global,
              onSelected: (_) => _switchMode(_FeedMode.global),
              selectedColor: AppColors.cta.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: _selectedMode == _FeedMode.global ? AppColors.cta : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            ChoiceChip(
              label: const Text('Personalized'),
              selected: _selectedMode == _FeedMode.personalized,
              onSelected: _hasFollowedClubs ? (_) => _switchMode(_FeedMode.personalized) : null,
              selectedColor: AppColors.cta.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: _selectedMode == _FeedMode.personalized ? AppColors.cta : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (!_hasFollowedClubs) ...[
          const SizedBox(height: 8),
          const Text(
            'Follow at least one club to enable personalized feed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          EmptyState(
            title: 'Unable to load feed',
            message: _error!,
          )
        else if (_feedRows.isEmpty)
          EmptyState(
            title: _selectedMode == _FeedMode.personalized
                ? 'No personalized posts yet'
                : 'No posts yet',
            message: _selectedMode == _FeedMode.personalized
                ? 'Follow more clubs or switch to global feed to see department updates.'
                : 'Posts will appear here once clubs publish updates.',
          )
        else
          ..._feedRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                clubName: (row['club']?['name']?.toString() ?? 'Club'),
                authorName: (row['author']?['name']?.toString() ?? 'Unknown'),
                authorRole: (row['author']?['role']?.toString() ?? 'student'),
                authorAvatarUrl: row['author']?['avatar_url']?.toString(),
                content: row['content']?.toString() ?? '',
                timestamp: _formatTimestamp(row['created_at']?.toString()),
                likeCount: ((row['reactions_count']?['like']) as num?)?.toInt() ?? 0,
                fireCount: ((row['reactions_count']?['fire']) as num?)?.toInt() ?? 0,
                applauseCount: ((row['reactions_count']?['clap']) as num?)?.toInt() ?? 0,
                commentCount: (row['comment_count'] as num?)?.toInt() ?? 0,
                imageUrls: (row['media'] as List<dynamic>? ?? const [])
                    .map((item) => item.toString())
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return 'just now';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'just now';

    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
