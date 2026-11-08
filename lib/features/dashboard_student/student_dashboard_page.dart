import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../core/avatar/nl_avatar_models.dart';
import '../../core/notifications/announcement_read_store.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../core/progress/pretest_lock_prompt.dart';
import '../../core/progress/progress_refresh.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/learning_progress_model.dart';
import '../../shared/models/material_model.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_metric_grid.dart';
import '../../shared/widgets/nl_notification_bell.dart';
import '../../shared/widgets/nl_progress_summary.dart';
import '../../shared/widgets/nl_shortcut_tile.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../../shared/widgets/nl_promo_banner.dart';
import '../assessment/assessment_completed_dialog.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../classes/class_onboarding_page.dart';
import '../classes/student_my_classes_bar.dart';
import '../dashboard_lecturer/notification_controller.dart';
import '../materials/student_materials_controller.dart';
import 'student_dashboard_controller.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  const StudentDashboardPage({
    super.key,
  });

  @override
  ConsumerState<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState
    extends ConsumerState<StudentDashboardPage> {
  Future<void> _refresh() async {
    invalidateStudentProgress(ref);

    // Pengumuman dan pengingat bukan progress, jadi tidak lewat
    // invalidateStudentProgress — provider-nya di-invalidate langsung di sini.
    // Tanpa ini pull-to-refresh memuat ulang progres tapi membiarkan preview
    // "Recent Notifications" menampilkan daftar lama.
    final userId = ref.read(notificationUserIdProvider);
    if (userId != null) {
      ref.invalidate(userAnnouncementsProvider(userId));
      ref.invalidate(studentDeadlineRemindersProvider(userId));
      ref.invalidate(announcementReadIdsProvider(userId));
    }

    await ref.read(studentDashboardProvider.future);
  }

  /// The bell opens the full Notifications page.
  ///
  /// It used to toggle an in-dashboard overlay, which duplicated the page and
  /// could not scroll a long list. Both the bell and the "Lihat Semua
  /// Notifikasi" action land on the same route as the notification center.
  void _openNotifications() {
    context.push('/student/notifications');
  }

  /// Tombol `?` di hero membuka halaman "About NetLearn" (`/student/about`).
  ///
  /// Sebelumnya tidak ada pintu ke halaman itu sama sekali dari dashboard; satu-
  /// satunya jalan adalah menebak rutenya. Tombolnya dipasang di hero, di
  /// sebelah lonceng, sama seperti frame "Dashboard Mahasiswa 1".
  void _openAbout() {
    context.push('/student/about');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dashboardAsync = ref.watch(
      studentDashboardProvider,
    );

    // The dashboard row is the only place the hero and the "Recent
    // Notifications" preview can learn who is signed in. Both degrade honestly
    // to null while the row is still loading or has failed.
    final String? userId = dashboardAsync.maybeWhen(
      data: (dashboard) => dashboard.userId,
      orElse: () => null,
    );

    final classesAsync = ref.watch(studentClassesProvider);
    final activeClass = ref.watch(activeStudentClassProvider).value;
    final classes = classesAsync.value;
    if (classes != null && classes.isEmpty) {
      return Scaffold(
        backgroundColor: context.background,
        body: const SafeArea(
          child: ClassOnboardingView(
            role: ClassOnboardingRole.student,
            hasExistingClass: false,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.background,

      // Navbar utama mahasiswa.
      // Dashboard = index 0.
      bottomNavigationBar: const StudentBottomNavbar(
        currentIndex: 0,
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: context.accent,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // `.hero.dashboard-hero` ΓÇö gradien 115deg dengan sudut bawah
              // membulat. Memegang lonceng, avatar, sapaan, dan NIM dalam
              // satu bidang ungu, sama seperti dashboard dosen.
              SliverToBoxAdapter(
                child: dashboardAsync.when(
                  loading: () => _buildHero(context, null),
                  error: (error, stackTrace) =>
                      _buildHero(context, null),
                  data: (dashboard) => _buildHero(context, dashboard),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  NetLearnSpace.s20,
                  NetLearnSpace.s20,
                  NetLearnSpace.s20,
                  NetLearnSpace.s32,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Banner error dashboard hanya muncul kalau data
                      // sapaan gagal; bagian progres punya penanganannya
                      // sendiri supaya satu kegagalan tidak mengosongkan
                      // seluruh layar.
                      if (dashboardAsync.hasError) ...[
                        _DashboardErrorBanner(
                          onRetry: _refresh,
                        ),
                        const SizedBox(
                          height: NetLearnSpace.s20,
                        ),
                      ],

                      if (classes != null &&
                          activeClass != null &&
                          activeClass.id != kLegacyFallbackClassId) ...[
                        StudentMyClassesBar(
                          classes: classes,
                          activeClass: activeClass,
                        ),
                        const SizedBox(
                          height: NetLearnSpace.s16,
                        ),
                      ],

                      NlPromoBanner(
                        title: Localizations.localeOf(context).languageCode == 'id'
                            ? 'Siap Belajar Hari Ini?'
                            : 'Ready to Learn Today?',
                        subtitle: Localizations.localeOf(context).languageCode == 'id'
                            ? 'Pelajari modul, tugas, dan evaluasi jaringan dengan dashboard pribadimu.'
                            : 'Explore modules, assignments, and network evaluations from your personal dashboard.',
                        ctaLabel: Localizations.localeOf(context).languageCode == 'id'
                            ? 'Lihat Jadwal & Materi'
                            : 'View Schedule & Materials',
                        onPressed: () {
                          context.push('/student/materials');
                        },
                      ),

                      const SizedBox(
                        height: NetLearnSpace.s20,
                      ),

                      // Learning Space ΓÇö shortcut grid dipindah ke atas
                      // supaya mahasiswa cepat mencapai halaman lain.
                      _buildSectionTitle(
                        context,
                        l10n.studentSpaceHeading,
                      ),

                      const SizedBox(
                        height: NetLearnSpace.s12,
                      ),

                      _buildShortcutGrid(context, l10n, dashboardAsync.value),

                      const SizedBox(
                        height: NetLearnSpace.s20,
                      ),

                      // Learning Progress ΓÇö ringkasan, Pretest, kartu Modul
                      // 1ΓÇô4, lalu Posttest. Urutannya mengikuti alur belajar.
                      _buildLearningProgress(
                        context,
                        l10n,
                        dashboardAsync.value,
                      ),

                      const SizedBox(
                        height: NetLearnSpace.s20,
                      ),

                      // Recent Notifications ΓÇö pratinjau dari provider yang
                      // sama dengan halaman Notifikasi.
                      _buildNotifications(context, l10n, userId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.hero.dashboard-hero` ΓÇö blok gradien di paling atas dashboard.
  ///
  /// Lonceng, avatar, sapaan, dan NIM digabung di sini, bukan di app bar,
  /// karena di desain semuanya berada pada satu bidang ungu. Avatar adalah
  /// satu-satunya pintu ke profil; keluar tetap tinggal di halaman profil.
  Widget _buildHero(
    BuildContext context,
    StudentDashboardData? dashboard,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final name = dashboard?.userName.trim();

    final greeting = name != null && name.isNotEmpty
        ? '${l10n.hello}, $name'
        : '${l10n.hello}, ${l10n.student}';

    final identityNumber = dashboard?.identityNumber?.trim();
    final isDark = theme.brightness == Brightness.dark;
    if (theme.brightness == Brightness.dark || !isDark) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          NetLearnSpace.s20,
          NetLearnSpace.s12,
          NetLearnSpace.s20,
          NetLearnSpace.s4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DashboardAvatar(
              userId: dashboard?.userId,
              initial: dashboard?.initial ?? 'M',
              avatarConfig: dashboard?.avatarConfig ??
                  AvatarConfig.defaultFor(
                    dashboard?.userId ?? dashboard?.userName ?? 'student',
                  ),
              onTap: () {
                context.go('/student/profile');
              },
            ),
            const SizedBox(width: NetLearnSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark
                          ? NetLearnColors.darkText
                          : NetLearnColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    identityNumber != null && identityNumber.isNotEmpty
                        ? '${l10n.studentAcademicTag} • $identityNumber'
                        : l10n.studentAcademicTag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? NetLearnColors.darkMuted
                          : NetLearnColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NetLearnSpace.s8),
            NlNotificationBell(
              onTap: _openNotifications,
              tooltip: l10n.notificationsTitle,
            ),
            const SizedBox(width: NetLearnSpace.s8),
            _HeroIconButton(
              icon: Icons.help_outline_rounded,
              tooltip: l10n.aboutNetLearn,
              onTap: _openAbout,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        NetLearnSpace.s20,
        NetLearnSpace.s16,
        NetLearnSpace.s20,
        NetLearnSpace.s32,
      ),
      decoration: const BoxDecoration(
        gradient: NetLearnGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // `.bell` — lonceng dengan dot notifikasi belum dibaca. Logikanya
              // satu widget bersama ([NlNotificationBell]) dengan dashboard
              // dosen: dulu tombol ini tidak punya indikator apa pun. Kini
              // dot tampil hanya untuk pengumuman terpublikasi yang belum
              // dibaca dan hilang seketika begitu status baca tersimpan.
              NlNotificationBell(
                onTap: _openNotifications,
                tooltip: l10n.notificationsTitle,
              ),

              const SizedBox(width: NetLearnSpace.s8),

              // `.about` — pintu ke halaman About NetLearn. Ukuran dan gayanya
              // disamakan dengan lonceng karena di desain keduanya satu kluster.
              _HeroIconButton(
                icon: Icons.help_outline_rounded,
                tooltip: l10n.aboutNetLearn,
                onTap: _openAbout,
              ),

              const Spacer(),

              // `.dashboard-avatar` ΓÇö 49px, inisial ungu tua di atas ungu
              // muda, garis putih. Avatar adalah pintu ke profil mahasiswa.
              _DashboardAvatar(
                userId: dashboard?.userId,
                initial: dashboard?.initial ?? 'M',
                avatarConfig: dashboard?.avatarConfig ??
                    AvatarConfig.defaultFor(
                      dashboard?.userId ?? dashboard?.userName ?? 'student',
                    ),
                onTap: () {
                  context.go('/student/profile');
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // `.greeting h1` ΓÇö 25px weight 800. Sapaan penuh dengan nama
          // mahasiswa yang login, bukan "Halo" generik.
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: NetLearnColors.white,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            l10n.studentAcademicTag,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFD4CDF2),
              height: 1.4,
            ),
          ),

          if (identityNumber != null && identityNumber.isNotEmpty) ...[
            const SizedBox(height: NetLearnSpace.s16),

            // `.unified-identity` ΓÇö chip berkilau untuk NIM.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: NetLearnColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: NetLearnColors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                identityNumber,
                style: const TextStyle(
                  color: NetLearnColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// `.section-heading h2` ΓÇö judul bagian ungu, bukan eyebrow pucat.
  ///
  /// Label lama memakai gaya eyebrow (`labelSmall`) yang warnanya meredup ke
  /// teks sekunder. Di desain, heading bagian memakai warna brand penuh supaya
  /// hierarki halaman terbaca tanpa perlu garis pemisah tambahan.
  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontSize: 16,
        color: context.accent,
      ),
    );
  }

  /// Judul "Learning Progress" plus isinya.
  ///
  /// Judulnya tetap terlihat saat data belum atau tidak bisa dimuat supaya
  /// bagian utama dashboard tidak menghilang dari hierarki halaman.
  ///
  /// [dashboard] hanya dipakai oleh dua status assessment di ujung alur
  /// (Pretest dan Posttest); kartu modul tetap membaca provider progresnya
  /// sendiri supaya satu kegagalan tidak menjatuhkan seluruh bagian.
  Widget _buildLearningProgress(
    BuildContext context,
    AppLocalizations l10n,
    StudentDashboardData? dashboard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.learningProgress),
        const SizedBox(height: NetLearnSpace.s12),
        _buildProgressContent(context, l10n, dashboard),
      ],
    );
  }

  Widget _buildProgressContent(
    BuildContext context,
    AppLocalizations l10n,
    StudentDashboardData? dashboard,
  ) {
    final materialsAsync = ref.watch(
      studentMaterialsProvider,
    );

    final modulesAsync = ref.watch(
      studentModulesProvider,
    );

    final progressAsync = ref.watch(
      studentLearningProgressProvider,
    );

    if (materialsAsync.isLoading ||
        modulesAsync.isLoading ||
        progressAsync.isLoading) {
      return const _ProgressSkeleton();
    }

    if (materialsAsync.hasError ||
        modulesAsync.hasError ||
        progressAsync.hasError) {
      return _ProgressError(
        onRetry: () {
          invalidateStudentProgress(ref);
        },
      );
    }

    final materials = materialsAsync.value ?? const <MaterialModel>[];
    final modules = modulesAsync.value ?? const <StudentModule>[];
    final progress =
        progressAsync.value ?? const <LearningProgressModel>[];

    // Unlock and completion come from the same `get_learning_flow_status`
    // source the materials page uses. It used to come from the older
    // `compute_module_states` RPC, which reported finished modules as locked,
    // so the two screens disagreed.
    final moduleByNumber = <int, StudentModule>{
      for (final module in modules) module.moduleNumber: module,
    };

    final grouped = <int, List<MaterialModel>>{};

    for (final material in materials) {
      final moduleNumber =
          material.moduleNumber ?? material.orderIndex + 1;

      grouped
          .putIfAbsent(
        moduleNumber,
            () => [],
      )
          .add(material);
    }

    // Materials without a matching StudentModule still get a card, so a
    // supporting material is never silently dropped from the dashboard.
    final moduleNumbers = <int>{
      ...modules.map((module) => module.moduleNumber),
      ...grouped.keys,
    }.toList()
      ..sort();

    if (moduleNumbers.isEmpty) {
      return const _EmptyModules();
    }

    // Per-material completion is read from `learning_progress`, which is what
    // the reader, the video page and the dashboard percentage card all write.
    final completedMaterialIds = <String>{
      for (final row in progress)
        if (row.readingCompleted && row.videoCompleted) row.materialId,
    };

    final totalModules = moduleNumbers.length;

    final completedModules = modules
        .where(
          (module) => module.completed,
        )
        .length;

    final fraction =
        totalModules == 0 ? 0.0 : completedModules / totalModules;

    final completedLabel = l10n.modulesCompletedOf(
      completedModules,
      totalModules,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NlProgressSummary(
          label: l10n.learningJourney,
          percentage: (fraction * 100).round().toString(),
          progress: fraction,
          leadingCaption: completedLabel,
          trailingCaption: l10n.keepGoing,
          secondaryLabel: Localizations.localeOf(context).languageCode == 'id'
              ? 'Assessment & Evaluasi'
              : 'Assessment & Evaluation',
          secondaryPercentage: ((((dashboard?.pretestCompleted ?? false) ? 1 : 0) +
                      ((dashboard?.posttestCompleted ?? false) ? 1 : 0)) *
                  50)
              .toString(),
          secondaryProgress: (((dashboard?.pretestCompleted ?? false) ? 1 : 0) +
                  ((dashboard?.posttestCompleted ?? false) ? 1 : 0)) /
              2.0,
          semanticLabel: '${l10n.overallProgress}: $completedLabel',
        ),

        // Continue Learning — aksi utama untuk melanjutkan materi. Targetnya
        // dihitung dari data progres yang sama dengan kartu modul di bawah
        // (`resolveContinueLearningMaterial`), bukan dari sumber progres baru.
        Padding(
          padding: const EdgeInsets.only(
            bottom: NetLearnSpace.s12,
          ),
          child: _buildContinueLearning(
            context,
            l10n,
            dashboard,
            moduleNumbers: moduleNumbers,
            moduleByNumber: moduleByNumber,
            grouped: grouped,
            completedMaterialIds: completedMaterialIds,
          ),
        ),

        // Pretest ΓÇö kepala alur belajar. Selalu bisa dibuka; hanya Posttest
        if (ref.watch(classLearningFlowStatusProvider(ref.watch(activeStudentClassProvider).value?.id ?? '')).value?.pretestEnabled ?? true)
        // yang dikunci alur, jadi baris ini tidak pernah membawa gembok.
        Padding(
          padding: const EdgeInsets.only(
            bottom: NetLearnSpace.s12,
          ),
          child: _AssessmentProgressCard(
            title: l10n.shortcutPretest,
            caption: l10n.shortcutPretestHint,
            icon: Icons.quiz_outlined,
            locked: false,
            completed: dashboard?.pretestCompleted ?? false,
            onTap: () {
              // Gerbang assessment bersama, bukan push instruksi langsung:
              // dulu kartu ini selalu bisa dipaksa membuka instruksi bahkan
              // ketika Pretest sudah selesai, dan tombol mulai di sana lalu
              // berakhir di halaman error ASSESSMENT_LOCKED dengan tombol
              // Retry yang mengulang kegagalan yang sama. Kini mahasiswa
              // yang sudah mengerjakan langsung mendapat dialog hasilnya.
              openAssessmentEntry(
                context,
                ref,
                assessmentType: 'pretest',
                completed: dashboard?.pretestCompleted ?? false,
                unlocked: true,
              );
            },
          ),
        ),

        for (final moduleNumber in moduleNumbers)
          Padding(
            padding: const EdgeInsets.only(
              bottom: NetLearnSpace.s12,
            ),
            child: _ModuleProgressCard(
              module: moduleByNumber[moduleNumber],
              moduleNumber: moduleNumber,
              materials: grouped[moduleNumber] ?? const [],
              completedMaterialIds: completedMaterialIds,
              onTap: () {
                final module = moduleByNumber[moduleNumber];

                final isUnlocked = module?.unlocked ?? false;

                if (!isUnlocked) {
                  if (module?.blockedByPretest == true) {
                    // Penyebab kunci yang patut dijelaskan: modul ini
                    // tertutup Pretest, jadi pop-upnya menawarkan
                    // "Kerjakan Pretest" langsung — bukan snackbar yang
                    // menyamakan semua sebab penguncian.
                    showPretestLockedDialog(context);

                    return;
                  }

                  // Persis pemetaan batch feedback: pesan modul terkunci
                  // memakai tone error.
                  NlSnackBar.show(
                    context,
                    l10n.lockedModuleMessage,
                    tone: NlSnackTone.error,
                  );

                  return;
                }

                final moduleMaterials =
                    grouped[moduleNumber] ?? const <MaterialModel>[];

                final firstMaterialId = module?.firstMaterialId ??
                    (moduleMaterials.isEmpty
                        ? null
                        : moduleMaterials.first.id);

                if (firstMaterialId == null) {
                  return;
                }

                // Unlock is a module-wide rule, so the first material of the
                // module is always the right entry point.
                // Navigate directly to the reading page for immediate in-app reading.
                context.push(
                  '/student/material/$firstMaterialId/read',
                );
              },
            ),
          ),

        // Posttest ΓÇö penutup alur. Terkunci sampai seluruh modul selesai;
        if (ref.watch(classLearningFlowStatusProvider(ref.watch(activeStudentClassProvider).value?.id ?? '')).value?.posttestEnabled ?? true)
        // status gemboknya berasal dari `get_learning_flow_status`
        // (`posttest_unlocked`), bukan dari hitungan materi di klien.
        Padding(
          padding: const EdgeInsets.only(
            bottom: NetLearnSpace.s12,
          ),
          child: _AssessmentProgressCard(
            title: l10n.shortcutPosttest,
            caption: l10n.shortcutPosttestHint,
            icon: Icons.fact_check_outlined,
            locked: !(dashboard?.posttestUnlocked ?? false),
            completed: dashboard?.posttestCompleted ?? false,
            onTap: () {
              // Gerbang assessment bersama yang sama dengan kartu Pretest:
              // selesai → dialog hasil; masih terkunci → dialog terkunci.
              // Kartunya sendiri tetap memakai `locked` untuk mematikan
              // `InkWell.onTap` (`onTap: locked ? null : onTap`), jadi kartu
              // terkunci tidak bisa ditekan sama sekali dan `openAssessment-
              // Entry` di sini hanya menerima kartu yang sudah terbuka.
              openAssessmentEntry(
                context,
                ref,
                assessmentType: 'posttest',
                completed: dashboard?.posttestCompleted ?? false,
                unlocked: dashboard?.posttestUnlocked ?? false,
              );
            },
          ),
        ),

        // `.tip` ΓÇö ajakan singkat di bawah daftar modul.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(NetLearnSpace.s14),
          decoration: BoxDecoration(
            color: context.accentTint,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 17,
                color: context.accent,
              ),
              const SizedBox(width: NetLearnSpace.s8),
              Expanded(
                child: Text(
                  '${l10n.oneStepToday} ${l10n.oneConnectionTomorrow}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: context.accent,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tombol "Continue Learning" di bawah ringkasan progres.
  ///
  /// Targetnya dipilih oleh [resolveContinueLearningMaterial] dari data yang
  /// sudah ada di layar ini (modul ter-unlock yang belum tuntas). Kalau tidak
  /// ada modul yang bisa dilanjutkan, tombol mengikuti aturan alur belajar
  /// yang sama dengan kartu di bawah: Pretest lebih dulu kalau belum
  /// dikerjakan, lalu Post Test; dan kalau semuanya selesai, yang tampil
  /// adalah status selesai — bukan tombol yang menuju halaman salah.
  Widget _buildContinueLearning(
    BuildContext context,
    AppLocalizations l10n,
    StudentDashboardData? dashboard, {
    required List<int> moduleNumbers,
    required Map<int, StudentModule> moduleByNumber,
    required Map<int, List<MaterialModel>> grouped,
    required Set<String> completedMaterialIds,
  }) {
    final materialId = resolveContinueLearningMaterial(
      moduleNumbers: moduleNumbers,
      moduleByNumber: moduleByNumber,
      grouped: grouped,
      completedMaterialIds: completedMaterialIds,
    );

    final theme = Theme.of(context);

    if (materialId != null) {
      return _continueButton(context, l10n, () {
        context.push('/student/material/$materialId/read');
      });
    }

    final pretestBlocked =
        moduleByNumber[moduleNumbers.first]?.blockedByPretest ?? false;

    if (pretestBlocked) {
      // Aturan awal pembelajaran aplikasi: Pretest adalah gerbang seluruh
      // modul, jadi "melanjutkan" bagi mahasiswa baru berarti membuka
      // instruksi Pretest — halaman yang sama dengan kartu Pretest.
      return _continueButton(context, l10n, () {
        context.push('/student/assessment-instructions/pretest');
      });
    }

    final posttestPending = (dashboard?.posttestUnlocked ?? false) &&
        !(dashboard?.posttestCompleted ?? false);

    if (posttestPending) {
      return _continueButton(context, l10n, () {
        context.push('/student/assessment-instructions/posttest');
      });
    }

    // Semua langkah alur sudah tuntas: tampilkan status selesai, bukan
    // tombol yang tidak punya tujuan yang benar.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s14,
        vertical: NetLearnSpace.s12,
      ),
      decoration: BoxDecoration(
        color: context.accentTint,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: context.accent,
          ),
          const SizedBox(width: NetLearnSpace.s8),
          Flexible(
            child: Text(
              l10n.allMaterialsCompleted,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.accent,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tubuh tombol "Continue Learning" sesuai referensi dashboard: blok
  /// penuh selebar konten, ungu, teks putih, panah di ujung kanan.
  ///
  /// `NlButton` membungkus isi dengan `Row(mainAxisSize: min)`, sementara
  /// parent Column menata children secara start — tanpa lebar penuh, tombol
  /// menciut mengikuti teks dan proporsinya tidak lagi sesuai kartu Progress
  /// di atasnya. Posisi (di bawah ringkasan progres) dan target navigasi
  /// tidak berubah.
  Widget _continueButton(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: NlButton(
        label: l10n.continueLearning,
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: onPressed,
      ),
    );
  }

  /// `.shortcut-grid.learning-space-grid` — pintu masuk ruang belajar.
  ///
  /// Sembilan pintu sesuai desain, tersusun tiga kolom seperti frame
  /// "Dashboard Mahasiswa 1". Hanya yang benar-benar punya route yang
  /// diaktifkan: assessment (tempat pretest/posttest dan tugas berada), modul,
  /// riwayat assessment, learning video, dan virtual lab.
  /// Shortcut Profile tidak ikut di sini: sesuai referensi Dashboard Mahasiswa,
  /// Profile hanya dijangkau lewat bottom navigation.
  Widget _buildShortcutGrid(
    BuildContext context,
    AppLocalizations l10n,
    StudentDashboardData? dashboard,
  ) {
    final accents = NetLearnAccents.grid;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return NlMetricGrid(
      bordered: false,
      padding: EdgeInsets.zero,
      columns: 3,
      gap: NetLearnSpace.s12,
      bottomGap: 0,
      children: [
        NlShortcutTile(
          icon: Icons.quiz_outlined,
          accentColor: accents[2],
          title: l10n.shortcutPretest,
          subtitle: l10n.shortcutPretestHint,
          onTap: () {
            // Gerbang assessment bersama juga untuk sel Learning Space:
            // dulu selnya selalu push instruksi (keluhan "pretest/posttest
            // di Learning Space tidak bisa"), sekarang status selesai/
            // terkunci dijawab dengan dialog yang sama seperti kartu lain.
            openAssessmentEntry(
              context,
              ref,
              assessmentType: 'pretest',
              completed: dashboard?.pretestCompleted ?? false,
              unlocked: true,
            );
          },
        ),

        NlShortcutTile(
          icon: Icons.menu_book_outlined,
          accentColor: accents[0],
          title: l10n.shortcutModules,
          subtitle: l10n.shortcutModulesHint,
          onTap: () {
            context.push('/student/materials');
          },
        ),

        NlShortcutTile(
          icon: Icons.view_in_ar_rounded,
          accentColor: accents[3],
          title: l10n.shortcutScanner,
          subtitle: l10n.shortcutScannerHint,
          onTap: () {
            NlSnackBar.show(
              context,
              isId
                  ? 'Fitur AR Scanner masih dalam tahap pengembangan.'
                  : 'AR Scanner feature is currently under development.',
            );
          },
        ),

        NlShortcutTile(
          icon: Icons.fact_check_outlined,
          accentColor: accents[4],
          title: l10n.shortcutPosttest,
          subtitle: l10n.shortcutPosttestHint,
          onTap: () {
            // Gerbang yang sama dengan sel Pretest: sel Posttest yang belum
            // terbuka kini menampilkan dialog terkunci langsung dari sini,
            // bukan instruksi yang tombol mulainya menolak di akhir.
            openAssessmentEntry(
              context,
              ref,
              assessmentType: 'posttest',
              completed: dashboard?.posttestCompleted ?? false,
              unlocked: dashboard?.posttestUnlocked ?? false,
            );
          },
        ),

        NlShortcutTile(
          icon: Icons.assignment_outlined,
          accentColor: accents[1],
          title: l10n.shortcutAssignments,
          subtitle: l10n.shortcutAssignmentsHint,
          onTap: () {
            context.push('/student/assessment');
          },
        ),

        NlShortcutTile(
          icon: Icons.history_rounded,
          accentColor: accents[5],
          title: l10n.shortcutAssessmentHistory,
          subtitle: l10n.shortcutAssessmentHistoryHint,
          // "Assessment History" lebih panjang dari label lain, jadi di sel
          // sempit ia boleh membungkus ke dua baris alih-alih terpotong.
          maxTitleLines: 2,
          onTap: () {
            context.push('/student/assessment-history');
          },
        ),

        // Row 3: Learning Video, Virtual Lab. Shortcut Profile dihapus sesuai
        // referensi Dashboard Mahasiswa — Profile tetap bisa dibuka dari
        // bottom navigation. Learning Video membuka halaman daftar video;
        // Virtual Lab membuka halaman lab 2D `/student/virtual-lab`.
        NlShortcutTile(
          icon: Icons.play_circle_outline_rounded,
          accentColor: accents[1],
          title: l10n.learningVideo,
          subtitle: l10n.watchAndLearn,
          onTap: () {
            context.push('/student/video-list');
          },
        ),

        NlShortcutTile(
          icon: Icons.lan_outlined,
          accentColor: accents[0],
          title: l10n.virtualLab,
          subtitle: l10n.networkPractice,
          onTap: () {
            context.push('/student/virtual-lab');
          },
        ),

        NlShortcutTile(
          icon: Icons.auto_awesome_rounded,
          accentColor: accents[2],
          title: 'NetBot AI',
          subtitle: isId ? 'Tutor Cerdas' : 'Smart AI Tutor',
          onTap: () {
            NlSnackBar.show(
              context,
              isId
                  ? 'Fitur NetBot AI masih dalam tahap pengembangan.'
                  : 'NetBot AI feature is currently under development.',
            );
          },
        ),

        NlShortcutTile(
          icon: Icons.speed_rounded,
          accentColor: accents[4],
          title: isId ? 'Subnet Drill' : 'Subnet Drill',
          subtitle: isId ? 'Tantangan 60s' : '60s Challenge',
          onTap: () {
            NlSnackBar.show(
              context,
              isId
                  ? 'Fitur Subnet Drill masih dalam tahap pengembangan.'
                  : 'Subnet Drill feature is currently under development.',
            );
          },
        ),
      ],
    );
  }

  /// "Recent Notifications" ΓÇö pratinjau dari sumber yang sama dengan halaman
  /// Notifikasi.
  ///
  /// Sebelumnya bagian ini selalu menampilkan keadaan kosong dengan alasan
  /// tidak ada provider notifikasi. Provider-nya sudah ada sejak halaman
  /// Notifikasi dibuat, jadi yang benar adalah membaca keduanya; keadaaan
  /// kosong tetap muncul apa adanya saat memang belum ada pengumuman maupun
  /// pengingat. Ketika id mahasiswa belum diketahui (baris dashboard masih
  /// dimuat atau gagal), tidak ada yang bisa dibaca dengan aman, jadi yang
  /// tampil kembali adalah keadaan kosong.
  Widget _buildNotifications(
    BuildContext context,
    AppLocalizations l10n,
    String? userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.recentNotifications),
        const SizedBox(height: NetLearnSpace.s12),
        if (userId == null)
          const _NotificationsEmpty()
        else
          _RecentNotificationsPreview(userId: userId),
      ],
    );
  }
}

/// Tombol ikon berbentuk kotak di dalam hero dashboard.
///
/// Di desain, lonceng Notifikasi dan tombol About NetLearn adalah kotak 35px
/// dengan gaya yang sama persis (latar putih 5%, garis putih 14%, radius 12),
/// jadi keduanya berbagi satu widget. [tooltip] sekaligus menjadi label
/// aksesibel karena ikonnya tidak membawa teks.
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? NetLearnColors.darkSurface : NetLearnColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? NetLearnColors.darkLine
                    : const Color(0xFFF1EDFC),
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0F1D1C21),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 19,
                color: isDark ? NetLearnColors.darkText : NetLearnColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar mahasiswa di hero, lengkap dengan titik status di pojok kanan bawah.
///
/// Titik hijau (`heroOnlineDot`) sengaja digambar di dalam [Stack] dengan
/// `clipBehavior: Clip.none`, bukan sebagai anak dari `Container` bulat:
/// lingkaran avatar memotong anaknya di tepi lengkung, sehingga titik yang
/// menempel di pojok kanan bawah akan terlihat terpangkas. Dengan `Stack` di
/// luar lingkaran, titik itu utuh di kedua tema.
class _DashboardAvatar extends StatelessWidget {
  final String? userId;
  final String initial;
  final AvatarConfig? avatarConfig;
  final VoidCallback onTap;

  const _DashboardAvatar({
    this.userId,
    required this.initial,
    this.avatarConfig,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 49,
      height: 49,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial.isNotEmpty ? initial : 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // `.avatar > span` — titik status hijau dengan cincin ungu. Tetap di
          // dalam kotak 49px supaya tidak pernah butuh ruang di luar Stack.
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: NetLearnColors.heroOnlineDot,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NetLearnColors.heroOnlineDotRing,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleProgressCard extends StatelessWidget {
  final StudentModule? module;
  final int moduleNumber;
  final List<MaterialModel> materials;
  final Set<String> completedMaterialIds;
  final VoidCallback onTap;

  const _ModuleProgressCard({
    required this.module,
    required this.moduleNumber,
    required this.materials,
    required this.completedMaterialIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final completed = materials
        .where(
          (material) =>
              completedMaterialIds.contains(material.id),
        )
        .length;

    final total = materials.length;

    final progress = total == 0 ? 0.0 : completed / total;

    final isUnlocked = module?.unlocked ?? false;

    // An unlocked module stays unlocked no matter how the progress rows look,
    // so a module the student is part-way through is never shown as a lock.
    final isCompleted =
        (module?.completed ?? false) ||
            (isUnlocked && total > 0 && completed == total);

    final moduleTitle = _moduleTitle(context, l10n);

    final status = _statusFor(
      l10n,
      isUnlocked: isUnlocked,
      isCompleted: isCompleted,
      completed: completed,
    );

    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(
        NetLearnRadius.card,
      ),
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            NetLearnSpace.s16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              NetLearnRadius.card,
            ),
            border: Border.all(
              color: context.border,
            ),
          ),
          child: Row(
            children: [
              _ModuleNumber(
                number: moduleNumber,
                locked: !isUnlocked,
                completed: isCompleted,
              ),
              const SizedBox(
                width: NetLearnSpace.s12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            moduleTitle,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: NetLearnSpace.s8,
                        ),
                        _ModuleStatusChip(
                          label: status.label,
                          tone: status.tone,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor:
                            NetLearnColors.neutralBg,
                        valueColor:
                            const AlwaysStoppedAnimation<
                                Color>(
                          NetLearnColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      l10n.moduleMaterialsCompleted(
                        completed,
                        total,
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: NetLearnSpace.s8,
              ),
              // Gembok modul hanya digambar sekali, di kotak nomor di depan
              // (`_ModuleNumber`). Ikon di ujung kanan dulu menggambar gembok
              // kedua kalinya untuk baris yang sama; sekarang hanya panah
              // "bisa dibuka" yang muncul, sehingga satu baris terkunci
              // membawa tepat satu gembok.
              if (isUnlocked)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: NetLearnColors.forest,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Module cards fall back to whatever title the module data carries; the
  /// per-module course titles are no longer hardcoded here because
  /// `studentModulesProvider` already localises them from the database.
  String _moduleTitle(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final moduleTitle = module?.title.trim() ?? '';

    if (moduleTitle.isNotEmpty) {
      return moduleTitle;
    }

    if (materials.isNotEmpty) {
      return materials.first.title;
    }

    return '${l10n.module} $moduleNumber';
  }

  _ModuleStatus _statusFor(
    AppLocalizations l10n, {
    required bool isUnlocked,
    required bool isCompleted,
    required int completed,
  }) {
    if (!isUnlocked) {
      return _ModuleStatus(
        label: l10n.locked,
        tone: _ModuleStatusTone.muted,
      );
    }

    if (isCompleted) {
      return _ModuleStatus(
        label: l10n.completed,
        tone: _ModuleStatusTone.positive,
      );
    }

    if (completed > 0) {
      return _ModuleStatus(
        label: l10n.inProgress,
        tone: _ModuleStatusTone.accent,
      );
    }

    return _ModuleStatus(
      label: l10n.unlocked,
      tone: _ModuleStatusTone.accent,
    );
  }
}

enum _ModuleStatusTone { muted, accent, positive }

class _ModuleStatus {
  final String label;
  final _ModuleStatusTone tone;

  const _ModuleStatus({
    required this.label,
    required this.tone,
  });
}

class _ModuleStatusChip extends StatelessWidget {
  final String label;
  final _ModuleStatusTone tone;

  const _ModuleStatusChip({
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    switch (tone) {
      case _ModuleStatusTone.positive:
        background = NetLearnColors.mintLight;
        foreground = NetLearnColors.forest;
        break;
      case _ModuleStatusTone.accent:
        background = context.accentTint;
        foreground = context.accent;
        break;
      case _ModuleStatusTone.muted:
        background = context.raisedSurface;
        foreground = context.mutedText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ModuleNumber extends StatelessWidget {
  final int number;
  final bool locked;
  final bool completed;

  const _ModuleNumber({
    required this.number,
    required this.locked,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;
    IconData? icon;

    if (completed) {
      background = NetLearnColors.mint;
      foreground = NetLearnColors.forest;
      icon = Icons.check_rounded;
    } else if (locked) {
      background = context.raisedSurface;
      foreground = context.mutedText;
      icon = Icons.lock_outline_rounded;
    } else {
      background = NetLearnColors.forest;
      foreground = context.surface;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(
              icon,
              color: foreground,
              size: 20,
            )
          : Text(
              number.toString().padLeft(2, '0'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                color: foreground,
                fontSize: 13,
              ),
            ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    // Tinggi mendekati panel ringkasan plus beberapa kartu modul supaya isi
    // halaman tidak melompat jauh saat data tiba.
    return const SizedBox(
      height: 240,
      child: Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProgressError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        NetLearnSpace.s16,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        border: Border.all(
          color: context.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.accent,
          ),
          const SizedBox(
            width: NetLearnSpace.s12,
          ),
          Expanded(
            child: Text(
              l10n.moduleProgressLoadError,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retry,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardErrorBanner({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        NetLearnSpace.s16,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        border: Border.all(
          color: context.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.accent,
          ),
          const SizedBox(
            width: NetLearnSpace.s12,
          ),
          Expanded(
            child: Text(
              l10n.dashboardLoadError,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retry,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyModules extends StatelessWidget {
  const _EmptyModules();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(
        NetLearnSpace.s20,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        border: Border.all(
          color: context.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 32,
            color: context.mutedText,
          ),
          const SizedBox(
            height: NetLearnSpace.s8,
          ),
          Text(
            l10n.noModules,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontSize: 12,
            ),
          ),
          const SizedBox(
            height: NetLearnSpace.s4,
          ),
          Text(
            l10n.noModulesDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong untuk "Recent Notifications", disamakan dengan dashboard
/// dosen supaya bagian ini tidak terlihat seperti elemen asing.
class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NetLearnSpace.s16,
        vertical: NetLearnSpace.s24,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        border: Border.all(
          color: context.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 28,
            color: context.mutedText,
          ),
          const SizedBox(
            height: NetLearnSpace.s8,
          ),
          Text(
            l10n.noNotifications,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris status Pretest / Posttest di "Learning Progress".
///
/// Sengaja dibuat seperti [_ModuleProgressCard] sesederhana mungkin: kotak
/// status di depan, judul dan keterangan di tengah, chip status di belakang.
/// Bedanya hanya isi kotak depan — ikon assessment saat bisa dibuka, centang
/// saat selesai, dan satu gembok saat alur masih menguncinya. Gembok itu
/// sengaja hanya digambar di kotak depan (tidak sekaligus di ujung kanan)
/// supaya satu baris terkunci membawa tepat satu gembok, sama seperti kartu
/// modul. Statusnya berasal dari `get_learning_flow_status`, bukan dari
/// hitungan materi di klien.
class _AssessmentProgressCard extends StatelessWidget {
  final String title;
  final String caption;
  final IconData icon;
  final bool locked;
  final bool completed;
  final VoidCallback onTap;

  const _AssessmentProgressCard({
    required this.title,
    required this.caption,
    required this.icon,
    required this.locked,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final _ModuleStatus status;

    if (locked) {
      status = _ModuleStatus(
        label: l10n.locked,
        tone: _ModuleStatusTone.muted,
      );
    } else if (completed) {
      status = _ModuleStatus(
        label: l10n.completed,
        tone: _ModuleStatusTone.positive,
      );
    } else {
      status = _ModuleStatus(
        label: l10n.unlocked,
        tone: _ModuleStatusTone.accent,
      );
    }

    // Prioritasnya sama dengan kartu modul: terkunci dulu, lalu selesai, baru
    // bisa dibuka. Satu nilai hanya masuk ke satu cabang sehingga tidak
    // mungkin muncul dua status sekaligus.
    final Color tileBackground;
    final Color tileForeground;
    final IconData tileIcon;

    if (locked) {
      tileBackground = context.raisedSurface;
      tileForeground = context.mutedText;
      tileIcon = Icons.lock_outline_rounded;
    } else if (completed) {
      tileBackground = NetLearnColors.mint;
      tileForeground = NetLearnColors.forest;
      tileIcon = Icons.check_rounded;
    } else {
      tileBackground = NetLearnColors.forest;
      tileForeground = context.surface;
      tileIcon = icon;
    }

    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(
        NetLearnRadius.card,
      ),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            NetLearnSpace.s16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              NetLearnRadius.card,
            ),
            border: Border.all(
              color: context.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tileBackground,
                  borderRadius: BorderRadius.circular(
                    NetLearnRadius.card,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  tileIcon,
                  color: tileForeground,
                  size: 20,
                ),
              ),
              const SizedBox(
                width: NetLearnSpace.s12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: NetLearnSpace.s8,
              ),
              _ModuleStatusChip(
                label: status.label,
                tone: status.tone,
              ),
              if (!locked) ...[
                const SizedBox(
                  width: NetLearnSpace.s8,
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: NetLearnColors.forest,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Isi satu baris pratinjau notifikasi, setelah dipilih dari pengumuman dan
/// pengingat yang nyata.
class _NotificationPreviewData {
  final IconData icon;
  final int tint;
  final String title;
  final String subtitle;

  const _NotificationPreviewData({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
  });
}

/// Pratinjau "Recent Notifications".
///
/// Membaca dua provider yang sama dengan halaman Notifikasi
/// (`userAnnouncementsProvider` dan `studentDeadlineRemindersProvider`),
/// sehingga bagian ini tidak mungkin menampilkan hal yang berbeda dari daftar
/// penuhnya. `NotificationPreview` di desain memakai dua baris contoh dan
/// tautan "Lihat Semua Notifikasi"; di sini barisnya adalah data mahasiswa
/// yang sebenarnya, dibatasi supaya tetap hanya sekilas.
class _RecentNotificationsPreview extends ConsumerWidget {
  final String userId;

  const _RecentNotificationsPreview({
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isIndonesian =
        Localizations.localeOf(context).languageCode == 'id';

    final announcementsAsync = ref.watch(
      userAnnouncementsProvider(userId),
    );

    final remindersAsync = ref.watch(
      studentDeadlineRemindersProvider(userId),
    );

    // Hanya pemuatan pertama yang menampilkan placeholder; penyegaran
    // berikutnya tetap memakai baris lama supaya bagian ini tidak berkedip.
    final isLoading = (announcementsAsync.isLoading ||
            remindersAsync.isLoading) &&
        !announcementsAsync.hasValue &&
        !remindersAsync.hasValue;

    if (isLoading) {
      return const _NotificationsPreviewSkeleton();
    }

    final announcements =
        announcementsAsync.value ?? const <AnnouncementModel>[];

    final reminders =
        remindersAsync.value ?? const <ReminderItem>[];

    if (reminders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LocalNotificationService.instance.syncDeadlineReminders(reminders);
      });
    }

    // Pengumuman dulu, baru pengingat, sama seperti desain. Dibatasi tiga
    // baris: daftar lengkapnya ada di halaman Notifikasi.
    final rows = <_NotificationPreviewData>[
      for (final announcement in announcements.take(2))
        _NotificationPreviewData(
          icon: Icons.campaign_rounded,
          tint: 0,
          title: announcement.title,
          subtitle: announcement.displayContent,
        ),
      for (final reminder in reminders.take(2))
        _NotificationPreviewData(
          icon: Icons.schedule_rounded,
          tint: 4,
          title: reminder.localizedTitle(isIndonesian),
          subtitle: reminder.subtitle(isIndonesian),
        ),
    ].take(3).toList();

    if (rows.isEmpty) {
      return const _NotificationsEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(
              NetLearnRadius.card,
            ),
            border: Border.all(
              color: context.border,
            ),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++)
                _NotificationPreviewRow(
                  data: rows[index],
                  showDivider: index < rows.length - 1,
                  onTap: () {
                    context.push('/student/notifications');
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: NetLearnSpace.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              context.push('/student/notifications');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: NetLearnSpace.s8,
              ),
              foregroundColor: context.accent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.viewAllNotifications),
                const SizedBox(width: NetLearnSpace.s4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Satu baris pratinjau.
///
/// Garis pemisah digambar di tepi bawah setiap baris kecuali baris terakhir,
/// jadi pratinjau tidak pernah diakhiri garis nyasar.
class _NotificationPreviewRow extends StatelessWidget {
  final _NotificationPreviewData data;
  final bool showDivider;
  final VoidCallback onTap;

  const _NotificationPreviewRow({
    required this.data,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: showDivider
                  ? BorderSide(color: context.border)
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NetLearnSpace.s16,
            vertical: NetLearnSpace.s12,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NetLearnAccents.tintBackgrounds[data.tint],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  data.icon,
                  size: 16,
                  color: NetLearnAccents.tintForegrounds[data.tint],
                ),
              ),
              const SizedBox(width: NetLearnSpace.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (data.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          fontSize: 10,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: NetLearnSpace.s8),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: context.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder statis saat pratinjau memuat pertama kali.
///
/// Sengaja tanpa animasi: tinggi yang tetap sudah cukup menjaga tata letak,
/// dan tidak ada spinner yang membuat `pumpAndSettle` menunggu selamanya.
class _NotificationsPreviewSkeleton extends StatelessWidget {
  const _NotificationsPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(
          NetLearnRadius.card,
        ),
        border: Border.all(
          color: context.border,
        ),
      ),
    );
  }
}

/// Memilih materi untuk tombol "Continue Learning".
///
/// Fungsi murni & bisa diuji offline: hanya membaca data yang sudah dipakai
/// kartu modul di dashboard — `StudentModule` (unlocked/completed) dari
/// `get_learning_flow_status` dan progres membaca+video per materi dari
/// `learning_progress` — jadi tidak ada sumber progres baru di sini.
///
/// Aturannya: modul pertama (urut nomor) yang terbuka dan belum tuntas adalah
/// titik lanjut; di dalamnya, materi pertama yang belum tuntas. Kalau modul
/// belum terbuka, punya `StudentModule`, atau sudah tuntas, ia dilewati.
/// `null` berarti tidak ada materi yang bisa dilanjutkan.
String? resolveContinueLearningMaterial({
  required List<int> moduleNumbers,
  required Map<int, StudentModule> moduleByNumber,
  required Map<int, List<MaterialModel>> grouped,
  required Set<String> completedMaterialIds,
}) {
  for (final moduleNumber in moduleNumbers) {
    final module = moduleByNumber[moduleNumber];

    // Tanpa `StudentModule` tidak ada sinyal unlock yang bisa dipercaya —
    // kartu modul di dashboard memperlakukannya terkunci juga.
    if (module == null || !module.unlocked || module.completed) {
      continue;
    }

    final moduleMaterials = grouped[moduleNumber] ?? const <MaterialModel>[];

    if (moduleMaterials.isEmpty) {
      continue;
    }

    // Materi pertama dalam modul yang belum tuntas (baca + video selesai).
    // Kalau semua materinya sudah tercatat tuntas tetapi modulnya belum,
    // kembali ke materi pertama modul — titik masuk yang sama dengan kartu
    // modul, sehingga kedua pintu tidak pernah membuka materi berbeda.
    for (final material in moduleMaterials) {
      if (!completedMaterialIds.contains(material.id)) {
        return material.id;
      }
    }

    return moduleMaterials.first.id;
  }

  return null;
}
