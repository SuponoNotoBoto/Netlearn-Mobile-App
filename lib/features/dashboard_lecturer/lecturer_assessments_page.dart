import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../../shared/widgets/status_badge.dart';
import 'assessment_models.dart';
import 'lecturer_score_overview.dart';
import 'lecturer_task_form_page.dart';

class LecturerAssessmentsPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;

  const LecturerAssessmentsPage({
    super.key,
    this.onBack,
    this.bottomNavigationBar,
  });

  @override
  State<LecturerAssessmentsPage> createState() => _LecturerAssessmentsPageState();
}

class _LecturerAssessmentsPageState extends State<LecturerAssessmentsPage> {
  static const int _assessmentsTab = 0;
  static const int _scoreOverviewTab = 1;

  int _selectedTab = _assessmentsTab;

  late List<LecturerAssessment> _coreAssessments;
  late List<LecturerTask> _customTasks;

  @override
  void initState() {
    super.initState();
    _coreAssessments = getInitialAssessments();
    _customTasks = getInitialTasks();
  }

  void _openCreateTaskForm() async {
    final created = await Navigator.push<LecturerTask>(
      context,
      MaterialPageRoute(
        builder: (context) => LecturerTaskFormPage(
          onSave: (newTask) {
            setState(() {
              _customTasks.insert(0, newTask);
            });
          },
        ),
      ),
    );

    if (created != null && mounted) {
      setState(() {
        if (!_customTasks.any((t) => t.id == created.id)) {
          _customTasks.insert(0, created);
        }
      });
    }
  }

  void _openEditTaskForm(LecturerTask task) async {
    final updated = await Navigator.push<LecturerTask>(
      context,
      MaterialPageRoute(
        builder: (context) => LecturerTaskFormPage(
          task: task,
          onSave: (edited) {
            setState(() {
              final idx = _customTasks.indexWhere((t) => t.id == edited.id);
              if (idx != -1) {
                _customTasks[idx] = edited;
              }
            });
          },
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        final idx = _customTasks.indexWhere((t) => t.id == updated.id);
        if (idx != -1) {
          _customTasks[idx] = updated;
        }
      });
    }
  }

  void _toggleAssessmentPublish(LecturerAssessment assessment) {
    final isPub = assessment.isPublished;
    final nextStatus = isPub ? 'draft' : 'published';

    setState(() {
      final index = _coreAssessments.indexWhere((a) => a.id == assessment.id);
      if (index != -1) {
        _coreAssessments[index] = assessment.copyWith(status: nextStatus);
      }
    });

    NlSnackBar.show(
      context,
      isPub
          ? 'Asesmen "${assessment.title}" telah disembunyikan (Draft)'
          : 'Asesmen "${assessment.title}" berhasil diterbitkan',
      tone: NlSnackTone.success,
    );
  }

  void _toggleTaskPublish(LecturerTask task) {
    final isPub = task.isPublished;
    final nextStatus = isPub ? 'draft' : 'published';

    setState(() {
      final index = _customTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _customTasks[index] = task.copyWith(status: nextStatus);
      }
    });

    NlSnackBar.show(
      context,
      isPub
          ? 'Tugas "${task.title}" telah disembunyikan (Draft)'
          : 'Tugas "${task.title}" berhasil diterbitkan',
      tone: NlSnackTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: 'Asesmen',
        onBack: widget.onBack ?? (Navigator.canPop(context) ? () => Navigator.pop(context) : null),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NetLearnSpace.s20,
              NetLearnSpace.s16,
              NetLearnSpace.s20,
              0,
            ),
            child: NlSegmentedTabs(
              labels: const ['Asesmen Utama', 'Rekap Nilai'],
              selectedIndex: _selectedTab,
              semanticLabel: 'Asesmen & Rekap Nilai',
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),
          const SizedBox(height: NetLearnSpace.s16),
          Expanded(
            child: _selectedTab == _scoreOverviewTab
                ? const LecturerScoreOverviewTab()
                : _buildAssessmentsTab(context),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == _assessmentsTab
          ? FloatingActionButton.extended(
              backgroundColor: context.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Asesmen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: _openCreateTaskForm,
            )
          : null,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  Widget _buildAssessmentsTab(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: context.accent,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() {
          _coreAssessments = getInitialAssessments();
          _customTasks = getInitialTasks();
        });
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s8,
          NetLearnSpace.s20,
          NetLearnSpace.s32 + 64,
        ),
        children: [
          // Section 1: Core Assessments (Pretest & Posttest)
          Text(
            'Asesmen Utama (Gerbang)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: NetLearnColors.neutral900,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s12),
          for (final assessment in _coreAssessments)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCoreAssessmentCard(context, assessment),
            ),

          const SizedBox(height: NetLearnSpace.s16),

          // Section 2: Custom Tasks & LMS Assessments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tugas & Kuis Kustom',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: NetLearnColors.neutral900,
                  ),
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              TextButton.icon(
                onPressed: _openCreateTaskForm,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  'Buat Baru',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s12),

          if (_customTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(NetLearnSpace.s24),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: context.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 40, color: context.mutedText),
                  const SizedBox(height: NetLearnSpace.s8),
                  const Text(
                    'Belum Ada Asesmen Kustom',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buat asesmen kustom bebas atau kuis terikat modul untuk mahasiswa di kelas Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.mutedText, fontSize: 12),
                  ),
                  const SizedBox(height: NetLearnSpace.s16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Asesmen Sekarang'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _openCreateTaskForm,
                  ),
                ],
              ),
            )
          else
            for (final task in _customTasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTaskCard(context, task),
              ),
        ],
      ),
    );
  }

  Widget _buildCoreAssessmentCard(BuildContext context, LecturerAssessment assessment) {
    final bool isPublished = assessment.isPublished;
    final bool isPretest = assessment.isPretest;

    final Color typeAccent = isPretest ? NetLearnAccents.purple : NetLearnAccents.pink;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              StatusBadge(
                status: isPublished ? NetLearnStatus.linked : NetLearnStatus.active,
                label: isPublished ? 'Terbit' : 'Draft',
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s10),
          Text(
            assessment.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: NetLearnColors.neutral900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NetLearnSpace.s10),
          Text(
            '${assessment.questionCount} Soal · ${assessment.durationMinutes} Mnt',
            style: TextStyle(
              fontSize: 12,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s4),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: NetLearnColors.forest,
              ),
              const SizedBox(width: NetLearnSpace.s6),
              Expanded(
                child: Text(
                  'Kunci jawaban dikonfigurasi (${assessment.answeredCount}/${assessment.questionCount})',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    NlSnackBar.show(
                      context,
                      'Membuka bank soal untuk ${assessment.title}',
                      tone: NlSnackTone.info,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: NetLearnColors.primaryTint,
                    foregroundColor: context.accent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Kelola Soal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: NetLearnSpace.s12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => _toggleAssessmentPublish(assessment),
                  style: FilledButton.styleFrom(
                    backgroundColor: isPublished ? context.raisedSurface : context.accent,
                    foregroundColor: isPublished ? NetLearnColors.neutral900 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isPublished ? 'Sembunyikan' : 'Terbitkan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, LecturerTask task) {
    final bool isPublished = task.isPublished;
    final bool isModuleQuiz = task.module != null;
    final String statusLabel = isPublished ? 'Terbit' : 'Draft';

    final Color accentColor = isModuleQuiz ? const Color(0xFF00B4D8) : const Color(0xFF8C52FF);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isModuleQuiz ? Icons.menu_book_rounded : Icons.assignment_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              StatusBadge(
                status: isPublished ? NetLearnStatus.linked : NetLearnStatus.active,
                label: statusLabel,
              ),
            ],
          ),
          const SizedBox(height: NetLearnSpace.s10),
          Text(
            task.localizedTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: NetLearnColors.neutral900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NetLearnSpace.s8),

          // Category & configuration chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isModuleQuiz) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Modul ${task.module}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0077B6),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (task.required ? const Color(0xFFE65100) : const Color(0xFF4CAF50)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.required ? 'Wajib Buka Modul' : 'Kuis Opsional',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: task.required ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Asesmen Bebas (LMS)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C2CE2),
                    ),
                  ),
                ),
              ],
              if (task.leaderboardEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🏆 Leaderboard',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: NetLearnSpace.s10),

          // Meta info
          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 15, color: context.mutedText),
              const SizedBox(width: 4),
              Text(
                '${task.questionCount} Soal',
                style: TextStyle(fontSize: 12, color: context.mutedText),
              ),
              const SizedBox(width: 14),
              Icon(Icons.timer_outlined, size: 15, color: context.mutedText),
              const SizedBox(width: 4),
              Text(
                '${task.durationMinutes} Mnt',
                style: TextStyle(fontSize: 12, color: context.mutedText),
              ),
              if (task.deadline != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.calendar_today_outlined, size: 14, color: context.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}',
                    style: TextStyle(fontSize: 12, color: context.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: NetLearnSpace.s16),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () {
                    NlSnackBar.show(
                      context,
                      'Membuka bank soal untuk ${task.title}',
                      tone: NlSnackTone.info,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: NetLearnColors.primaryTint,
                    foregroundColor: context.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NetLearnRadius.button),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Kelola Soal (${task.questionCount})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text(
                          'Pengaturan',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        onPressed: () => _openEditTaskForm(task),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: FilledButton.icon(
                        icon: Icon(
                          isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                        ),
                        label: Text(
                          isPublished ? 'Sembunyikan' : 'Terbitkan',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isPublished ? context.raisedSurface : context.accent,
                          foregroundColor: isPublished ? NetLearnColors.neutral900 : Colors.white,
                        ),
                        onPressed: () => _toggleTaskPublish(task),
                      ),
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
