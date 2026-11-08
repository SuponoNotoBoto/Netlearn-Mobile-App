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
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../classes/lecturer_manage_class_section.dart';

/// Holds the current search text for the student list.
///
/// Riverpod 3.x does not provide `StateProvider`; a `Notifier` is used
/// instead, following the same pattern as `LanguageController`.
class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String value) {
    state = value;
  }
}

/// Provides the current search text for the student list page.
final _searchProvider =
    NotifierProvider.autoDispose<_SearchNotifier, String>(_SearchNotifier.new);

/// Student list for the lecturer, with two tabs: Student Data and Score
/// Recap — layout mengikuti desain `StudentProgress.tsx` (tab `.tabs`,
/// kartu mahasiswa `.card`, tabel nilai compact).
///
/// Both tabs read the same provider — `lecturerStudentsProvider`, which loads
/// every profile with role='student' plus the latest submitted pretest/posttest
/// score through the `get_lecturer_student_overview` RPC. One source, no
/// duplicated queries.
///
/// Searchable by name or student ID (NIM). Email is deliberately not
/// displayed to avoid exposing contact data unnecessarily. Halaman ini adalah
/// halaman second-level: kembali lewat NlTopBar, bukan salah satu tab navbar.
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

  /// Tab navbar yang disorot: Profil (index 4), sesuai screenshot acuan.
  static const _profileNavIndex = 4;

  int _selectedTab = _studentDataTab;

  List<StudentModel> _filter(List<StudentModel> students, String search) {
    if (search.isEmpty) {
      return students;
    }

    return students.where((student) {
      return student.name.toLowerCase().contains(search) ||
          (student.identityNumber?.toLowerCase().contains(search) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final studentsAsync = ref.watch(lecturerStudentsProvider(null));
    final activeClass = ref.watch(activeLecturerClassProvider).value;
    final classes = ref.watch(lecturerClassesProvider).value;

    return Scaffold(
      backgroundColor: context.background,

      appBar: NlTopBar(
        title: l10n.studentList,
        onBack: () => context.pop(),
      ),

      body: Column(
        children: [
          if (classes != null &&
              activeClass != null &&
              activeClass.id != kLegacyFallbackClassId) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NetLearnSpace.s20,
                NetLearnSpace.s12,
                NetLearnSpace.s20,
                0,
              ),
              child: LecturerActiveClassBar(
                classes: classes,
                activeClass: activeClass,
              ),
            ),
          ],
          // `.tabs` dari desain: track abu, pill putih untuk tab terpilih —
          // bukan pil ungu solid.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NetLearnSpace.s20,
              NetLearnSpace.s16,
              NetLearnSpace.s20,
              0,
            ),
            child: NlSegmentedTabs(
              labels: [l10n.studentData, l10n.scoreOverview],
              selectedIndex: _selectedTab,
              semanticLabel: l10n.studentList,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),

          const SizedBox(height: NetLearnSpace.s16),

          // Tab content.
          Expanded(
            child: _selectedTab == _scoreOverviewTab
                ? const LecturerScoreOverviewTab()
                : _buildStudentDataTab(context, l10n, studentsAsync),
          ),
        ],
      ),

      // Screenshot acuan akhir masih menampilkan bottom navbar (tab Profil
      // aktif) di halaman ini, jadi navbar dipertahankan — berbeda dengan
      // instruksi awal menghapusnya; keputusan produk menyusul. Index 4
      // (Profil) dipakai karena halaman ini di-push dari shortcut Profil.
      bottomNavigationBar:
          LecturerBottomNavbar(currentIndex: _profileNavIndex),
    );
  }

  Widget _buildStudentDataTab(
    BuildContext context,
    AppLocalizations l10n,
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
                child: Text(l10n.retry),
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
              // Blok pengantar. Judul h2 ("Student List") sengaja tidak
              // diulang di sini: top bar sudah memuat judul yang sama, dan di
              // prototipe h2 hanya ada karena frame Figma tidak punya top bar.
              Text(
                l10n.studentScoreSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s4),
              Text(
                l10n.studentListIntro,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const SizedBox(height: NetLearnSpace.s16),

              // `.search` — permukaan putih, teks 12px, ikon 17px.
              TextField(
                onChanged: (value) =>
                    ref.read(_searchProvider.notifier).setSearch(value),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: l10n.searchStudentsHint,
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

              // Student list — kartu persis Figma: nama + NIM + tombol.
              if (students.isEmpty)
                NlEmptyState(
                  icon: Icons.people_outline,
                  title: l10n.noStudents,
                  message: l10n.noStudentsDescription,
                )
              else if (visible.isEmpty)
                Text(
                  l10n.noStudentsFound,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
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

/// Kartu mahasiswa versi desain: nama, NIM, dan satu tombol ke Rekap Nilai.
/// Dilengkapi penanda mahasiswa pasif / butuh perhatian dan aksi kirim pengingat cepat.
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
    final l10n = AppLocalizations.of(context)!;
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
          if (student.identityNumber != null &&
              student.identityNumber!.isNotEmpty)
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
              label: l10n.viewScoreSummary,
              trailingIcon: Icons.arrow_forward,
              variant: NlButtonVariant.secondary,
              onPressed: () =>
                  context.push('/lecturer/students/${student.id}'),
            ),
          ),
        ],
      ),
    );
  }
}
