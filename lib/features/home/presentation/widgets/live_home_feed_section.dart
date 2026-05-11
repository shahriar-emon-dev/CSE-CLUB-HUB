import 'package:flutter/material.dart';

import '../../../feed/data/feed_repository.dart';
import '../../../../core/constants/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Feed Header with Tabs ──
        Row(
          children: [
            Text(
              'Feed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            _FeedTabChip(
              label: 'Global',
              isActive: _selectedMode == _FeedMode.global,
              onTap: () => _switchMode(_FeedMode.global),
            ),
            const SizedBox(width: 6),
            _FeedTabChip(
              label: 'For You',
              isActive: _selectedMode == _FeedMode.personalized,
              isDisabled: !_hasFollowedClubs,
              onTap: _hasFollowedClubs
                  ? () => _switchMode(_FeedMode.personalized)
                  : null,
            ),
          ],
        ),
        if (!_hasFollowedClubs) ...[
          const SizedBox(height: 6),
          Text(
            'Follow clubs to enable personalized feed.',
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _FeedMessage(
            icon: Icons.error_outline,
            title: 'Unable to load feed',
            message: _error!,
          )
        else if (_feedRows.isEmpty)
          _FeedMessage(
            icon: _selectedMode == _FeedMode.personalized
                ? Icons.person_search_outlined
                : Icons.article_outlined,
            title: _selectedMode == _FeedMode.personalized
                ? 'No personalized posts yet'
                : 'No posts yet',
            message: _selectedMode == _FeedMode.personalized
                ? 'Follow more clubs or switch to global feed.'
                : 'Posts will appear once clubs publish updates.',
          )
        else
          ..._feedRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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

// ── Compact Feed Tab Chip ──
class _FeedTabChip extends StatelessWidget {
  const _FeedTabChip({
    required this.label,
    required this.isActive,
    this.isDisabled = false,
    this.onTap,
  });
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = AppColors.cta.withValues(alpha: 0.12);
    final inactiveBg = isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF0F2F5);

    return Material(
      color: isActive ? activeBg : inactiveBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isDisabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDisabled
                  ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                      .withValues(alpha: 0.5)
                  : isActive
                      ? AppColors.cta
                      : isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error State for Feed ──
class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 36,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
