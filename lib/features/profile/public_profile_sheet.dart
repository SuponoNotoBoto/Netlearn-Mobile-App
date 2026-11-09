import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../achievements/achievement_service.dart';

class PublicMemberProfile {
  final String userId;
  final String displayName;
  final String role;
  final String? program;
  final String? identityNumber;
  final String? bio;
  final AvatarConfig? avatarConfig;
  final Set<String> unlockedBadges;
  final double totalPoints;
  final int completedAssessments;
  final int subnetBestScore;
  final int cheersCount;
  final bool cheeredToday;
  final bool isMe;

  const PublicMemberProfile({
    required this.userId,
    required this.displayName,
    this.role = 'student',
    this.program,
    this.identityNumber,
    this.bio,
    this.avatarConfig,
    this.unlockedBadges = const <String>{},
    this.totalPoints = 0,
    this.completedAssessments = 0,
    this.subnetBestScore = 0,
    this.cheersCount = 0,
    this.cheeredToday = false,
    this.isMe = false,
  });

  bool get isLecturer => role == 'lecturer';

  PublicMemberProfile copyWith({
    int? cheersCount,
    bool? cheeredToday,
  }) {
    return PublicMemberProfile(
      userId: userId,
      displayName: displayName,
      role: role,
      program: program,
      identityNumber: identityNumber,
      bio: bio,
      avatarConfig: avatarConfig,
      unlockedBadges: unlockedBadges,
      totalPoints: totalPoints,
      completedAssessments: completedAssessments,
      subnetBestScore: subnetBestScore,
      cheersCount: cheersCount ?? this.cheersCount,
      cheeredToday: cheeredToday ?? this.cheeredToday,
      isMe: isMe,
    );
  }

  factory PublicMemberProfile.fromMap(Map<String, dynamic> map) {
    final rawBadges = map['unlocked_badges'];
    final badges = <String>{};
    if (rawBadges is List) {
      for (final item in rawBadges) {
        final s = item?.toString().trim() ?? '';
        if (s.isNotEmpty) badges.add(s);
      }
    }

    final cleanBio = map['bio']?.toString().trim();
    final cleanIdNum = map['identity_number']?.toString().trim();
    final cleanProgram = map['program']?.toString().trim();

    return PublicMemberProfile(
      userId: map['user_id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? 'Mahasiswa',
      role: map['role']?.toString() ?? 'student',
      program: (cleanProgram == null || cleanProgram.isEmpty)
          ? null
          : cleanProgram,
      identityNumber:
          (cleanIdNum == null || cleanIdNum.isEmpty) ? null : cleanIdNum,
      bio: (cleanBio == null || cleanBio.isEmpty) ? null : cleanBio,
      avatarConfig: AvatarConfig.fromDynamic(map['avatar_config']),
      unlockedBadges: badges,
      totalPoints: (map['total_points'] as num?)?.toDouble() ?? 0,
      completedAssessments:
          (map['completed_assessments'] as num?)?.toInt() ?? 0,
      subnetBestScore: (map['subnet_best_score'] as num?)?.toInt() ?? 0,
      cheersCount: (map['cheers_count'] as num?)?.toInt() ?? 0,
      cheeredToday: map['cheered_today'] == true,
      isMe: map['is_me'] == true,
    );
  }
}

/// Shows the Classroom Social Public Profile Bottom Sheet for any classmate or lecturer.
Future<void> showPublicProfileSheet(
  BuildContext context, {
  required String userId,
  String? classId,
  String? fallbackName,
  AvatarConfig? fallbackAvatar,
  String? fallbackRole,
  double? fallbackPoints,
  PublicMemberProfile? mockProfile,
}) {
  if (userId.trim().isEmpty && mockProfile == null) {
    return Future.value();
  }
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => _PublicProfileSheet(
      userId: userId,
      classId: classId,
      fallbackName: fallbackName,
      fallbackAvatar: fallbackAvatar,
      fallbackRole: fallbackRole,
      fallbackPoints: fallbackPoints,
      mockProfile: mockProfile,
    ),
  );
}

class _PublicProfileSheet extends StatefulWidget {
  final String userId;
  final String? classId;
  final String? fallbackName;
  final AvatarConfig? fallbackAvatar;
  final String? fallbackRole;
  final double? fallbackPoints;
  final PublicMemberProfile? mockProfile;

  const _PublicProfileSheet({
    required this.userId,
    this.classId,
    this.fallbackName,
    this.fallbackAvatar,
    this.fallbackRole,
    this.fallbackPoints,
    this.mockProfile,
  });

  @override
  State<_PublicProfileSheet> createState() => _PublicProfileSheetState();
}

class _PublicProfileSheetState extends State<_PublicProfileSheet> {
  PublicMemberProfile? _profile;
  bool _loading = true;
  bool _sendingCheer = false;

  @override
  void initState() {
    super.initState();
    if (widget.mockProfile != null) {
      _profile = widget.mockProfile;
      _loading = false;
    } else {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final validClassUuid = (widget.classId != null &&
              RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(widget.classId!))
          ? widget.classId
          : null;

      final dynamic res = await supabase.rpc(
        'get_public_member_profile',
        params: {
          'p_user': widget.userId,
          'p_class': validClassUuid,
        },
      );

      Map<String, dynamic>? row;
      if (res is List && res.isNotEmpty) {
        row = Map<String, dynamic>.from(res.first as Map);
      } else if (res is Map) {
        row = Map<String, dynamic>.from(res);
      }

      if (!mounted) return;
      if (row != null) {
        setState(() {
          _profile = PublicMemberProfile.fromMap(row!);
          _loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('get_public_member_profile fallback: $e');
    }

    if (!mounted) return;
    final myUid = _tryCurrentUserId();
    setState(() {
      _profile = PublicMemberProfile(
        userId: widget.userId,
        displayName: widget.fallbackName ?? 'Mahasiswa',
        role: widget.fallbackRole ?? 'student',
        avatarConfig: widget.fallbackAvatar,
        totalPoints: widget.fallbackPoints ?? 0,
        isMe: myUid != null && myUid == widget.userId,
      );
      _loading = false;
    });
  }

  String? _tryCurrentUserId() {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendCheer() async {
    final current = _profile;
    if (current == null || current.isMe || current.cheeredToday || _sendingCheer) {
      return;
    }

    setState(() => _sendingCheer = true);
    HapticFeedback.mediumImpact();

    try {
      if (widget.mockProfile != null) {
        setState(() {
          _profile = current.copyWith(
            cheersCount: current.cheersCount + 1,
            cheeredToday: true,
          );
        });
        SfxService.instance.playSuccess();
        return;
      }

      final validClassUuid = (widget.classId != null &&
              RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(widget.classId!))
          ? widget.classId
          : null;

      final dynamic res = await supabase.rpc(
        'send_profile_cheer',
        params: {
          'p_receiver': current.userId,
          'p_class': validClassUuid,
        },
      );

      int nextCount = current.cheersCount + 1;
      if (res is List && res.isNotEmpty) {
        final m = Map<String, dynamic>.from(res.first as Map);
        nextCount = (m['cheers_count'] as num?)?.toInt() ?? nextCount;
      }

      SfxService.instance.playSuccess();
      if (!mounted) return;
      setState(() {
        _profile = current.copyWith(
          cheersCount: nextCount,
          cheeredToday: true,
        );
      });
    } catch (e) {
      debugPrint('send_profile_cheer failed: $e');
    } finally {
      if (mounted) {
        setState(() => _sendingCheer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final p = _profile!;
    final avatar = p.avatarConfig ?? AvatarConfig.defaultFor(p.userId.isEmpty ? p.displayName : p.userId);
    final rankTitle = AvatarCatalog.socialRankTitle(
      totalPoints: p.totalPoints,
      badgeCount: p.unlockedBadges.length,
      isLecturer: p.isLecturer,
      isId: isId,
    );

    final earnedBadges = AchievementService.allBadges
        .where((b) => p.unlockedBadges.contains(b.id))
        .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? NetLearnColors.darkLine : const Color(0xFFDDD9E9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Social Hero Card
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                gradient: NetLearnGradients.hero,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.isLecturer
                              ? const Color(0xFFFFD54F).withValues(alpha: 0.24)
                              : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: p.isLecturer
                                ? const Color(0xFFFFD54F)
                                : Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.isLecturer
                                  ? Icons.verified_rounded
                                  : Icons.school_rounded,
                              size: 13,
                              color: p.isLecturer
                                  ? const Color(0xFFFFE082)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              p.isLecturer
                                  ? (isId ? 'DOSEN' : 'LECTURER')
                                  : (isId ? 'MAHASISWA' : 'STUDENT'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: p.isLecturer
                                    ? const Color(0xFFFFE082)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  NlAvatarWidget(
                    key: const Key('public_profile_avatar'),
                    config: avatar,
                    size: 92,
                    borderWidth: 3.5,
                    borderColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rankTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.identityNumber != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.identityNumber!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (p.bio != null && p.bio!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '"${p.bio!}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Social Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? NetLearnColors.darkApp : const Color(0xFFF8F6FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? NetLearnColors.darkLine : const Color(0xFFEDEAF6),
                ),
              ),
              child: Row(
                children: [
                  if (!p.isLecturer) ...[
                    Expanded(
                      child: _SocialStatCell(
                        value: p.totalPoints.toStringAsFixed(0),
                        label: isId ? 'Total Poin' : 'Total Points',
                        color: const Color(0xFF6C2CE2),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark
                          ? NetLearnColors.darkLine
                          : const Color(0xFFE3DFEE),
                    ),
                    Expanded(
                      child: _SocialStatCell(
                        value: p.subnetBestScore > 0
                            ? '${p.subnetBestScore}'
                            : '${p.completedAssessments}',
                        label: p.subnetBestScore > 0
                            ? 'Subnet Best'
                            : (isId ? 'Asesmen' : 'Quizzes'),
                        color: const Color(0xFF00897B),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark
                          ? NetLearnColors.darkLine
                          : const Color(0xFFE3DFEE),
                    ),
                  ],
                  Expanded(
                    child: _SocialStatCell(
                      value: '${p.cheersCount} 👋',
                      label: isId ? 'Semangat Diterima' : 'Cheers Received',
                      color: const Color(0xFFF57C00),
                    ),
                  ),
                ],
              ),
            ),

            // Send Cheer Button (for peers)
            if (!p.isMe) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  key: const Key('public_profile_send_cheer_btn'),
                  onPressed:
                      (p.cheeredToday || _sendingCheer) ? null : _sendCheer,
                  icon: Text(
                    p.cheeredToday ? '🙌' : '👋',
                    style: const TextStyle(fontSize: 17),
                  ),
                  label: Text(
                    p.cheeredToday
                        ? (isId
                            ? 'Semangat Terkirim Hari Ini!'
                            : 'Cheer Sent Today!')
                        : (isId
                            ? 'Kirim Semangat Teman!'
                            : 'Send Classmate Cheer!'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
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

            // Badges Showcase (for students or lecturers who earned badges)
            if (!p.isLecturer || earnedBadges.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isId ? 'Koleksi Lencana' : 'Earned Badges',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${earnedBadges.length}/${AchievementService.allBadges.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C2CE2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (earnedBadges.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? NetLearnColors.darkApp
                        : const Color(0xFFFAF9FD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? NetLearnColors.darkLine
                          : const Color(0xFFEDEAF6),
                    ),
                  ),
                  child: Text(
                    isId
                        ? 'Belum ada lencana terbuka. Kirim semangat agar temanmu makin rajin belajar! ✨'
                        : 'No badges unlocked yet. Send a cheer to encourage them! ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? NetLearnColors.darkMuted
                          : const Color(0xFF7E7B8F),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in earnedBadges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: b.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: b.color.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(b.icon, size: 16, color: b.color),
                            const SizedBox(width: 6),
                            Text(
                              isId ? b.titleId : b.titleEn,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SocialStatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SocialStatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7E7B8F),
          ),
        ),
      ],
    );
  }
}

