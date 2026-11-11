import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../profile/public_profile_sheet.dart';
import 'discussion_controller.dart';
import 'discussion_models.dart';

class ClassDiscussionPage extends ConsumerStatefulWidget {
  final String? classId;
  final int? initialModuleNumber;
  final String? initialMaterialId;
  final bool isLecturer;

  const ClassDiscussionPage({
    super.key,
    this.classId,
    this.initialModuleNumber,
    this.initialMaterialId,
    this.isLecturer = false,
  });

  @override
  ConsumerState<ClassDiscussionPage> createState() =>
      _ClassDiscussionPageState();
}

class _ClassDiscussionPageState extends ConsumerState<ClassDiscussionPage> {
  /// `-1` = All Topics, `0` = General Class Discussion (`moduleNumber == null`),
  /// `1..4` = Specific Module.
  late int _selectedFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialModuleNumber ?? -1;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _resolveClassId() {
    if (widget.classId != null &&
        widget.classId!.isNotEmpty &&
        widget.classId != kLegacyFallbackClassId) {
      return widget.classId;
    }
    if (widget.isLecturer) {
      final cls = ref.watch(activeLecturerClassProvider).value;
      if (cls != null &&
          cls.id.isNotEmpty &&
          cls.id != kLegacyFallbackClassId) {
        return cls.id;
      }
      return null;
    }
    final cls = ref.watch(activeStudentClassProvider).value;
    if (cls != null && cls.id.isNotEmpty && cls.id != kLegacyFallbackClassId) {
      return cls.id;
    }
    return null;
  }

  void _openCreateThreadSheet(BuildContext context, String resolvedClassId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateDiscussionThreadSheet(
        parentRef: ref,
        classId: resolvedClassId,
        initialModuleNumber: _selectedFilter > 0
            ? _selectedFilter
            : widget.initialModuleNumber,
        initialMaterialId: widget.initialMaterialId,
      ),
    );
  }

  void _openThread(BuildContext context, DiscussionThread thread) {
    final base = widget.isLecturer ? '/lecturer' : '/student';
    try {
      context.push('$base/discussions/${thread.id}');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedClassId = _resolveClassId();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isId ? 'Forum Tanya-Jawab Kelas' : 'Class Q&A Forum',
        ),
      ),
      floatingActionButton: resolvedClassId == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('discussion_create_fab'),
              onPressed: () =>
                  _openCreateThreadSheet(context, resolvedClassId),
              backgroundColor: const Color(0xFF6C2CE2),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: Text(
                isId ? 'Buat Diskusi' : 'Ask Question',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
      body: SafeArea(
        child: resolvedClassId == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: Text(
                    isId
                        ? 'Bergabung atau pilih kelas aktif terlebih dahulu untuk membuka forum diskusi.'
                        : 'Join or select an active class first to access the Q&A forum.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(context),
                  ),
                ),
              )
            : _buildForumBody(context, resolvedClassId, isId, isDark),
      ),
    );
  }

  Widget _buildForumBody(
    BuildContext context,
    String resolvedClassId,
    bool isId,
    bool isDark,
  ) {
    final queryModule = _selectedFilter > 0 ? _selectedFilter : null;
    final threadsAsync = ref.watch(
      classDiscussionThreadsProvider(
        (classId: resolvedClassId, moduleNumber: queryModule),
      ),
    );

    final filterItems = <({int value, String label})>[
      (value: -1, label: isId ? 'Semua Topik' : 'All Topics'),
      (value: 0, label: isId ? 'Diskusi Umum' : 'General'),
      (value: 1, label: 'Modul 1'),
      (value: 2, label: 'Modul 2'),
      (value: 3, label: 'Modul 3'),
      (value: 4, label: 'Modul 4'),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        invalidateDiscussions(ref);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
        children: [
          // Search Input
          TextField(
            key: const Key('discussion_search_input'),
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: isId
                  ? 'Cari pertanyaan atau topik materi...'
                  : 'Search questions or module topics...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor:
                  isDark ? NetLearnColors.darkSurface : const Color(0xFFF6F4FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color:
                      isDark ? NetLearnColors.darkLine : const Color(0xFFE7E2F3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color:
                      isDark ? NetLearnColors.darkLine : const Color(0xFFE7E2F3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Module Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in filterItems) ...[
                  ChoiceChip(
                    key: Key('discussion_filter_chip_${f.value}'),
                    label: Text(f.label),
                    selected: _selectedFilter == f.value,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = f.value),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          threadsAsync.when(
            loading: () => const NlSkeletonList(
              itemCount: 3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            error: (_, _) => NlSurfaceCard(
              child: Text(
                isId
                    ? 'Gagal memuat daftar diskusi. Tarik ke bawah untuk menyegarkan.'
                    : 'Could not load discussions. Pull down to refresh.',
                style: AppTypography.body(context),
              ),
            ),
            data: (rawThreads) {
              var filtered = rawThreads;
              if (_selectedFilter == 0) {
                filtered = filtered
                    .where((t) => t.moduleNumber == null)
                    .toList(growable: false);
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filtered = filtered
                    .where((t) =>
                        t.title.toLowerCase().contains(q) ||
                        t.body.toLowerCase().contains(q) ||
                        t.authorName.toLowerCase().contains(q))
                    .toList(growable: false);
              }

              if (filtered.isEmpty) {
                return NlSurfaceCard(
                  key: const Key('discussion_empty_card'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6C2CE2).withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_outlined,
                            size: 36,
                            color: Color(0xFF6C2CE2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isId
                              ? 'Belum ada diskusi di topik ini'
                              : 'No discussions in this topic yet',
                          textAlign: TextAlign.center,
                          style: AppTypography.cardTitle(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isId
                              ? 'Jadilah yang pertama bertanya atau berbagi pemahaman tentang materi jaringan!'
                              : 'Be the first to ask a question or share networking insights!',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final thread in filtered) ...[
                    _DiscussionThreadCard(
                      thread: thread,
                      isId: isId,
                      onTap: () => _openThread(context, thread),
                      onUpvote: () => toggleDiscussionUpvoteAction(
                        ref,
                        threadId: thread.id,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiscussionThreadCard extends StatelessWidget {
  final DiscussionThread thread;
  final bool isId;
  final VoidCallback onTap;
  final VoidCallback onUpvote;

  const _DiscussionThreadCard({
    required this.thread,
    required this.isId,
    required this.onTap,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    final moduleLabel = thread.moduleNumber != null
        ? 'Modul ${thread.moduleNumber}'
        : (isId ? 'Umum' : 'General');

    return NlSurfaceCard(
      key: Key('discussion_thread_card_${thread.id}'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status & Module Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  moduleLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6C2CE2),
                  ),
                ),
              ),
              if (thread.isPinned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 11,
                        color: Color(0xFFF57C00),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isId ? 'Dipin' : 'Pinned',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                    ],
                  ),
                ),
              if (thread.isResolved)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isId ? 'Terjawab' : 'Resolved',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                formatRelativeDiscussionTime(thread.createdAt, isId: isId),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF9A96A8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            thread.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle(context).copyWith(fontSize: 15),
          ),

          const SizedBox(height: 5),

          Text(
            thread.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(context).copyWith(fontSize: 12.5),
          ),

          const SizedBox(height: 12),

          // Author Avatar + Meta Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => showPublicProfileSheet(
                    context,
                    userId: thread.authorId,
                    classId: thread.classId,
                    fallbackName: thread.authorName,
                    fallbackAvatar: thread.effectiveAvatar,
                    fallbackRole: thread.authorRole,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NlAvatarWidget(
                        config: thread.effectiveAvatar,
                        size: 28,
                        borderWidth: 1.5,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              thread.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (thread.isAuthorLecturer)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isId ? 'DOSEN' : 'LECTURER',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onUpvote,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        thread.upvotedByMe
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_off_alt_rounded,
                        size: 14,
                        color: thread.upvotedByMe
                            ? const Color(0xFF6C2CE2)
                            : const Color(0xFF7E7B8F),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${thread.upvoteCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: thread.upvotedByMe
                              ? const Color(0xFF6C2CE2)
                              : const Color(0xFF7E7B8F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 13.5,
                    color: Color(0xFF7E7B8F),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${thread.replyCount}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E7B8F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateDiscussionThreadSheet extends StatefulWidget {
  final WidgetRef parentRef;
  final String classId;
  final int? initialModuleNumber;
  final String? initialMaterialId;

  const _CreateDiscussionThreadSheet({
    required this.parentRef,
    required this.classId,
    this.initialModuleNumber,
    this.initialMaterialId,
  });

  @override
  State<_CreateDiscussionThreadSheet> createState() =>
      _CreateDiscussionThreadSheetState();
}

class _CreateDiscussionThreadSheetState
    extends State<_CreateDiscussionThreadSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  int? _selectedModule;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModuleNumber;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.length < 3 || body.length < 3) {
      NlSnackBar.show(
        context,
        isId
            ? 'Judul dan isi pertanyaan minimal 3 karakter.'
            : 'Title and question body must be at least 3 characters.',
        tone: NlSnackTone.error,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await createDiscussionThreadAction(
        widget.parentRef,
        classId: widget.classId,
        moduleNumber: _selectedModule,
        materialId: widget.initialMaterialId,
        title: title,
        body: body,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      NlSnackBar.show(
        context,
        isId
            ? 'Pertanyaan diskusi berhasil dipublikasikan!'
            : 'Discussion thread posted!',
        tone: NlSnackTone.success,
      );
    } catch (e) {
      debugPrint('createDiscussionThread failed: $e');
      if (!mounted) return;
      NlSnackBar.show(
        context,
        isId
            ? 'Gagal mengirim diskusi. Silakan coba lagi.'
            : 'Could not post discussion. Please try again.',
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final moduleChoices = <({int? mod, String label})>[
      (mod: null, label: isId ? 'Umum' : 'General'),
      (mod: 1, label: 'Modul 1'),
      (mod: 2, label: 'Modul 2'),
      (mod: 3, label: 'Modul 3'),
      (mod: 4, label: 'Modul 4'),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isId ? 'Buat Diskusi / Pertanyaan Baru' : 'New Q&A Thread',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isId ? 'Kategori Modul' : 'Module Topic',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final item in moduleChoices)
                  ChoiceChip(
                    label: Text(item.label),
                    selected: _selectedModule == item.mod,
                    onSelected: (_) =>
                        setState(() => _selectedModule = item.mod),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('discussion_title_input'),
              controller: _titleController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: isId ? 'Judul Pertanyaan' : 'Question Title',
                hintText: isId
                    ? 'Contoh: Cara menghitung broadcast address /26?'
                    : 'e.g. How to compute the broadcast address for /26?',
                filled: true,
                fillColor:
                    isDark ? NetLearnColors.darkApp : const Color(0xFFF7F5FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('discussion_body_input'),
              controller: _bodyController,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: isId ? 'Detail Pertanyaan / Diskusi' : 'Details',
                hintText: isId
                    ? 'Jelaskan bagian materi atau soal yang ingin didiskusikan...'
                    : 'Explain the concept or problem you want to discuss...',
                filled: true,
                fillColor:
                    isDark ? NetLearnColors.darkApp : const Color(0xFFF7F5FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                key: const Key('discussion_submit_btn'),
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.send_rounded, size: 17),
                label: Text(
                  isId ? 'Publikasikan Diskusi' : 'Post Question',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C2CE2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
