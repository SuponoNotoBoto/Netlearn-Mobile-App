import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/avatar/nl_avatar_models.dart';
import '../../../core/avatar/nl_avatar_widget.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/nl_skeleton.dart';
import '../../../shared/widgets/nl_surface_card.dart';
import '../../classes/class_controller.dart';
import '../../dashboard_student/student_dashboard_controller.dart';
import '../../profile/public_profile_sheet.dart';
import '../virtual_lab_leaderboard_models.dart';
import '../virtual_lab_leaderboard_service.dart';
import '../virtual_lab_mission_service.dart';

/// Modal bottom sheet dan widget tampilan Leaderboard Virtual Lab.
class VirtualLabLeaderboardSheet extends ConsumerStatefulWidget {
  final String? classId;
  final String? initialMissionId;

  const VirtualLabLeaderboardSheet({
    super.key,
    this.classId,
    this.initialMissionId,
  });

  static Future<void> show(
    BuildContext context, {
    String? classId,
    String? initialMissionId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VirtualLabLeaderboardSheet(
        classId: classId,
        initialMissionId: initialMissionId,
      ),
    );
  }

  @override
  ConsumerState<VirtualLabLeaderboardSheet> createState() =>
      _VirtualLabLeaderboardSheetState();
}

class _VirtualLabLeaderboardSheetState
    extends ConsumerState<VirtualLabLeaderboardSheet> {
  // 'overall', 'p2p', 'star', 'dual_subnet', 'dhcp_server'
  late String _selectedMission;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _selectedMission =
        VirtualLabLeaderboardService.normalizeMissionKey(widget.initialMissionId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExistingScores());
  }

  Future<void> _syncExistingScores() async {
    try {
      final submissions =
          await ref.read(virtualLabMissionServiceProvider).getSubmissions();
      if (submissions.isEmpty) return;

      final activeClass = ref.read(activeStudentClassProvider).value ??
          await resolveActiveStudentClass(ref);
      final classId = widget.classId ??
          ((activeClass != null && !activeClass.isLegacyFallback)
              ? activeClass.id
              : null);

      String studentName =
          ref.read(studentDashboardProvider).value?.userName.trim() ?? '';
      if (studentName.isEmpty) {
        final uid = supabase.auth.currentUser?.id;
        if (uid != null) {
          try {
            final prof = await supabase
                .from('profiles')
                .select('name')
                .eq('id', uid)
                .maybeSingle();
            studentName = prof?['name']?.toString().trim() ?? '';
          } catch (_) {}
        }
      }

      await VirtualLabLeaderboardService.syncSubmissions(
        submissions: submissions,
        classId: classId,
        studentName: studentName.isEmpty ? 'Mahasiswa' : studentName,
      );
      if (mounted) {
        setState(() => _refreshTick++);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEn = ref.watch(languageProvider).languageCode == 'en';
    final activeClass = ref.watch(activeStudentClassProvider).value;
    final fallbackClassId =
        (activeClass != null && !activeClass.isLegacyFallback)
            ? activeClass.id
            : null;
    final resolvedClassId = (widget.classId != null &&
            widget.classId!.isNotEmpty)
        ? widget.classId
        : fallbackClassId;

    final missions = [
      (
        key: 'overall',
        label: isEn ? 'All Missions' : 'Semua Misi (Akumulasi)',
      ),
      (
        key: 'p2p',
        label: isEn ? 'Mod 1: P2P' : 'Modul 1: Topologi P2P',
      ),
      (
        key: 'star',
        label: isEn ? 'Mod 2: Star LAN' : 'Modul 2: Star LAN',
      ),
      (
        key: 'dual_subnet',
        label: isEn ? 'Mod 3: Routing' : 'Modul 3: Routing & Gateway',
      ),
      (
        key: 'dhcp_server',
        label: isEn ? 'Mod 4: Server' : 'Modul 4: Server DHCP',
      ),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C29) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn
                            ? 'Virtual Lab Leaderboard'
                            : 'Leaderboard Virtual Lab',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isEn
                            ? 'Practical mission scores & rankings'
                            : 'Peringkat & skor misi praktikum jaringan',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? NetLearnColors.darkMuted
                              : const Color(0xFF787489),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isEn ? 'Refresh' : 'Muat Ulang',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    setState(() => _refreshTick++);
                    _syncExistingScores();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: missions.map((m) {
                final isSelected = _selectedMission == m.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('vlab_mission_tab_${m.key}'),
                    label: Text(m.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedMission = m.key),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Body Content
          Expanded(
            child: _selectedMission == 'overall'
                ? _OverallVirtualLabList(
                    key: ValueKey('overall_${resolvedClassId ?? "global"}_$_refreshTick'),
                    classId: resolvedClassId,
                    isDark: isDark,
                    isEn: isEn,
                  )
                : _MissionSpecificVirtualLabList(
                    key: ValueKey('${_selectedMission}_${resolvedClassId ?? "global"}_$_refreshTick'),
                    classId: resolvedClassId,
                    missionKey: _selectedMission,
                    isDark: isDark,
                    isEn: isEn,
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverallVirtualLabList extends StatelessWidget {
  final String? classId;
  final bool isDark;
  final bool isEn;

  const _OverallVirtualLabList({
    super.key,
    required this.classId,
    required this.isDark,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VirtualLabOverallScore>>(
      future: VirtualLabLeaderboardService.getOverallScores(classId: classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const NlSkeletonList(
            itemCount: 4,
            padding: EdgeInsets.all(AppSpacing.s20),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.biotech_outlined,
                    size: 48,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? 'No Virtual Lab scores recorded yet'
                        : 'Belum ada skor praktikum Virtual Lab',
                    style: AppTypography.cardTitle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Complete and submit practical missions in the Virtual Lab to appear on the leaderboard.'
                        : 'Selesaikan dan kumpulkan misi praktikum di Virtual Lab untuk mulai masuk ke papan peringkat.',
                    style: AppTypography.body(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        String? currentUid;
        try {
          currentUid = supabase.auth.currentUser?.id;
        } catch (_) {}

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Top 3 Podium if >= 2 entries
            if (list.length >= 2) ...[
              _buildPodium(context, list),
              const SizedBox(height: 16),
            ],

            Text(
              isEn ? 'All Rankings' : 'Seluruh Peringkat',
              style: AppTypography.sectionTitle(context),
            ),
            const SizedBox(height: 8),

            for (var i = 0; i < list.length; i++) ...[
              _buildRow(context, list[i], i + 1, currentUid),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPodium(BuildContext context, List<VirtualLabOverallScore> list) {
    final first = list.isNotEmpty ? list[0] : null;
    final second = list.length > 1 ? list[1] : null;
    final third = list.length > 2 ? list[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NetLearnColors.darkSurface : const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? NetLearnColors.darkLine : const Color(0xFFEBE7F5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Silver
          if (second != null)
            _podiumColumn(context, second, 2, const Color(0xFF64748B), 88)
          else
            const SizedBox(width: 72),

          // #1 Gold
          if (first != null)
            _podiumColumn(context, first, 1, const Color(0xFFD97706), 110)
          else
            const SizedBox(width: 72),

          // #3 Bronze
          if (third != null)
            _podiumColumn(context, third, 3, const Color(0xFFB45309), 74)
          else
            const SizedBox(width: 72),
        ],
      ),
    );
  }

  Widget _podiumColumn(
    BuildContext context,
    VirtualLabOverallScore entry,
    int rank,
    Color color,
    double height,
  ) {
    final avatar = entry.avatarConfig ??
        AvatarConfig.defaultFor(
          entry.studentId.isNotEmpty ? entry.studentId : entry.studentName,
        );

    final crown = rank == 1 ? '👑' : (rank == 2 ? '🥈' : '🥉');

    return GestureDetector(
      onTap: () => showPublicProfileSheet(
        context,
        userId: entry.studentId,
        classId: classId,
        fallbackName: entry.studentName,
        fallbackAvatar: avatar,
        fallbackPoints: entry.totalScore.toDouble(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(crown, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          NlAvatarWidget(config: avatar, size: 40, borderWidth: 2),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Text(
              entry.studentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${entry.totalScore} PTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 72,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    VirtualLabOverallScore entry,
    int rank,
    String? currentUid,
  ) {
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
      key: Key('vlab_leaderboard_row_${entry.studentId}'),
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
            child: Text(
              '#$rank',
              style: AppTypography.cardTitle(context).copyWith(
                color: rankColor,
                fontSize: 13,
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
                          isEn ? 'You' : 'Anda',
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
                  '${entry.completedMissions}/${entry.totalAvailableMissions} ${isEn ? 'Missions' : 'Misi'} · Avg: ${entry.averageScore.toStringAsFixed(1)}',
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
                '${entry.totalScore} PTS',
                style: AppTypography.sectionTitle(context).copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                '${entry.completedMissions} tuntas',
                style: AppTypography.caption(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionSpecificVirtualLabList extends StatelessWidget {
  final String? classId;
  final String missionKey;
  final bool isDark;
  final bool isEn;

  const _MissionSpecificVirtualLabList({
    super.key,
    required this.classId,
    required this.missionKey,
    required this.isDark,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VirtualLabScore>>(
      future: VirtualLabLeaderboardService.getScoresByMission(
        missionKey: missionKey,
        classId: classId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const NlSkeletonList(
            itemCount: 4,
            padding: EdgeInsets.all(AppSpacing.s20),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? 'No submissions for this mission yet'
                        : 'Belum ada pengumpulan untuk misi ini',
                    style: AppTypography.cardTitle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Be the first to complete this practical mission!'
                        : 'Jadilah mahasiswa pertama yang menuntaskan misi praktikum ini!',
                    style: AppTypography.body(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        String? currentUid;
        try {
          currentUid = supabase.auth.currentUser?.id;
        } catch (_) {}

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final entry = list[i];
            final rank = i + 1;
            final rankColor = switch (rank) {
              1 => const Color(0xFFD97706),
              2 => const Color(0xFF64748B),
              3 => const Color(0xFFB45309),
              _ => AppColors.primaryBlue,
            };
            final avatar = entry.avatarConfig ??
                AvatarConfig.defaultFor(
                  entry.studentId.isNotEmpty
                      ? entry.studentId
                      : entry.studentName,
                );
            final isMe = currentUid != null && currentUid == entry.studentId;

            return NlSurfaceCard(
              key: Key('vlab_mission_score_row_${entry.studentId}'),
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
                    child: Text(
                      '#$rank',
                      style: AppTypography.cardTitle(context).copyWith(
                        color: rankColor,
                        fontSize: 13,
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
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.rPill),
                                ),
                                child: Text(
                                  isEn ? 'You' : 'Anda',
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
                          '${entry.completedTasks}/${entry.totalTasks} ${isEn ? 'Tasks Completed' : 'Tugas Selesai'}${entry.isPassed ? ' · Lulus ✅' : ''}',
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    '${entry.score} pts',
                    style: AppTypography.sectionTitle(context).copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
