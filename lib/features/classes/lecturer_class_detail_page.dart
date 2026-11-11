import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/localization/language_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../../shared/widgets/nl_walkthrough_overlay.dart';
import '../dashboard_lecturer/lecturer_bottom_navbar.dart';
import '../profile/public_profile_sheet.dart';
import 'class_action_messages.dart';
import 'class_controller.dart';
import 'class_models.dart';

class LecturerClassDetailPage extends ConsumerStatefulWidget {
  const LecturerClassDetailPage({
    super.key,
    required this.classId,
    this.startWalkthrough = false,
  });

  final String classId;
  final bool startWalkthrough;

  @override
  ConsumerState<LecturerClassDetailPage> createState() =>
      _LecturerClassDetailPageState();
}

class _LecturerClassDetailPageState
    extends ConsumerState<LecturerClassDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _statusBadgeKey = GlobalKey();
  final _modulesHeaderKey = GlobalKey();
  final _settingsCardKey = GlobalKey();
  final _inviteCardKey = GlobalKey();
  OverlayEntry? _walkthroughEntry;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Pre-warm tab providers so switching tabs during walkthrough mounts immediately.
    ref.read(classModulesProvider(widget.classId));
    ref.read(classSettingsProvider(widget.classId));
    ref.read(classInviteProvider(widget.classId));
    if (widget.startWalkthrough) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleWalkthroughAfterRouteTransition();
      });
    }
  }

  void _scheduleWalkthroughAfterRouteTransition() {
    if (!mounted) return;
    final routeAnim = ModalRoute.of(context)?.animation;
    if (routeAnim == null || routeAnim.isCompleted) {
      _startWalkthrough();
      return;
    }

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        routeAnim.removeStatusListener(listener);
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startWalkthrough();
        });
      }
    }

    routeAnim.addStatusListener(listener);
  }

  @override
  void dispose() {
    _removeWalkthroughOverlay();
    _tabController.dispose();
    super.dispose();
  }

  void _removeWalkthroughOverlay() {
    _walkthroughEntry?.remove();
    _walkthroughEntry = null;
  }

  void _startWalkthrough() {
    if (!mounted) return;
    _removeWalkthroughOverlay();

    final isId = Localizations.localeOf(context).languageCode == 'id';
    final steps = [
      NlWalkthroughStep(
        targetKey: _statusBadgeKey,
        tabIndex: 0,
        icon: Icons.edit_note_rounded,
        accentColor: AppColors.warningAmber,
        highlightPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        highlightRadius: 999,
        title: isId
            ? 'Status Kelas Masih Draf'
            : 'Class Status is Still Draft',
        description: isId
            ? 'Kelas kustom Anda baru dibuat dan saat ini masih berstatus Draf (belum dipublikasikan), sehingga siswa belum dapat bergabung ke kelas ini.'
            : 'Your custom class was just created and is currently in Draft status (not published yet), so students cannot join it yet.',
        onPrepare: () async {
          if (_tabController.index != 0) {
            _tabController.animateTo(0);
          }
        },
      ),
      NlWalkthroughStep(
        targetKey: _modulesHeaderKey,
        tabIndex: 0,
        icon: Icons.library_add_rounded,
        accentColor: AppColors.primaryBlue,
        highlightPadding: const EdgeInsets.all(8),
        highlightRadius: 14,
        title: isId
            ? 'Isi Minimal 1 Modul & 1 Materi'
            : 'Add at Least 1 Module & 1 Material',
        description: isId
            ? 'Sebelum dapat memublikasikan kelas, isi minimal 1 modul dan 1 materi terlebih dahulu lewat tombol "+ Tambah Modul" lalu tambahkan materi di dalamnya. Setelah siap, baru kelas bisa dipublikasikan.'
            : 'Before you can publish this class, add at least 1 module via "+ Add Module" and add at least 1 material inside it first. Once ready, you can publish the class.',
        onPrepare: () async {
          if (_tabController.index != 0) {
            _tabController.animateTo(0);
          }
        },
      ),
      NlWalkthroughStep(
        targetKey: _settingsCardKey,
        tabIndex: 1,
        icon: Icons.tune_rounded,
        accentColor: const Color(0xFF6C2CE2),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 16,
        title: isId
            ? 'Atur Kelas di Settings & Gates'
            : 'Configure Class in Settings & Gates',
        description: isId
            ? 'Di tab Pengaturan & Gerbang ini Anda dapat mengatur Pretest, Posttest, dan Leaderboard kelas, mengubah info kelas, serta mempublikasikan kelas.'
            : 'In this Settings & Gates tab you can configure Pretest, Posttest, and Leaderboard rules, edit class details, and publish the class.',
        onPrepare: () async {
          if (_tabController.index != 1) {
            _tabController.animateTo(1);
          }
        },
      ),
      NlWalkthroughStep(
        targetKey: _inviteCardKey,
        tabIndex: 2,
        icon: Icons.vpn_key_rounded,
        accentColor: const Color(0xFF00897B),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 16,
        title: isId
            ? 'Kode Kelas untuk Siswa'
            : 'Class Code for Students',
        description: isId
            ? 'Di tab Invite & Roster ini terdapat kode kelas Anda. Salin dan bagikan kode tersebut — kode inilah yang harus dimasukkan oleh siswa untuk bergabung ke kelas.'
            : 'In this Invite & Roster tab you can find your class invite code. Share this code with students — they must enter it to join your class.',
        onPrepare: () async {
          if (_tabController.index != 2) {
            _tabController.animateTo(2);
          }
        },
      ),
    ];

    final overlay = Overlay.of(context, rootOverlay: true);
    _walkthroughEntry = OverlayEntry(
      builder: (_) => NlWalkthroughOverlay(
        steps: steps,
        isIndonesian: isId,
        onFinish: ({required bool completed}) {
          _removeWalkthroughOverlay();
          if (completed && mounted && _tabController.index != 0) {
            _tabController.animateTo(0);
          }
        },
      ),
    );
    overlay.insert(_walkthroughEntry!);
  }

  LecturerClass? _findClass(
    List<LecturerClass>? activeList,
    List<LecturerClass>? archivedList,
  ) {
    if (activeList != null) {
      for (final c in activeList) {
        if (c.id == widget.classId) return c;
      }
    }
    if (archivedList != null) {
      for (final c in archivedList) {
        if (c.id == widget.classId) return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final classesAsync = ref.watch(lecturerClassesProvider);
    final archivedAsync = ref.watch(lecturerArchivedClassesProvider);
    final inviteAsync = ref.watch(classInviteProvider(widget.classId));

    final cls = _findClass(classesAsync.value, archivedAsync.value);
    final inviteCode = inviteAsync.value?.code ?? cls?.code;

    return Scaffold(
      appBar: AppBar(
        title: Text(cls?.name ?? l10n.manageClassesTitle),
        actions: [
          IconButton(
            key: const Key('class_detail_walkthrough_btn'),
            tooltip: isId ? 'Panduan Kelas' : 'Class Guide',
            onPressed: _startWalkthrough,
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          tabs: [
            Tab(text: l10n.classTabModules),
            Tab(text: l10n.classTabSettings),
            Tab(text: l10n.classTabInviteRoster),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ClassStatusHeaderBanner(
              classId: widget.classId,
              cls: cls,
              inviteCode: inviteCode,
              statusBadgeKey: _statusBadgeKey,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ModulesTab(
                    classId: widget.classId,
                    headerKey: _modulesHeaderKey,
                  ),
                  _SettingsGatesTab(
                    classId: widget.classId,
                    cls: cls,
                    settingsCardKey: _settingsCardKey,
                  ),
                  _InviteRosterTab(
                    classId: widget.classId,
                    fallbackCode: inviteCode,
                    inviteCardKey: _inviteCardKey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 0),
    );
  }
}

// ============================================================
// HEADER STATUS BANNER
// ============================================================

class _ClassStatusHeaderBanner extends ConsumerStatefulWidget {
  const _ClassStatusHeaderBanner({
    required this.classId,
    required this.cls,
    required this.inviteCode,
    this.statusBadgeKey,
  });

  final String classId;
  final LecturerClass? cls;
  final String? inviteCode;
  final GlobalKey? statusBadgeKey;

  @override
  ConsumerState<_ClassStatusHeaderBanner> createState() =>
      _ClassStatusHeaderBannerState();
}

class _ClassStatusHeaderBannerState
    extends ConsumerState<_ClassStatusHeaderBanner> {
  bool _busy = false;

  Future<void> _changeStatus(String targetStatus, String successMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await runClassAction(
        context,
        () => setClassStatusAction(
          ref,
          classId: widget.classId,
          status: targetStatus,
        ),
        successMessage: successMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final status = widget.cls?.status ?? 'draft';
    final code = widget.inviteCode;

    final (Color badgeColor, String badgeLabel) = switch (status) {
      'published' => (AppColors.successGreen, l10n.classStatusPublished),
      'archived' => (AppColors.textMuted, l10n.classStatusArchived),
      _ => (AppColors.warningAmber, l10n.classStatusDraft),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle(context)),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.s10,
        runSpacing: AppSpacing.s8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: widget.statusBadgeKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.rPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'published'
                          ? Icons.check_circle_rounded
                          : status == 'archived'
                              ? Icons.archive_outlined
                              : Icons.edit_note_rounded,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: AppTypography.badge(context).copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (code != null && code.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.s8),
                InkWell(
                  key: const Key('header_copy_invite_code_btn'),
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.classInviteCodeCopied)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.vpn_key_outlined,
                          size: 13,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          code,
                          style: AppTypography.badge(context).copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('header_open_discussions_btn'),
                onPressed: () => context.push(
                  '/lecturer/discussions?classId=${widget.classId}',
                ),
                icon: const Icon(Icons.forum_outlined, size: 15),
                label: Text(isId ? 'Forum Diskusi' : 'Q&A Forum'),
              ),
              if (status == 'draft')
                FilledButton.icon(
                  key: const Key('publish_class_header_btn'),
                  onPressed: _busy
                      ? null
                      : () => _changeStatus(
                            'published',
                            isId
                                ? 'Kelas berhasil dipublikasikan! Mahasiswa kini dapat bergabung.'
                                : 'Class published! Students can now join with the invite code.',
                          ),
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish_rounded, size: 16),
                  label: Text(l10n.classPublishAction),
                ),
              if (status == 'published')
                OutlinedButton.icon(
                  key: const Key('unpublish_class_header_btn'),
                  onPressed: _busy
                      ? null
                      : () => _changeStatus(
                            'draft',
                            isId
                                ? 'Status kelas diubah ke Draf.'
                                : 'Class status set to Draft.',
                          ),
                  icon: const Icon(Icons.unpublished_outlined, size: 16),
                  label: Text(isId ? 'Jadikan Draf' : 'Set to Draft'),
                ),
              if (status == 'archived')
                FilledButton.icon(
                  key: const Key('restore_class_header_btn'),
                  onPressed: _busy
                      ? null
                      : () => _changeStatus(
                            'draft',
                            isId
                                ? 'Kelas berhasil dipulihkan ke Draf.'
                                : 'Class restored to Draft.',
                          ),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: Text(l10n.classRestoreAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: MODULES & SUBCHAPTERS
// ============================================================

class _ModulesTab extends ConsumerWidget {
  const _ModulesTab({
    required this.classId,
    this.headerKey,
  });

  final String classId;
  final GlobalKey? headerKey;

  Future<void> _showModuleDialog(
    BuildContext context,
    WidgetRef ref, {
    ClassModule? editing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final titleIdCtrl =
        TextEditingController(text: editing?.titleId ?? editing?.title ?? '');
    final titleEnCtrl = TextEditingController(text: editing?.titleEn ?? '');
    final descIdCtrl = TextEditingController(
        text: editing?.descriptionId ?? editing?.description ?? '');
    final descEnCtrl =
        TextEditingController(text: editing?.descriptionEn ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          editing == null
              ? l10n.classAddModuleAction
              : l10n.classEditModuleAction,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('module_dialog_title_id'),
                controller: titleIdCtrl,
                decoration: InputDecoration(
                  labelText: l10n.classModuleTitleIdLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('module_dialog_title_en'),
                controller: titleEnCtrl,
                decoration: InputDecoration(
                  labelText: l10n.classModuleTitleEnLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('module_dialog_desc_id'),
                controller: descIdCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.classModuleDescIdLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('module_dialog_desc_en'),
                controller: descEnCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.classModuleDescEnLabel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('module_dialog_save_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      await runClassAction(
        context,
        () async {
          if (editing == null) {
            await createClassModuleAction(
              ref,
              classId: classId,
              titleId: titleIdCtrl.text,
              titleEn: titleEnCtrl.text,
              descriptionId: descIdCtrl.text,
              descriptionEn: descEnCtrl.text,
            );
          } else {
            await updateClassModuleAction(
              ref,
              classId: classId,
              moduleId: editing.id,
              titleId: titleIdCtrl.text,
              titleEn: titleEnCtrl.text,
              descriptionId: descIdCtrl.text,
              descriptionEn: descEnCtrl.text,
            );
          }
        },
        successMessage: l10n.classUpdatedSuccess,
      );
    }

    titleIdCtrl.dispose();
    titleEnCtrl.dispose();
    descIdCtrl.dispose();
    descEnCtrl.dispose();
  }

  Future<void> _moveModule(
    BuildContext context,
    WidgetRef ref,
    List<ClassModule> modules,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= modules.length) return;
    final ids = modules.map((m) => m.id).toList();
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    await runClassAction(
      context,
      () => reorderClassModulesAction(ref, classId: classId, moduleIds: ids),
    );
  }

  Future<void> _showCloneCurriculumDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final classes = ref.read(lecturerClassesProvider).value ?? [];
    final otherClasses = classes.where((c) => c.id != classId).toList();

    String? selectedSourceId = otherClasses.isNotEmpty ? otherClasses.first.id : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.copy_all_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(isId ? 'Salin Kurikulum' : 'Clone Curriculum', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isId
                        ? 'Salin materi modul dari kelas lain atau gunakan kurikulum template NetLearn.'
                        : 'Copy module materials from another class or use NetLearn default template.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isId ? 'Pilih Sumber Kurikulum:' : 'Select Curriculum Source:',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String?>(
                    value: null,
                    groupValue: selectedSourceId,
                    contentPadding: EdgeInsets.zero,
                    title: Text(isId ? 'Template Standar NetLearn (Global)' : 'NetLearn Default Template (Global)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(isId ? '5 Materi inti Modul 1-4' : '5 Core materials of Modules 1-4', style: const TextStyle(fontSize: 11)),
                    onChanged: (val) => setDialogState(() => selectedSourceId = val),
                  ),
                  for (final c in otherClasses)
                    RadioListTile<String?>(
                      value: c.id,
                      groupValue: selectedSourceId,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${c.code} · ${c.status == 'published' ? l10n.classStatusPublished : c.status == 'archived' ? l10n.classStatusArchived : l10n.classStatusDraft}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (val) => setDialogState(() => selectedSourceId = val),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(isId ? 'Mulai Salin' : 'Start Clone'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      await runClassAction(
        context,
        () async {
          final count = await cloneClassCurriculumAction(
            ref,
            sourceClassId: selectedSourceId,
            targetClassId: classId,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isId
                      ? '$count materi kurikulum berhasil disalin ke kelas ini!'
                      : 'Successfully cloned $count materials to this class!',
                ),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        successMessage: null,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider).languageCode;
    final modulesAsync = ref.watch(classModulesProvider(classId));
    final modules = modulesAsync.value ?? const <ClassModule>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s20),
      children: [
        Row(
          key: headerKey,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${l10n.classTabModules} (${modules.length})',
                style: AppTypography.sectionTitle(context),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showCloneCurriculumDialog(context, ref),
              icon: const Icon(Icons.copy_all_rounded, size: 16),
              label: Text(lang == 'id' ? 'Salin Kurikulum' : 'Clone'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const Key('class_add_module_button'),
              onPressed: () => _showModuleDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.classAddModuleAction),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        if (modulesAsync.isLoading && modulesAsync.value == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (modulesAsync.hasError && modulesAsync.value == null)
          Center(child: Text(l10n.couldNotLoadData))
        else if (modules.isEmpty)
          NlSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Text(
                l10n.classNoModulesEmpty,
                style: AppTypography.body(context),
              ),
            ),
          )
        else
          for (var i = 0; i < modules.length; i++) ...[
            _ClassModuleCard(
              classId: classId,
              module: modules[i],
              languageCode: lang,
              canMoveUp: i > 0,
              canMoveDown: i < modules.length - 1,
              onMoveUp: () => _moveModule(context, ref, modules, i, -1),
              onMoveDown: () => _moveModule(context, ref, modules, i, 1),
              onEdit: () =>
                  _showModuleDialog(context, ref, editing: modules[i]),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
      ],
    );
  }
}

class _ClassModuleCard extends ConsumerWidget {
  const _ClassModuleCard({
    required this.classId,
    required this.module,
    required this.languageCode,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
  });

  final String classId;
  final ClassModule module;
  final String languageCode;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;

  Future<void> _confirmDeleteMaterial(
    BuildContext context,
    WidgetRef ref,
    ClassMaterialEntry mat,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final isId = languageCode == 'id';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(
          isId
              ? 'Hapus materi "${mat.material.localizedTitle(languageCode)}" dari modul ini?'
              : 'Delete material "${mat.material.localizedTitle(languageCode)}" from this module?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await runClassAction(
        context,
        () => deleteClassMaterialAction(
          ref,
          classId: classId,
          moduleId: module.id,
          materialId: mat.material.id,
        ),
        successMessage: isId ? 'Materi dihapus.' : 'Material deleted.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = languageCode == 'id';
    final materialsAsync = ref.watch(
      classModuleMaterialsProvider((classId: classId, moduleId: module.id)),
    );

    final isPublished = module.isPublished;
    final statusColor = isPublished
        ? AppColors.successGreen
        : module.isArchived
            ? AppColors.textMuted
            : AppColors.warningAmber;
    final statusLabel = isPublished
        ? l10n.classStatusPublished
        : module.isArchived
            ? l10n.classStatusArchived
            : l10n.classStatusDraft;

    return NlSurfaceCard(
      key: Key('class_module_card_${module.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.rPill),
                ),
                child: Text(
                  '${l10n.module} ${module.position}',
                  style: AppTypography.badge(context).copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.rPill),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.badge(context).copyWith(
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: isId ? 'Geser ke atas' : 'Move up',
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
              IconButton(
                tooltip: isId ? 'Geser ke bawah' : 'Move down',
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              ),
              IconButton(
                tooltip: l10n.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            module.localizedTitle(languageCode),
            style: AppTypography.cardTitle(context),
          ),
          if (module.localizedDescription(languageCode).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              module.localizedDescription(languageCode),
              style: AppTypography.body(context),
            ),
          ],
          const SizedBox(height: AppSpacing.s10),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${module.publishedMaterialCount}/${module.materialCount} ${l10n.materials}',
                style: AppTypography.caption(context),
              ),
              OutlinedButton.icon(
                key: Key('toggle_module_status_${module.id}'),
                onPressed: () => runClassAction(
                  context,
                  () => setClassModuleStatusAction(
                    ref,
                    classId: classId,
                    moduleId: module.id,
                    status: isPublished ? 'draft' : 'published',
                  ),
                  successMessage: isPublished
                      ? (isId
                          ? 'Modul diubah ke Draf.'
                          : 'Module set to Draft.')
                      : (isId
                          ? 'Modul berhasil dipublikasikan.'
                          : 'Module published.'),
                ),
                icon: Icon(
                  isPublished
                      ? Icons.unpublished_outlined
                      : Icons.publish_rounded,
                  size: 16,
                ),
                label: Text(
                  isPublished
                      ? (isId ? 'Jadikan Draf' : 'Set Draft')
                      : l10n.publish,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.s20),
          materialsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.s8),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => Text(l10n.couldNotLoadData),
            data: (materials) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (materials.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.s6),
                      child: Text(
                        isId
                            ? 'Belum ada materi pada modul ini.'
                            : 'No materials in this module yet.',
                        style: AppTypography.caption(context),
                      ),
                    ),
                  for (final mat in materials)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.s6),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.s10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated(context),
                          borderRadius: BorderRadius.circular(AppRadius.r10),
                          border: Border.all(
                            color: AppColors.borderSubtle(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  mat.published
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: mat.published
                                      ? AppColors.successGreen
                                      : AppColors.warningAmber,
                                ),
                                const SizedBox(width: AppSpacing.s8),
                                Expanded(
                                  child: Text(
                                    mat.material.localizedTitle(languageCode),
                                    style: AppTypography.body(context).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: Key(
                                      'edit_class_material_${mat.material.id}'),
                                  tooltip: l10n.editMaterial,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    selectLecturerActiveClass(ref, classId);
                                    context.push(
                                      '/lecturer/materials/${mat.material.id}/edit',
                                    );
                                  },
                                ),
                                if (!mat.isCore)
                                  IconButton(
                                    key: Key(
                                      'delete_class_material_${mat.material.id}',
                                    ),
                                    tooltip: l10n.delete,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.dangerRed,
                                    ),
                                    onPressed: () => _confirmDeleteMaterial(
                                      context,
                                      ref,
                                      mat,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s6),
                            Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ActionChip(
                                  key: Key(
                                    'toggle_material_publish_${mat.material.id}',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  avatar: Icon(
                                    mat.published
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_outlined,
                                    size: 14,
                                    color: mat.published
                                        ? AppColors.successGreen
                                        : AppColors.warningAmber,
                                  ),
                                  label: Text(
                                    mat.published
                                        ? l10n.classStatusPublished
                                        : l10n.classStatusDraft,
                                  ),
                                  onPressed: () => runClassAction(
                                    context,
                                    () => toggleClassMaterialPublishedAction(
                                      ref,
                                      classId: classId,
                                      moduleId: module.id,
                                      materialId: mat.material.id,
                                      published: !mat.published,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  key: Key(
                                    'material_lock_menu_${mat.material.id}',
                                  ),
                                  tooltip: l10n.materialAccessLabel,
                                  onSelected: (lockVal) => runClassAction(
                                    context,
                                    () => updateClassMaterialLockStatusAction(
                                      ref,
                                      classId: classId,
                                      moduleId: module.id,
                                      materialId: mat.material.id,
                                      lockStatus: lockVal,
                                    ),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'default',
                                      child: Text(
                                          l10n.materialAccessOptionProgress),
                                    ),
                                    PopupMenuItem(
                                      value: 'unlocked',
                                      child:
                                          Text(l10n.materialAccessOptionOpen),
                                    ),
                                    PopupMenuItem(
                                      value: 'locked',
                                      child:
                                          Text(l10n.materialAccessOptionLocked),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.r8),
                                      border: Border.all(
                                        color: AppColors.borderSubtle(context),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          mat.material.lockStatus == 'locked'
                                              ? Icons.lock_rounded
                                              : mat.material.lockStatus ==
                                                      'unlocked'
                                                  ? Icons.lock_open_rounded
                                                  : Icons.schedule_rounded,
                                          size: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          mat.material.lockStatus == 'locked'
                                              ? l10n.materialAccessOptionLocked
                                              : mat.material.lockStatus ==
                                                      'unlocked'
                                                  ? l10n
                                                      .materialAccessOptionOpen
                                                  : l10n
                                                      .materialAccessOptionProgress,
                                          style: AppTypography.caption(context),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: Key('add_material_to_module_${module.id}'),
                      onPressed: () {
                        context.push(
                          '/lecturer/materials/create?classId=$classId&moduleId=${module.id}&moduleNumber=${module.position}',
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l10n.addMaterial),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 2: SETTINGS & GATES
// ============================================================

class _SettingsGatesTab extends ConsumerWidget {
  const _SettingsGatesTab({
    required this.classId,
    required this.cls,
    this.settingsCardKey,
  });

  final String classId;
  final LecturerClass? cls;
  final GlobalKey? settingsCardKey;

  Future<void> _showEditClassInfoDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: cls?.name ?? '');
    final semesterCtrl = TextEditingController(text: cls?.semester ?? '');
    final descCtrl = TextEditingController(text: cls?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.basicInformation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('edit_class_name_field'),
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.classNameLabel),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('edit_class_semester_field'),
                controller: semesterCtrl,
                decoration: InputDecoration(labelText: l10n.classSemesterLabel),
              ),
              const SizedBox(height: AppSpacing.s10),
              TextField(
                key: const Key('edit_class_desc_field'),
                controller: descCtrl,
                maxLines: 3,
                decoration:
                    InputDecoration(labelText: l10n.classDescriptionLabel),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('save_class_info_btn'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      await runClassAction(
        context,
        () => updateClassInfoAction(
          ref,
          classId: classId,
          name: nameCtrl.text,
          semester: semesterCtrl.text,
          description: descCtrl.text,
        ),
        successMessage: l10n.classUpdatedSuccess,
      );
    }

    nameCtrl.dispose();
    semesterCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _confirmAndUpdatePolicy(
    BuildContext context,
    WidgetRef ref, {
    required bool pretestEnabled,
    required bool posttestEnabled,
    required bool leaderboardEnabled,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.classPolicyChangeTitle),
        content: Text(l10n.classPolicyChangeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_policy_change_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await runClassAction(
        context,
        () => updateClassSettingsAction(
          ref,
          classId: classId,
          pretestEnabled: pretestEnabled,
          posttestEnabled: posttestEnabled,
          leaderboardEnabled: leaderboardEnabled,
        ),
        successMessage: l10n.classUpdatedSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider).languageCode;
    final isId = lang == 'id';
    final settingsAsync = ref.watch(classSettingsProvider(classId));
    final gatesAsync = ref.watch(classGateAssessmentsProvider(classId));

    final settings = settingsAsync.value;
    final pretestOn = settings?.pretestEnabled ?? cls?.pretestEnabled ?? false;
    final posttestOn =
        settings?.posttestEnabled ?? cls?.posttestEnabled ?? false;
    final lbOn =
        settings?.leaderboardEnabled ?? cls?.leaderboardEnabled ?? true;
    final currentStatus = cls?.status ?? 'draft';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s20),
      children: [
        if (settingsAsync.isLoading && settings == null) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.s12),
        ],
        // Card 1: Class Basic Info
        NlSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.basicInformation,
                        style: AppTypography.cardTitle(context),
                      ),
                      TextButton.icon(
                        key: const Key('edit_class_info_btn'),
                        onPressed: () => _showEditClassInfoDialog(context, ref),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(l10n.edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    cls?.name ?? '—',
                    style: AppTypography.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (cls?.semester != null && cls!.semester!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.classSemesterLabel}: ${cls!.semester}',
                      style: AppTypography.caption(context),
                    ),
                  ],
                  if (cls?.description != null &&
                      cls!.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      cls!.description!,
                      style: AppTypography.body(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // Card 2: Learning Flow Gate Toggles
            NlSurfaceCard(
              key: settingsCardKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.classTabSettings,
                    style: AppTypography.cardTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  SwitchListTile(
                    key: const Key('settings_pretest_switch'),
                    contentPadding: EdgeInsets.zero,
                    value: pretestOn,
                    onChanged: (val) => _confirmAndUpdatePolicy(
                      context,
                      ref,
                      pretestEnabled: val,
                      posttestEnabled: posttestOn,
                      leaderboardEnabled: lbOn,
                    ),
                    title: Text(l10n.classPretestEnabledLabel),
                    subtitle: Text(l10n.classPretestEnabledHelper),
                  ),
                  const Divider(),
                  SwitchListTile(
                    key: const Key('settings_posttest_switch'),
                    contentPadding: EdgeInsets.zero,
                    value: posttestOn,
                    onChanged: (val) => _confirmAndUpdatePolicy(
                      context,
                      ref,
                      pretestEnabled: pretestOn,
                      posttestEnabled: val,
                      leaderboardEnabled: lbOn,
                    ),
                    title: Text(l10n.classPosttestEnabledLabel),
                    subtitle: Text(l10n.classPosttestEnabledHelper),
                  ),
                  const Divider(),
                  SwitchListTile(
                    key: const Key('settings_leaderboard_switch'),
                    contentPadding: EdgeInsets.zero,
                    value: lbOn,
                    onChanged: (val) => _confirmAndUpdatePolicy(
                      context,
                      ref,
                      pretestEnabled: pretestOn,
                      posttestEnabled: posttestOn,
                      leaderboardEnabled: val,
                    ),
                    title: Text(l10n.classLeaderboardEnabledLabel),
                    subtitle: Text(l10n.classLeaderboardEnabledHelper),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // Card 3: Pretest & Posttest Gate Assessments Readiness
            NlSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isId
                              ? 'Kesiapan Asesmen Gerbang (Pretest & Posttest)'
                              : 'Gate Assessments Readiness (Pretest & Posttest)',
                          style: AppTypography.cardTitle(context),
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('open_lecturer_assessments_btn'),
                        onPressed: () {
                          selectLecturerActiveClass(ref, classId);
                          context.push('/lecturer/assessments');
                        },
                        icon: const Icon(Icons.quiz_outlined, size: 16),
                        label: Text(isId ? 'Kelola Soal' : 'Manage Questions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  gatesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.s8),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, _) => Text(l10n.couldNotLoadData),
                    data: (gates) {
                      if (gates.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isId
                                  ? 'Belum ada Pretest/Posttest untuk kelas ini.'
                                  : 'No Pretest/Posttest configured for this class yet.',
                              style: AppTypography.caption(context),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            OutlinedButton.icon(
                              key: const Key('init_class_gates_btn'),
                              onPressed: () => runClassAction(
                                context,
                                () async {
                                  await ensureClassGateAssessmentsExist(
                                      classId);
                                  ref.invalidate(
                                    classGateAssessmentsProvider(classId),
                                  );
                                },
                                successMessage: isId
                                    ? 'Pretest & Posttest berhasil disiapkan.'
                                    : 'Pretest & Posttest initialized.',
                              ),
                              icon: const Icon(
                                Icons.auto_fix_high_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isId
                                    ? 'Siapkan Pretest & Posttest dari Template'
                                    : 'Initialize Pretest & Posttest from Template',
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          for (final gate in gates)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.s6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    gate.isPublished
                                        ? Icons.check_circle_rounded
                                        : Icons.pending_outlined,
                                    size: 18,
                                    color: gate.isPublished
                                        ? AppColors.successGreen
                                        : AppColors.warningAmber,
                                  ),
                                  const SizedBox(width: AppSpacing.s10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gate.localizedTitle(lang),
                                          style: AppTypography.body(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          isId
                                              ? '${gate.answeredCount}/${gate.questionCount} soal berkunci • ${gate.isPublished ? l10n.classStatusPublished : l10n.classStatusDraft}'
                                              : '${gate.answeredCount}/${gate.questionCount} keyed questions • ${gate.isPublished ? l10n.classStatusPublished : l10n.classStatusDraft}',
                                          style: AppTypography.caption(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    key: Key(
                                      'toggle_gate_${gate.assessmentType}_btn',
                                    ),
                                    onPressed: () => runClassAction(
                                      context,
                                      () =>
                                          setClassGateAssessmentPublishedAction(
                                        ref,
                                        classId: classId,
                                        assessmentType: gate.assessmentType,
                                        published: !gate.isPublished,
                                      ),
                                      successMessage: !gate.isPublished
                                          ? (isId
                                              ? '${gate.localizedTitle(lang)} dipublikasikan.'
                                              : '${gate.localizedTitle(lang)} published.')
                                          : (isId
                                              ? '${gate.localizedTitle(lang)} diubah ke Draf.'
                                              : '${gate.localizedTitle(lang)} set to Draft.'),
                                    ),
                                    child: Text(
                                      gate.isPublished
                                          ? (isId ? 'Jadikan Draf' : 'Draft')
                                          : l10n.publish,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // Card 4: Class Lifecycle (Publish / Archive / Restore)
            NlSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isId ? 'Siklus Hidup Kelas' : 'Class Lifecycle',
                    style: AppTypography.cardTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (currentStatus == 'draft')
                    FilledButton.icon(
                      key: const Key('publish_class_btn'),
                      onPressed: () => runClassAction(
                        context,
                        () => setClassStatusAction(
                          ref,
                          classId: classId,
                          status: 'published',
                        ),
                        successMessage: isId
                            ? 'Kelas berhasil dipublikasikan!'
                            : 'Class published successfully!',
                      ),
                      icon: const Icon(Icons.publish_rounded),
                      label: Text(l10n.classPublishAction),
                    ),
                  if (currentStatus != 'archived') ...[
                    const SizedBox(height: AppSpacing.s8),
                    OutlinedButton.icon(
                      key: const Key('archive_class_btn'),
                      onPressed: () => runClassAction(
                        context,
                        () => setClassStatusAction(
                          ref,
                          classId: classId,
                          status: 'archived',
                        ),
                        successMessage: isId
                            ? 'Kelas berhasil diarsipkan.'
                            : 'Class archived.',
                      ),
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(l10n.classArchiveAction),
                    ),
                  ] else
                    FilledButton.icon(
                      key: const Key('restore_class_btn'),
                      onPressed: () => runClassAction(
                        context,
                        () => setClassStatusAction(
                          ref,
                          classId: classId,
                          status: 'draft',
                        ),
                        successMessage: isId
                            ? 'Kelas berhasil dipulihkan ke Draf.'
                            : 'Class restored to Draft.',
                      ),
                      icon: const Icon(Icons.restore_rounded),
                      label: Text(l10n.classRestoreAction),
                    ),
                ],
              ),
            ),
          ],
        );
  }
}

// ============================================================
// TAB 3: INVITE CODE & ROSTER
// ============================================================

class _InviteRosterTab extends ConsumerWidget {
  const _InviteRosterTab({
    required this.classId,
    this.fallbackCode,
    this.inviteCardKey,
  });

  final String classId;
  final String? fallbackCode;
  final GlobalKey? inviteCardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final inviteAsync = ref.watch(classInviteProvider(classId));
    final rosterAsync = ref.watch(classRosterProvider(classId));

    final invite = inviteAsync.value;
    final code = invite?.code ?? fallbackCode ?? '—';
    final active = invite?.active ?? true;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s20),
      children: [
        NlSurfaceCard(
          key: inviteCardKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.classInviteCodeLabel,
                style: AppTypography.cardTitle(context),
              ),
              if (inviteAsync.isLoading && invite == null) ...[
                const SizedBox(height: AppSpacing.s8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      code,
                      key: const Key('invite_code_display'),
                      style: AppTypography.displayTitle(context).copyWith(
                        color: AppColors.primaryBlue,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('copy_invite_code_button'),
                    tooltip: l10n.classInviteCodeLabel,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.classInviteCodeCopied),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  IconButton(
                    key: const Key('rotate_invite_code_button'),
                    tooltip: l10n.classRotateInviteAction,
                    onPressed: () => runClassAction(
                      context,
                      () => rotateClassInviteAction(ref, classId),
                      successMessage: isId
                          ? 'Kode undangan berhasil diperbarui.'
                          : 'Invite code rotated.',
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const Divider(),
              SwitchListTile(
                key: const Key('invite_active_switch'),
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (v) => runClassAction(
                  context,
                  () => setClassInviteActiveAction(
                    ref,
                    classId: classId,
                    active: v,
                  ),
                ),
                title: Text(l10n.classInviteActiveLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        NlSurfaceCard(
          child: rosterAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(l10n.couldNotLoadData),
            data: (roster) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.classTabInviteRoster} (${roster.length})',
                    style: AppTypography.cardTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (roster.isEmpty)
                    Text(
                      l10n.classRosterEmpty,
                      style: AppTypography.body(context),
                    )
                  else
                    for (final member in roster) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => showPublicProfileSheet(
                          context,
                          userId: member.studentId,
                          classId: classId,
                          fallbackName: member.name,
                        ),
                        leading: NlAvatarWidget(
                          config: AvatarConfig.defaultFor(member.studentId),
                          size: 40,
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.identityNumber ?? '—'),
                        trailing: IconButton(
                          key: Key('remove_member_${member.studentId}'),
                          tooltip: l10n.classRemoveMemberTitle,
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.dangerRed,
                          ),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Text(l10n.classRemoveMemberTitle),
                                content: Text(l10n.classRemoveMemberConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: Text(l10n.confirm),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              await runClassAction(
                                context,
                                () => removeClassMemberAction(
                                  ref,
                                  classId: classId,
                                  studentId: member.studentId,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
