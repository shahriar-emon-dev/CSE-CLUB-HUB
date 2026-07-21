import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/event.dart';
import '../providers/event_participants_provider.dart';

enum _SortField { name, registeredAt }

/// Admin participant roster for a single event: search, status filter,
/// sort, bulk-select, CSV export, and attendance toggling — all driven by
/// live event_rsvps + profiles data via eventParticipantsProvider.
class EventParticipantsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventParticipantsScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  ConsumerState<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends ConsumerState<EventParticipantsScreen> {
  String _searchQuery = '';
  RsvpStatus? _statusFilter;
  final Set<String> _selectedIds = {};
  _SortField _sortField = _SortField.registeredAt;
  bool _sortAscending = false;

  List<EventParticipant> _applyFilters(List<EventParticipant> all) {
    var result = all.where((p) {
      if (_statusFilter != null && p.status != _statusFilter) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.fullName.toLowerCase().contains(q) || (p.studentId ?? '').toLowerCase().contains(q);
    }).toList();

    result.sort((a, b) {
      final cmp = _sortField == _SortField.name
          ? a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())
          : a.registeredAt.compareTo(b.registeredAt);
      return _sortAscending ? cmp : -cmp;
    });
    return result;
  }

  Future<void> _exportCsv(List<EventParticipant> rows) async {
    final buffer = StringBuffer('Name,Student ID,Batch,Semester,Department,Status,Registered At,Attended\n');
    for (final p in rows) {
      buffer.writeln([
        p.fullName,
        p.studentId ?? '',
        p.batch ?? '',
        p.semester ?? '',
        p.department ?? '',
        p.status.value,
        p.registeredAt.toIso8601String(),
        p.attended ? 'Yes' : 'No',
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(','));
    }
    await Share.share(buffer.toString(), subject: '${widget.eventTitle} — Participants');
  }

  Color _statusColor(RsvpStatus status) {
    return switch (status) {
      RsvpStatus.confirmed => AppColors.success,
      RsvpStatus.interested => AppColors.warning,
      RsvpStatus.waitlisted => AppColors.info,
      RsvpStatus.cancelled => AppColors.textTertiaryDark,
    };
  }

  String _statusLabel(RsvpStatus status) {
    return switch (status) {
      RsvpStatus.confirmed => 'Going',
      RsvpStatus.interested => 'Interested',
      RsvpStatus.waitlisted => 'Waitlisted',
      RsvpStatus.cancelled => 'Cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(eventParticipantsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(widget.eventTitle, overflow: TextOverflow.ellipsis),
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text('Failed to load participants: $e', style: const TextStyle(color: AppColors.error))),
        data: (all) {
          final filtered = _applyFilters(all);
          final goingCount = all.where((p) => p.status == RsvpStatus.confirmed).length;
          final interestedCount = all.where((p) => p.status == RsvpStatus.interested).length;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryChip('Total', all.length.toString(), AppColors.primary),
                    _summaryChip('Going', goingCount.toString(), AppColors.success),
                    _summaryChip('Interested', interestedCount.toString(), AppColors.warning),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or student ID...',
                          hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<_SortField>(
                      tooltip: 'Sort by',
                      icon: const Icon(Icons.sort, color: AppColors.textSecondaryDark),
                      onSelected: (field) => setState(() {
                        if (_sortField == field) {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortField = field;
                          _sortAscending = true;
                        }
                      }),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: _SortField.name, child: Text('Sort by Name')),
                        PopupMenuItem(value: _SortField.registeredAt, child: Text('Sort by Registration Time')),
                      ],
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: filtered.isEmpty ? null : () => _exportCsv(_selectedIds.isEmpty ? filtered : filtered.where((p) => _selectedIds.contains(p.rsvpId)).toList()),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: Text(_selectedIds.isEmpty ? 'Export CSV' : 'Export ${_selectedIds.length} Selected'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip('All', null),
                      const SizedBox(width: 8),
                      _filterChip('Going', RsvpStatus.confirmed),
                      const SizedBox(width: 8),
                      _filterChip('Interested', RsvpStatus.interested),
                      const SizedBox(width: 8),
                      _filterChip('Waitlisted', RsvpStatus.waitlisted),
                      const SizedBox(width: 8),
                      _filterChip('Cancelled', RsvpStatus.cancelled),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No participants match your filters.', style: TextStyle(color: AppColors.textSecondaryDark)))
                      : _buildTable(filtered),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Real column-header data table (not a ListTile stack) — horizontally
  /// scrollable so every column stays readable on narrow viewports instead
  /// of squeezing/wrapping.
  Widget _buildTable(List<EventParticipant> rows) {
    final allSelected = rows.isNotEmpty && rows.every((p) => _selectedIds.contains(p.rsvpId));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, 900),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    color: AppColors.surfaceContainerDark,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Checkbox(
                            value: allSelected,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selectedIds.addAll(rows.map((p) => p.rsvpId));
                              } else {
                                _selectedIds.removeAll(rows.map((p) => p.rsvpId));
                              }
                            }),
                          ),
                        ),
                        const Expanded(flex: 3, child: _ColumnHeader('Participant')),
                        const Expanded(flex: 2, child: _ColumnHeader('Student ID')),
                        const Expanded(flex: 3, child: _ColumnHeader('Batch / Semester / Dept')),
                        const Expanded(flex: 2, child: _ColumnHeader('RSVP Status')),
                        const Expanded(flex: 2, child: _ColumnHeader('Registered')),
                        const Expanded(flex: 1, child: _ColumnHeader('Attended')),
                      ],
                    ),
                  ),
                  // Data rows
                  Expanded(
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final p = rows[index];
                        final isSelected = _selectedIds.contains(p.rsvpId);
                        return Container(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : null,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => setState(() => isSelected ? _selectedIds.remove(p.rsvpId) : _selectedIds.add(p.rsvpId)),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                      backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) ? NetworkImage(p.avatarUrl!) : null,
                                      child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                                          ? Text(
                                              p.fullName.trim().isEmpty ? '?' : p.fullName.trim()[0].toUpperCase(),
                                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          if (p.email != null)
                                            Text(p.email!, style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(p.studentId ?? 'N/A', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontFamily: 'monospace')),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${p.batch ?? 'N/A'} · Sem ${p.semester ?? 'N/A'} · ${p.department ?? 'CSE'}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _statusColor(p.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text(_statusLabel(p.status), style: TextStyle(color: _statusColor(p.status), fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(DateFormat('MMM d, h:mm a').format(p.registeredAt), style: const TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Tooltip(
                                  message: p.attended ? 'Mark as not attended' : 'Mark as attended',
                                  child: Checkbox(
                                    value: p.attended,
                                    activeColor: AppColors.success,
                                    onChanged: (v) => ref.read(participantActionProvider.notifier).setAttended(p.rsvpId, widget.eventId, v ?? false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, RsvpStatus? status) {
    final isSelected = _statusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondaryDark, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Small header-cell label used by the participants table's header row.
class _ColumnHeader extends StatelessWidget {
  final String label;
  const _ColumnHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
    );
  }
}
