import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_surface_card.dart';
import '../profile/public_profile_sheet.dart';
import '../subnet_drill/subnet_drill_leaderboard.dart';
import '../virtual_lab/virtual_lab_leaderboard_models.dart';
import '../virtual_lab/virtual_lab_leaderboard_service.dart';
import 'class_controller.dart';
import 'class_models.dart';

class ClassLeaderboardPage extends ConsumerWidget {
  const ClassLeaderboardPage({
    super.key,
    this.classId,
  });

  final String? classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedClassId = classId ??
        ref.watch(activeStudentClassProvider).value?.id ??
        ref.watch(activeLecturerClassProvider).value?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboardTitle),
      ),
      body: SafeArea(
        child: resolvedClassId == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: Text(
                    l10n.leaderboardEmptyTitle,
                    style: AppTypography.cardTitle(context),
                  ),
                ),
              )
            : ClassLeaderboardView(classId: resolvedClassId),
      ),
    );
  }
}

class ClassLeaderboardView extends ConsumerStatefulWidget {
  const ClassLeaderboardView({
    super.key,
    required this.classId,
  });

  final String classId;

  @override
  ConsumerState<ClassLeaderboardView> createState() =>
      _ClassLeaderboardViewState();
}

class _ClassLeaderboardViewState extends ConsumerState<ClassLeaderboardView> {
  int _selectedMode = 0; // 0 = Overall Class, 1 = Per Assessment, 2 = Subnet Drill, 3 = Virtual Lab
  String? _selectedQuizId;
  String _selectedVLabMission = 'overall';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              ChoiceChip(
                key: const Key('leaderboard_tab_overall'),
                label: Text(l10n.leaderboardOverallTab),
                selected: _selectedMode == 0,
                onSelected: (_) => setState(() => _selectedMode = 0),
              ),
              ChoiceChip(
                key: const Key('leaderboard_tab_assessment'),
                label: Text(l10n.leaderboardAssessmentTab),
                selected: _selectedMode == 1,
                onSelected: (_) => setState(() => _selectedMode = 1),
              ),
              ChoiceChip(
                key: const Key('leaderboard_tab_subnet_drill'),
                label: const Text('Subnet Drill'),
                selected: _selectedMode == 2,
                onSelected: (_) => setState(() => _selectedMode = 2),
              ),
              ChoiceChip(
                key: const Key('leaderboard_tab_virtual_lab'),
                label: const Text('Virtual Lab'),
                selected: _selectedMode == 3,
                onSelected: (_) => setState(() => _selectedMode = 3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          NlSurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Text(
                    _selectedMode == 3
                        ? (isId
                            ? 'Peringkat skor penyelesaian misi praktikum Virtual Lab di materi kelas · Ketuk mahasiswa untuk melihat profil publik.'
                            : 'Class Virtual Lab practical mission completion scores · Tap a student to view public profile.')
                        : _selectedMode == 2
                            ? (isId
                                ? 'Skor tertinggi & rekor beruntun latihan Subnet Drill kelas · Ketuk mahasiswa untuk melihat profil publik.'
                                : 'Class Subnet Drill highest scores & max streaks · Tap a student to view public profile.')
                            : l10n.leaderboardFormulaNote,
                    style: AppTypography.caption(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (_selectedMode == 0)
            _OverallClassLeaderboardSection(classId: widget.classId)
          else if (_selectedMode == 1)
            _AssessmentLeaderboardSection(
              classId: widget.classId,
              selectedQuizId: _selectedQuizId,
              onSelectQuiz: (id) => setState(() => _selectedQuizId = id),
            )
          else if (_selectedMode == 2)
            _SubnetDrillLeaderboardSection(classId: widget.classId)
          else
            _ClassVirtualLabLeaderboardSection(
              classId: widget.classId,
              selectedMission: _selectedVLabMission,
              onSelectMission: (m) => setState(() => _selectedVLabMission = m),
            ),
        ],
      ),
    );
  }
}

class _OverallClassLeaderboardSection extends ConsumerWidget {
  const _OverallClassLeaderboardSection({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(classLeaderboardProvider(classId));

    return entriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.s24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => NlSurfaceCard(
        child: Text(
          l10n.couldNotLoadData,
          style: AppTypography.body(context),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return NlSurfaceCard(
            key: const Key('leaderboard_empty_card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.leaderboardEmptyTitle,
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  l10n.leaderboardEmptyMessage,
                  style: AppTypography.body(context),
                ),
              ],
            ),
          );
        }

        final finalCohort =
            entries.where((e) => e.isFinal).toList(growable: false);
        final provisionalCohort =
            entries.where((e) => !e.isFinal).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (finalCohort.isNotEmpty) ...[
              Text(
                l10n.leaderboardCohortFinal,
                style: AppTypography.sectionTitle(context),
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final entry in finalCohort) ...[
                _OverallLeaderboardRow(entry: entry, classId: classId),
                const SizedBox(height: AppSpacing.s8),
              ],
              const SizedBox(height: AppSpacing.s12),
            ],
            if (provisionalCohort.isNotEmpty) ...[
              Text(
                l10n.leaderboardCohortProvisional,
                style: AppTypography.sectionTitle(context),
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final entry in provisionalCohort) ...[
                _OverallLeaderboardRow(entry: entry, classId: classId),
                const SizedBox(height: AppSpacing.s8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _OverallLeaderboardRow extends StatelessWidget {
  const _OverallLeaderboardRow({
    required this.entry,
    required this.classId,
  });

  final ClassLeaderboardEntry entry;
  final String classId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rankColor = switch (entry.rankPosition) {
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF64748B),
      3 => const Color(0xFFB45309),
      _ => AppColors.primaryBlue,
    };
    final avatar = entry.avatarConfig ??
        AvatarConfig.defaultFor(
          entry.studentId.isNotEmpty ? entry.studentId : entry.displayName,
        );

    return NlSurfaceCard(
      key: Key('class_leaderboard_row_${entry.studentId}'),
      onTap: () => showPublicProfileSheet(
        context,
        userId: entry.studentId,
        classId: classId,
        fallbackName: entry.displayName,
        fallbackAvatar: avatar,
        fallbackPoints: entry.weightedScore,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '#${entry.rankPosition}',
                style: AppTypography.cardTitle(context).copyWith(
                  color: rankColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          NlAvatarWidget(
            config: avatar,
            size: 38,
            borderWidth: 2,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(context).copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: AppSpacing.s6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(AppRadius.rPill),
                        ),
                        child: Text(
                          l10n.leaderboardYouBadge,
                          style: AppTypography.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.completedAssessments}/${entry.totalRankedAssessments} ${l10n.assessments}'
                  '${entry.identityNumber != null ? ' · ${entry.identityNumber}' : ''}',
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.weightedScore.round()} PTS',
                style: AppTypography.sectionTitle(context).copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                'Avg: ${entry.unweightedAvg.toStringAsFixed(1)}',
                style: AppTypography.caption(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssessmentLeaderboardSection extends ConsumerWidget {
  const _AssessmentLeaderboardSection({
    required this.classId,
    required this.selectedQuizId,
    required this.onSelectQuiz,
  });

  final String classId;
  final String? selectedQuizId;
  final ValueChanged<String> onSelectQuiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider).languageCode;
    final quizzesAsync = ref.watch(classLeaderboardQuizzesProvider(classId));

    return quizzesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(l10n.couldNotLoadData),
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return NlSurfaceCard(
            child: Text(l10n.leaderboardEmptyTitle),
          );
        }

        final activeQuizId = (selectedQuizId != null &&
                quizzes.any((q) => q.id == selectedQuizId))
            ? selectedQuizId!
            : quizzes.first.id;
        final boardAsync = ref.watch(
          assessmentLeaderboardProvider(
            (classId: classId, quizId: activeQuizId),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final q in quizzes)
                  ChoiceChip(
                    key: Key('assessment_leaderboard_chip_${q.id}'),
                    label: Text(q.localizedTitle(lang)),
                    selected: q.id == activeQuizId,
                    onSelected: (_) => onSelectQuiz(q.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            boardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.couldNotLoadData),
              data: (entries) {
                if (entries.isEmpty) {
                  return NlSurfaceCard(
                    child: Text(
                      l10n.leaderboardEmptyMessage,
                      style: AppTypography.body(context),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final entry in entries) ...[
                      _AssessmentLeaderboardRow(
                        entry: entry,
                        classId: classId,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AssessmentLeaderboardRow extends StatelessWidget {
  const _AssessmentLeaderboardRow({
    required this.entry,
    required this.classId,
  });

  final AssessmentLeaderboardEntry entry;
  final String classId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rankColor = switch (entry.rankPosition) {
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF64748B),
      3 => const Color(0xFFB45309),
      _ => AppColors.primaryBlue,
    };
    final avatar = entry.avatarConfig ??
        AvatarConfig.defaultFor(
          entry.studentId.isNotEmpty ? entry.studentId : entry.displayName,
        );

    return NlSurfaceCard(
      key: Key('assessment_leaderboard_row_${entry.studentId}'),
      onTap: () => showPublicProfileSheet(
        context,
        userId: entry.studentId,
        classId: classId,
        fallbackName: entry.displayName,
        fallbackAvatar: avatar,
        fallbackPoints: entry.bestScore,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '#${entry.rankPosition}',
                style: AppTypography.cardTitle(context).copyWith(
                  color: rankColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          NlAvatarWidget(
            config: avatar,
            size: 38,
            borderWidth: 2,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(context).copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: AppSpacing.s6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(AppRadius.rPill),
                        ),
                        child: Text(
                          l10n.leaderboardYouBadge,
                          style: AppTypography.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.identityNumber != null)
                  Text(
                    entry.identityNumber!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(context),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            entry.bestScore.toStringAsFixed(1),
            style: AppTypography.sectionTitle(context).copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubnetDrillLeaderboardSection extends StatefulWidget {
  const _SubnetDrillLeaderboardSection({required this.classId});

  final String classId;

  @override
  State<_SubnetDrillLeaderboardSection> createState() =>
      _SubnetDrillLeaderboardSectionState();
}

class _SubnetDrillLeaderboardSectionState
    extends State<_SubnetDrillLeaderboardSection> {
  late Future<List<SubnetDrillScore>> _future;

  @override
  void initState() {
    super.initState();
    _future = SubnetDrillLeaderboardService.getTopScores(classId: widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return FutureBuilder<List<SubnetDrillScore>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final scores = snapshot.data ?? [];
        if (scores.isEmpty) {
          return NlSurfaceCard(
            key: const Key('subnet_drill_leaderboard_empty'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isId
                      ? 'Belum ada skor Subnet Drill'
                      : 'No Subnet Drill scores yet',
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  isId
                      ? 'Peringkat akan muncul setelah mahasiswa berlatih Subnet Drill di kelas ini.'
                      : 'Rankings will appear once students practice Subnet Drill in this class.',
                  style: AppTypography.body(context),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < scores.length; i++) ...[
              _SubnetDrillLeaderboardRow(
                rank: i + 1,
                score: scores[i],
                classId: widget.classId,
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ],
        );
      },
    );
  }
}

class _SubnetDrillLeaderboardRow extends StatelessWidget {
  const _SubnetDrillLeaderboardRow({
    required this.rank,
    required this.score,
    required this.classId,
  });

  final int rank;
  final SubnetDrillScore score;
  final String classId;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF64748B),
      3 => const Color(0xFFB45309),
      _ => AppColors.primaryBlue,
    };

    final avatar = score.avatarConfig ??
        AvatarConfig.defaultFor(
          score.studentId.isNotEmpty ? score.studentId : score.studentName,
        );

    String? currentUid;
    try {
      currentUid = supabase.auth.currentUser?.id;
    } catch (_) {}
    final isMe = currentUid != null && currentUid == score.studentId;

    return NlSurfaceCard(
      key: Key('subnet_drill_leaderboard_row_${score.studentId}'),
      onTap: () => showPublicProfileSheet(
        context,
        userId: score.studentId,
        classId: classId,
        fallbackName: score.studentName,
        fallbackAvatar: avatar,
        fallbackPoints: score.score.toDouble(),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '#$rank',
                style: AppTypography.cardTitle(context).copyWith(
                  color: rankColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          NlAvatarWidget(
            config: avatar,
            size: 38,
            borderWidth: 2,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        score.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(context).copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.s6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(AppRadius.rPill),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.leaderboardYouBadge,
                          style: AppTypography.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Streak: ${score.maxStreak}x',
                  style: AppTypography.caption(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            '${score.score} pts',
            style: AppTypography.cardTitle(context).copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassVirtualLabLeaderboardSection extends StatelessWidget {
  final String classId;
  final String selectedMission;
  final ValueChanged<String> onSelectMission;

  const _ClassVirtualLabLeaderboardSection({
    required this.classId,
    required this.selectedMission,
    required this.onSelectMission,
  });

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    final missions = [
      (
        key: 'overall',
        label: isId ? 'Semua Misi (Akumulasi)' : 'All Missions',
      ),
      (
        key: 'p2p',
        label: isId ? 'Modul 1: P2P' : 'Mod 1: P2P',
      ),
      (
        key: 'star',
        label: isId ? 'Modul 2: Star LAN' : 'Mod 2: Star LAN',
      ),
      (
        key: 'dual_subnet',
        label: isId ? 'Modul 3: Routing' : 'Mod 3: Routing',
      ),
      (
        key: 'dhcp_server',
        label: isId ? 'Modul 4: Server' : 'Mod 4: Server',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: missions.map((m) {
            return ChoiceChip(
              key: Key('class_vlab_mission_chip_${m.key}'),
              label: Text(m.label),
              selected: selectedMission == m.key,
              onSelected: (_) => onSelectMission(m.key),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.s12),
        if (selectedMission == 'overall')
          _ClassVirtualLabOverallList(classId: classId)
        else
          _ClassVirtualLabMissionList(
            classId: classId,
            missionKey: selectedMission,
          ),
      ],
    );
  }
}

class _ClassVirtualLabOverallList extends StatelessWidget {
  final String classId;

  const _ClassVirtualLabOverallList({required this.classId});

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return FutureBuilder<List<VirtualLabOverallScore>>(
      future: VirtualLabLeaderboardService.getOverallScores(classId: classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return NlSurfaceCard(
            key: const Key('virtual_lab_leaderboard_empty'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isId
                      ? 'Belum ada skor praktikum Virtual Lab'
                      : 'No Virtual Lab scores yet',
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  isId
                      ? 'Peringkat akan muncul setelah mahasiswa menyelesaikan misi praktikum di kelas ini.'
                      : 'Rankings will appear once students complete practical missions in this class.',
                  style: AppTypography.body(context),
                ),
              ],
            ),
          );
        }

        String? currentUid;
        try {
          currentUid = supabase.auth.currentUser?.id;
        } catch (_) {}

        return Column(
          children: [
            for (var i = 0; i < list.length; i++) ...[
              _ClassVirtualLabOverallRow(
                rank: i + 1,
                entry: list[i],
                classId: classId,
                currentUid: currentUid,
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ],
        );
      },
    );
  }
}

class _ClassVirtualLabOverallRow extends StatelessWidget {
  final int rank;
  final VirtualLabOverallScore entry;
  final String classId;
  final String? currentUid;

  const _ClassVirtualLabOverallRow({
    required this.rank,
    required this.entry,
    required this.classId,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final rankColor = switch (rank) {
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF64748B),
      3 => const Color(0xFFB45309),
      _ => AppColors.primaryBlue,
    };

    final avatar = entry.avatarConfig ??
        AvatarConfig.defaultFor(
          entry.studentId.isNotEmpty ? entry.studentId : entry.studentName,
        );

    final isMe = currentUid != null && currentUid == entry.studentId;

    return NlSurfaceCard(
      key: Key('class_vlab_overall_row_${entry.studentId}'),
      onTap: () => showPublicProfileSheet(
        context,
        userId: entry.studentId,
        classId: classId,
        fallbackName: entry.studentName,
        fallbackAvatar: avatar,
        fallbackPoints: entry.totalScore.toDouble(),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '#$rank',
                style: AppTypography.cardTitle(context).copyWith(
                  color: rankColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          NlAvatarWidget(config: avatar, size: 38, borderWidth: 2),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(context).copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.s6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(AppRadius.rPill),
                        ),
                        child: Text(
                          l10n.leaderboardYouBadge,
                          style: AppTypography.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.completedMissions}/${entry.totalAvailableMissions} ${isId ? 'Misi Selesai' : 'Missions'} · Avg: ${entry.averageScore.toStringAsFixed(1)}',
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            '${entry.totalScore} PTS',
            style: AppTypography.sectionTitle(context).copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassVirtualLabMissionList extends StatelessWidget {
  final String classId;
  final String missionKey;

  const _ClassVirtualLabMissionList({
    required this.classId,
    required this.missionKey,
  });

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return FutureBuilder<List<VirtualLabScore>>(
      future: VirtualLabLeaderboardService.getScoresByMission(
        missionKey: missionKey,
        classId: classId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return NlSurfaceCard(
            key: const Key('virtual_lab_mission_leaderboard_empty'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isId
                      ? 'Belum ada pengumpulan untuk misi ini'
                      : 'No submissions for this mission yet',
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  isId
                      ? 'Peringkat akan muncul setelah mahasiswa mengumpulkan praktikum modul ini.'
                      : 'Rankings will appear once students submit this module practical.',
                  style: AppTypography.body(context),
                ),
              ],
            ),
          );
        }

        String? currentUid;
        try {
          currentUid = supabase.auth.currentUser?.id;
        } catch (_) {}

        return Column(
          children: [
            for (var i = 0; i < list.length; i++) ...[
              _ClassVirtualLabMissionRow(
                rank: i + 1,
                entry: list[i],
                classId: classId,
                currentUid: currentUid,
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ],
        );
      },
    );
  }
}

class _ClassVirtualLabMissionRow extends StatelessWidget {
  final int rank;
  final VirtualLabScore entry;
  final String classId;
  final String? currentUid;

  const _ClassVirtualLabMissionRow({
    required this.rank,
    required this.entry,
    required this.classId,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final rankColor = switch (rank) {
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF64748B),
      3 => const Color(0xFFB45309),
      _ => AppColors.primaryBlue,
    };

    final avatar = entry.avatarConfig ??
        AvatarConfig.defaultFor(
          entry.studentId.isNotEmpty ? entry.studentId : entry.studentName,
        );

    final isMe = currentUid != null && currentUid == entry.studentId;

    return NlSurfaceCard(
      key: Key('class_vlab_mission_row_${entry.studentId}'),
      onTap: () => showPublicProfileSheet(
        context,
        userId: entry.studentId,
        classId: classId,
        fallbackName: entry.studentName,
        fallbackAvatar: avatar,
        fallbackPoints: entry.score.toDouble(),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '#$rank',
                style: AppTypography.cardTitle(context).copyWith(
                  color: rankColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          NlAvatarWidget(config: avatar, size: 38, borderWidth: 2),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle(context).copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.s6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(AppRadius.rPill),
                        ),
                        child: Text(
                          l10n.leaderboardYouBadge,
                          style: AppTypography.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.completedTasks}/${entry.totalTasks} ${isId ? 'Tugas Selesai' : 'Tasks'}${entry.isPassed ? ' · Lulus' : ''}',
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            '${entry.score} pts',
            style: AppTypography.cardTitle(context).copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}


