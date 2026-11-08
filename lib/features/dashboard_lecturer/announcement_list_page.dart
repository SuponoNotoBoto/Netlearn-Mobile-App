import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/status_badge.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../classes/lecturer_manage_class_section.dart';
import 'announcement_controller.dart';
import 'lecturer_bottom_navbar.dart';

class LecturerAnnouncementListPage extends ConsumerStatefulWidget {
  const LecturerAnnouncementListPage({super.key});

  @override
  ConsumerState<LecturerAnnouncementListPage> createState() =>
      _LecturerAnnouncementListPageState();
}

class _LecturerAnnouncementListPageState
    extends ConsumerState<LecturerAnnouncementListPage> {
  final _searchController = TextEditingController();

  Future<void> _refresh() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      ref.invalidate(lecturerAnnouncementsProvider(user.id));
      await ref.read(lecturerAnnouncementsProvider(user.id).future);
    }
  }

  String _writeFailureMessage(Object error, AppLocalizations l10n) {
    if (error is! AnnouncementWriteException) {
      return l10n.announcementSaveFailed;
    }

    switch (error.failure) {
      case AnnouncementWriteFailure.notPermitted:
        return l10n.notPermittedError;
      case AnnouncementWriteFailure.titleTooLong:
        return 'Title is too long';
      case AnnouncementWriteFailure.contentTooLong:
        return 'Content is too long';
      case AnnouncementWriteFailure.unknown:
        return l10n.announcementSaveFailed;
    }
  }

  Future<void> _togglePublished(AnnouncementModel announcement) async {
    final l10n = AppLocalizations.of(context)!;
    final next = !announcement.published;

    try {
      await setAnnouncementPublished(ref, announcement, next);

      if (!mounted) return;

      NlSnackBar.show(
        context,
        next ? l10n.announcementPublishedSuccess : l10n.announcementUnpublished,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        _writeFailureMessage(error, l10n),
        tone: NlSnackTone.error,
      );
    }
  }

  Future<void> _confirmDelete(AnnouncementModel announcement) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteAnnouncement),
          content: Text(l10n.deleteAnnouncementConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: NetLearnColors.danger,
              ),
              child: Text(l10n.deleteAnnouncement),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await deleteAnnouncement(ref, announcement);

      if (!mounted) return;

      NlSnackBar.show(
        context,
        l10n.announcementDeleted,
        tone: NlSnackTone.success,
      );
    } catch (error) {
      if (!mounted) return;

      NlSnackBar.show(
        context,
        _writeFailureMessage(error, l10n),
        tone: NlSnackTone.error,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AnnouncementModel> _filter(List<AnnouncementModel> announcements) {
    final search = _searchController.text.trim().toLowerCase();

    return announcements.where((announcement) {
      if (search.isEmpty) return true;
      return announcement.title.toLowerCase().contains(search) ||
          announcement.displayContent.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = supabase.auth.currentUser;

    final announcementsAsync = user != null
        ? ref.watch(lecturerAnnouncementsProvider(user.id))
        : const AsyncValue.data([]);
    final activeClass = ref.watch(activeLecturerClassProvider).value;
    final classes = ref.watch(lecturerClassesProvider).value;

    return Scaffold(
      backgroundColor: context.background,

      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.manageAnnouncements,
          style: theme.textTheme.titleLarge,
        ),
        // No `+` in the app bar: the "Create Announcement" button in the body is
        // the single entry point into the form, mirroring the design (`64:2`).
      ),

      body: Column(
        children: [
          if (classes != null &&
              activeClass != null &&
              activeClass.id != kLegacyFallbackClassId) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                0,
              ),
              child: LecturerActiveClassBar(
                classes: classes,
                activeClass: activeClass,
              ),
            ),
          ],
          Expanded(
            child: announcementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 46, color: NetLearnColors.danger),
                      const SizedBox(height: 12),
                      Text(l10n.failedToLoad, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (announcements) {
                final announcementsTyped = announcements.cast<AnnouncementModel>();
                final visible = _filter(announcementsTyped);
                final publishedCount =
                    announcementsTyped.where((item) => item.published).length;
                final draftCount = announcementsTyped.length - publishedCount;

                return RefreshIndicator(
                  color: context.accent,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      20 + 80,
                    ),
                    children: [
                // The design (frame `64:2`) opens with a one-line subtitle, the
                // Create Announcement action and three counts, then the list.
                // The counts are derived from the rows the lecturer can read,
                // so an empty table really does show 0 / 0 / 0.
                Text(
                  l10n.manageAnnouncementsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/lecturer/announcements/create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.createAnnouncement),
                  ),
                ),

                const SizedBox(height: 16),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${announcementsTyped.length}',
                          label: l10n.totalAnnouncements,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '$publishedCount',
                          label: l10n.published,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '$draftCount',
                          label: l10n.drafts,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.searchMaterials,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 20),
                          ),
                    filled: true,
                    fillColor: context.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.accent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Announcement List
                if (visible.isEmpty)
                  NlEmptyState(
                    icon: Icons.campaign_outlined,
                    title: l10n.noAnnouncements,
                    message: l10n.noAnnouncementsLecturerMessage,
                  )
                else
                  for (final announcement in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AnnouncementCard(
                        announcement: announcement,
                        onEdit: () {
                          context.push(
                            '/lecturer/announcements/${announcement.id}/edit',
                          );
                        },
                        onTogglePublished: () {
                          _togglePublished(announcement);
                        },
                        onDelete: () {
                          _confirmDelete(announcement);
                        },
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

      bottomNavigationBar: const LecturerBottomNavbar(
        currentIndex: 0,
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.accentTint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.campaign_rounded,
                  color: context.accent,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.displayContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              StatusBadge(
                status: announcement.published
                    ? NetLearnStatus.linked
                    : NetLearnStatus.active,
                label: announcement.published
                    ? l10n.announcementPublished
                    : l10n.announcementDraft,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Meta: Recipient scope, Created date
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.people_outline_rounded,
                label: l10n.allStudents,
              ),
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: _formatDate(announcement.createdAt),
              ),
              if (announcement.published && announcement.publishedAt != null)
                _MetaChip(
                  icon: Icons.publish_rounded,
                  label: _formatDate(announcement.publishedAt!),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.edit),
              ),
              FilledButton.icon(
                onPressed: onTogglePublished,
                icon: Icon(
                  announcement.published
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(
                  announcement.published
                      ? l10n.unpublish
                      : l10n.publishAnnouncement,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.delete),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NetLearnColors.danger,
                  side: BorderSide(color: NetLearnColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// One of the three counts the design (frame `64:2`) puts under the Create
/// Announcement action: total, published and drafts.
///
/// Every value is counted from the rows the lecturer can read, so an empty table
/// shows 0 / 0 / 0 rather than a placeholder figure.
class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.mutedText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.mutedText,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}