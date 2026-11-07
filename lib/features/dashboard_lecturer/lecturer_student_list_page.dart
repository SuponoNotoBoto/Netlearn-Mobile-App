import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/student_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_segmented_tabs.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'lecturer_bottom_navbar.dart';
import 'lecturer_score_overview.dart';
import 'lecturer_students_controller.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String value) {
    state = value;
  }
}

final _searchProvider =
    NotifierProvider.autoDispose<_SearchNotifier, String>(_SearchNotifier.new);

class LecturerStudentListPage extends ConsumerStatefulWidget {
  const LecturerStudentListPage({super.key});

  @override
  ConsumerState<LecturerStudentListPage> createState() =>
      _LecturerStudentListPageState();
}

class _LecturerStudentListPageState
    extends ConsumerState<LecturerStudentListPage> {
  static const _studentDataTab = 0;
  static const _scoreOverviewTab = 1;

  int _selectedTab = _studentDataTab;

  List<StudentModel> _filter(List<StudentModel> students, String search) {
    if (search.isEmpty) {
      return students;
    }

    final query = search.toLowerCase();
    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          (student.identityNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isId = l10n == null || Localizations.localeOf(context).languageCode == 'id';

    final studentsAsync = ref.watch(lecturerStudentsProvider(null));

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n?.studentList ?? 'Daftar Mahasiswa',
        onBack: () => context.pop(),
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
              labels: [
                l10n?.studentData ?? 'Data Mahasiswa',
                l10n?.scoreOverview ?? 'Rekap Nilai',
              ],
              selectedIndex: _selectedTab,
              semanticLabel: l10n?.studentList ?? 'Daftar Mahasiswa',
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
                : _buildStudentDataTab(context, l10n, isId, studentsAsync),
          ),
        ],
      ),
      bottomNavigationBar: const LecturerBottomNavbar(currentIndex: 3),
    );
  }

  Widget _buildStudentDataTab(
    BuildContext context,
    AppLocalizations? l10n,
    bool isId,
    AsyncValue<List<StudentModel>> studentsAsync,
  ) {
    final search = ref.watch(_searchProvider);

    return studentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(NetLearnSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 46,
                color: NetLearnColors.danger,
              ),
              const SizedBox(height: NetLearnSpace.s12),
              Text(
                mapStudentsError(error).message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NetLearnSpace.s12),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(lecturerStudentsProvider(null));
                },
                child: Text(l10n?.retry ?? 'Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (students) {
        final visible = _filter(students, search);

        return RefreshIndicator(
          color: context.accent,
          onRefresh: () async {
            ref.invalidate(lecturerStudentsProvider(null));
            await ref.read(lecturerStudentsProvider(null).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              NetLearnSpace.s20,
              NetLearnSpace.s8,
              NetLearnSpace.s20,
              NetLearnSpace.s32,
            ),
            children: [
              Text(
                l10n?.studentScoreSummary ?? 'Ringkasan Nilai Mahasiswa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s4),
              Text(
                l10n?.studentListIntro ??
                    'Pantau progres pembelajaran, nilai evaluasi, dan keaktifan mahasiswa di kelas Anda.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s16),
              TextField(
                onChanged: (value) =>
                    ref.read(_searchProvider.notifier).setSearch(value),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: l10n?.searchStudentsHint ?? 'Cari nama atau NIM mahasiswa...',
                  prefixIcon: const Icon(Icons.search, size: 17),
                  filled: true,
                  fillColor: context.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: NetLearnSpace.s16),
              if (students.isEmpty)
                NlEmptyState(
                  icon: Icons.people_outline,
                  title: l10n?.noStudents ?? 'Belum Ada Mahasiswa',
                  message: l10n?.noStudentsDescription ?? 'Belum ada mahasiswa yang terdaftar di kelas.',
                )
              else if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      l10n?.noStudentsFound ?? 'Tidak ada mahasiswa yang cocok dengan pencarian.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.mutedText,
                          ),
                    ),
                  ),
                )
              else
                for (final student in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NetLearnSpace.s12),
                    child: _StudentCard(student: student),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;

  const _StudentCard({required this.student});

  void _sendReminderDialog(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final ctrl = TextEditingController(
      text: isId
          ? 'Halo ${student.name}, jangan lupa untuk melanjutkan materi modul NetLearn dan menyelesaikan evaluasi kompetensi minggu ini ya! Tetap semangat!'
          : 'Hi ${student.name}, don\'t forget to continue your NetLearn modules and complete the assessment this week! Keep it up!',
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
        ),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_outlined, color: Color(0xFFE65100)),
            const SizedBox(width: 8),
            Text(
              isId ? 'Kirim Pengingat Belajar' : 'Send Study Reminder',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isId
                  ? 'Kirim notifikasi pengingat langsung kepada mahasiswa ini:'
                  : 'Send a direct reminder notification to this student:',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF7F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(isId ? 'Batal' : 'Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(isId ? 'Kirim Sekarang' : 'Send Now'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8C52FF)),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isId
                        ? 'Pengingat berhasil dikirim kepada ${student.name}!'
                        : 'Reminder sent to ${student.name}!',
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isId = Localizations.localeOf(context).languageCode == 'id';

    final bool isAtRisk = !student.isActive ||
        (student.pretestScore == null &&
            student.createdAt != null &&
            DateTime.now().difference(student.createdAt!).inDays >= 3) ||
        (student.pretestScore != null && student.pretestScore! < 50 && student.posttestScore == null);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: isAtRisk ? const Color(0xFFFFB74D) : context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAtRisk) ...[
            Container(
              margin: const EdgeInsets.only(bottom: NetLearnSpace.s10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isId
                          ? 'Perlu Perhatian (Mahasiswa Pasif / Nilai Rendah)'
                          : 'Needs Attention (Inactive / Low Score)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            student.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: NetLearnSpace.s6),
          if (student.identityNumber != null && student.identityNumber!.isNotEmpty)
            Text(
              'NIM: ${student.identityNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
            ),
          const SizedBox(height: NetLearnSpace.s16),
          if (isAtRisk) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFFE65100)),
                label: Text(
                  isId ? 'Kirim Pengingat' : 'Send Reminder',
                  style: const TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFB74D)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _sendReminderDialog(context),
              ),
            ),
            const SizedBox(height: NetLearnSpace.s8),
          ],
          SizedBox(
            width: double.infinity,
            child: NlButton(
              label: l10n?.viewScoreSummary ?? 'Lihat Rekap Nilai',
              trailingIcon: Icons.arrow_forward,
              variant: NlButtonVariant.secondary,
              onPressed: () => context.push('/lecturer/students/${student.id}'),
            ),
          ),
        ],
      ),
    );
  }
}

