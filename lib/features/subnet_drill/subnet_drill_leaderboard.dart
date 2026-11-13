import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../profile/public_profile_sheet.dart';

class SubnetDrillScore {
  final String id;
  final String studentId;
  final String studentName;
  final int score;
  final int maxStreak;
  final String? classId;
  final DateTime date;
  final AvatarConfig? avatarConfig;

  const SubnetDrillScore({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.maxStreak,
    this.classId,
    required this.date,
    this.avatarConfig,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'score': score,
        'maxStreak': maxStreak,
        'classId': classId,
        'date': date.toIso8601String(),
        if (avatarConfig != null) 'avatarConfig': avatarConfig!.toMap(),
      };

  factory SubnetDrillScore.fromMap(Map<String, dynamic> map) => SubnetDrillScore(
        id: map['id']?.toString() ?? '',
        studentId: map['studentId']?.toString() ?? map['id']?.toString() ?? '',
        studentName: map['studentName']?.toString() ?? 'Mahasiswa',
        score: (map['score'] as num?)?.toInt() ?? 0,
        maxStreak: (map['maxStreak'] as num?)?.toInt() ?? 0,
        classId: map['classId']?.toString(),
        date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
        avatarConfig: AvatarConfig.fromDynamic(
          map['avatarConfig'] ?? map['avatar_config'],
        ),
      );
}

class SubnetDrillLeaderboardService {
  static String _storageKey(String? classId) =>
      'subnet_drill_leaderboard_v2_${classId != null && classId.isNotEmpty ? classId : "global"}';

  /// Saves a student's score, keeping their personal best in the specified class and globally.
  static Future<void> saveScore({
    String? classId,
    required String studentId,
    required String studentName,
    required int score,
    required int maxStreak,
  }) async {
    if (score <= 0) return;
    final cleanName = studentName.trim().isEmpty ? 'Mahasiswa' : studentName.trim();
    try {
      final prefs = await SharedPreferences.getInstance();

      // Record personal best for achievement auto-recovery
      final prevBest = prefs.getInt('subnet_drill_personal_best_$studentId') ?? 0;
      if (score > prevBest) {
        await prefs.setInt('subnet_drill_personal_best_$studentId', score);
      }
      final globalBest = prefs.getInt('subnet_drill_personal_best') ?? 0;
      if (score > globalBest) {
        await prefs.setInt('subnet_drill_personal_best', score);
      }

      // Save strictly to class-scoped key (or global key if outside a class)
      // to ensure leaderboard and personal high score are fully isolated per class.
      final targetKeys = <String>{
        _storageKey(classId),
      };

      for (final key in targetKeys) {
        final raw = prefs.getString(key);
        final list = <SubnetDrillScore>[];
        if (raw != null && raw.isNotEmpty) {
          try {
            final List decoded = jsonDecode(raw) as List;
            list.addAll(decoded.map((item) => SubnetDrillScore.fromMap(Map<String, dynamic>.from(item))));
          } catch (_) {}
        }

        // If student already has an entry, update if new score is higher
        final existingIndex = list.indexWhere((e) => e.studentId == studentId);
        if (existingIndex >= 0) {
          final existing = list[existingIndex];
          if (score > existing.score) {
            list[existingIndex] = SubnetDrillScore(
              id: existing.id,
              studentId: studentId,
              studentName: cleanName,
              score: score,
              maxStreak: maxStreak > existing.maxStreak ? maxStreak : existing.maxStreak,
              classId: classId,
              date: DateTime.now(),
            );
          } else if (cleanName != existing.studentName) {
            list[existingIndex] = SubnetDrillScore(
              id: existing.id,
              studentId: studentId,
              studentName: cleanName,
              score: existing.score,
              maxStreak: existing.maxStreak,
              classId: classId,
              date: existing.date,
            );
          }
        } else {
          list.add(SubnetDrillScore(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            studentId: studentId,
            studentName: cleanName,
            score: score,
            maxStreak: maxStreak,
            classId: classId,
            date: DateTime.now(),
          ));
        }

        list.sort((a, b) {
          final cmp = b.score.compareTo(a.score);
          return cmp != 0 ? cmp : b.maxStreak.compareTo(a.maxStreak);
        });

        final top = list.take(50).toList();
        final jsonStr = jsonEncode(top.map((e) => e.toMap()).toList());
        await prefs.setString(key, jsonStr);
      }

      // Persist to Supabase so scores are permanent and never reset on restart
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final isRealUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(studentId);
          final validUid = isRealUuid ? studentId : user.id;

          AvatarConfig? myAvatar = AvatarConfig.fromDynamic(
            prefs.getString('cached_avatar_config_$validUid'),
          );
          if (myAvatar == null) {
            try {
              final prof = await supabase
                  .from('profiles')
                  .select('avatar_config')
                  .eq('id', validUid)
                  .maybeSingle();
              myAvatar = AvatarConfig.fromDynamic(prof?['avatar_config']);
            } catch (_) {}
          }

          Future<void> syncRemote(String? cId) async {
            var q = supabase
                .from('subnet_drill_scores')
                .select('id, score, max_streak')
                .eq('user_id', validUid);
            if (cId != null && cId.isNotEmpty) {
              q = q.eq('class_id', cId);
            } else {
              q = q.isFilter('class_id', null);
            }
            final existing = await q.maybeSingle();
            if (existing != null) {
              final prevScore = (existing['score'] as num?)?.toInt() ?? 0;
              final prevStreak = (existing['max_streak'] as num?)?.toInt() ?? 0;
              if (score > prevScore || (score == prevScore && maxStreak > prevStreak) || cleanName != studentName || myAvatar != null) {
                await supabase.from('subnet_drill_scores').update({
                  'student_name': cleanName,
                  'score': score > prevScore ? score : prevScore,
                  'max_streak': maxStreak > prevStreak ? maxStreak : prevStreak,
                  if (myAvatar != null) 'avatar_config': myAvatar.toMap(),
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', existing['id']);
              }
            } else {
              await supabase.from('subnet_drill_scores').insert({
                'user_id': validUid,
                'student_name': cleanName,
                'score': score,
                'max_streak': maxStreak,
                'class_id': cId,
                if (myAvatar != null) 'avatar_config': myAvatar.toMap(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            }
          }

          if (classId != null && classId.isNotEmpty) {
            await syncRemote(classId);
          } else {
            await syncRemote(null);
          }
        }
      } catch (e) {
        debugPrint('SubnetDrill saveScore remote warning: $e');
      }
    } catch (_) {}
  }

  /// Returns real student scores for the given class, with fallback to global scores.
  static Future<List<SubnetDrillScore>> getTopScores({String? classId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Try remote fetch from Supabase
      try {
        var query = supabase
            .from('subnet_drill_scores')
            .select('id, user_id, student_name, score, max_streak, class_id, avatar_config, updated_at');
        if (classId != null && classId.isNotEmpty) {
          query = query.eq('class_id', classId);
        } else {
          query = query.isFilter('class_id', null);
        }

        final remoteRows = await query
            .order('score', ascending: false)
            .order('max_streak', ascending: false)
            .limit(50);

        if (remoteRows.isNotEmpty) {
          final remoteScores = remoteRows.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return SubnetDrillScore(
              id: m['id']?.toString() ?? '',
              studentId: m['user_id']?.toString() ?? '',
              studentName: m['student_name']?.toString() ?? 'Mahasiswa',
              score: (m['score'] as num?)?.toInt() ?? 0,
              maxStreak: (m['max_streak'] as num?)?.toInt() ?? 0,
              classId: m['class_id']?.toString(),
              date: DateTime.tryParse(m['updated_at']?.toString() ?? '') ?? DateTime.now(),
              avatarConfig: AvatarConfig.fromDynamic(m['avatar_config']),
            );
          }).toList();

          final key = _storageKey(classId);
          await prefs.setString(key, jsonEncode(remoteScores.map((e) => e.toMap()).toList()));

          return remoteScores;
        }
      } catch (remoteErr) {
        debugPrint('SubnetDrill getTopScores remote fallback: $remoteErr');
      }

      final key = _storageKey(classId);
      var raw = prefs.getString(key);

      // Migrate legacy scores from subnet_drill_leaderboard_v1 only for global fallback,
      // and remove the key so it never leaks or populates other newly opened classes.
      if (classId == null || classId.isEmpty) {
        final legacyRaw = prefs.getString('subnet_drill_leaderboard_v1');
        if (legacyRaw != null && legacyRaw.isNotEmpty) {
          try {
            final List decodedLegacy = jsonDecode(legacyRaw) as List;
            final legacyScores = decodedLegacy
                .map((item) => SubnetDrillScore.fromMap(Map<String, dynamic>.from(item)))
                .where((s) => s.score > 0 && !s.studentName.contains('Dummy') && !s.studentName.contains('Seed'))
                .toList();
            if (legacyScores.isNotEmpty) {
              for (final sc in legacyScores) {
                await saveScore(
                  classId: null,
                  studentId: sc.studentId,
                  studentName: sc.studentName,
                  score: sc.score,
                  maxStreak: sc.maxStreak,
                );
              }
              raw = prefs.getString(key);
            }
          } catch (_) {}
          await prefs.remove('subnet_drill_leaderboard_v1');
        }
      }

      // If class-specific leaderboard is empty, fallback to global scores
      if ((raw == null || raw.isEmpty) && classId != null && classId.isNotEmpty) {
        raw = prefs.getString(_storageKey(null));
      }

      if (raw == null || raw.isEmpty) return <SubnetDrillScore>[];

      final List decoded = jsonDecode(raw) as List;
      final scores = decoded
          .map((item) => SubnetDrillScore.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      scores.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        return cmp != 0 ? cmp : b.maxStreak.compareTo(a.maxStreak);
      });
      return scores;
    } catch (_) {
      return <SubnetDrillScore>[];
    }
  }
}

/// Bottom Sheet modal displaying the Subnetting Drill Leaderboard for the active class.
void showSubnetDrillLeaderboard(
  BuildContext context, {
  String? classId,
  String? className,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _SubnetDrillLeaderboardSheet(
      classId: classId,
      className: className,
    ),
  );
}

class _SubnetDrillLeaderboardSheet extends StatefulWidget {
  final String? classId;
  final String? className;

  const _SubnetDrillLeaderboardSheet({
    this.classId,
    this.className,
  });

  @override
  State<_SubnetDrillLeaderboardSheet> createState() => _SubnetDrillLeaderboardSheetState();
}

class _SubnetDrillLeaderboardSheetState extends State<_SubnetDrillLeaderboardSheet> {
  late Future<List<SubnetDrillScore>> _future;

  @override
  void initState() {
    super.initState();
    _future = SubnetDrillLeaderboardService.getTopScores(classId: widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? NetLearnColors.darkLine : const Color(0xFFDDD9E9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF8F00), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.className != null && widget.className!.isNotEmpty
                              ? (isId ? 'Peringkat: ${widget.className}' : 'Leaderboard: ${widget.className}')
                              : (isId ? 'Papan Peringkat Subnetting' : 'Subnetting Leaderboard'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isId
                              ? 'Skor tertinggi Speed Subnetting Drill mahasiswa'
                              : 'Top student scores in Speed Subnetting Drill',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            Expanded(
              child: FutureBuilder<List<SubnetDrillScore>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const NlSkeletonList(
                      itemCount: 4,
                      padding: EdgeInsets.all(20),
                    );
                  }

                  final scores = snapshot.data ?? [];
                  if (scores.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8C52FF).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_outlined,
                                size: 48,
                                color: Color(0xFF8C52FF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.className != null
                                  ? (isId ? 'Belum ada skor di ${widget.className}' : 'No scores in ${widget.className} yet')
                                  : (isId ? 'Belum ada skor tercatat' : 'No scores recorded yet'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isId
                                  ? 'Mainkan Speed Subnetting Drill sekarang untuk mencatatkan rekor pertamamu di kelas!'
                                  : 'Play Speed Subnetting Drill now to record your first class record!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? NetLearnColors.darkMuted : const Color(0xFF8A8FA3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // Podium Top 3
                      if (scores.isNotEmpty) _buildPodium(scores),

                      const SizedBox(height: 24),
                      Text(
                        isId ? 'Semua Peringkat' : 'All Rankings',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),

                      // Rest of list
                      for (var i = 0; i < scores.length; i++)
                        _buildRow(index: i + 1, score: scores[i], isDark: isDark),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodium(List<SubnetDrillScore> scores) {
    final first = scores.isNotEmpty ? scores[0] : null;
    final second = scores.length > 1 ? scores[1] : null;
    final third = scores.length > 2 ? scores[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (second != null)
          Expanded(child: _buildPodiumColumn(second, 2, const Color(0xFFB0BEC5), 110, '🥈')),
        // 1st Place
        if (first != null)
          Expanded(child: _buildPodiumColumn(first, 1, const Color(0xFFFFB300), 140, '👑')),
        // 3rd Place
        if (third != null)
          Expanded(child: _buildPodiumColumn(third, 3, const Color(0xFFCD7F32), 90, '🥉')),
      ],
    );
  }

  Widget _buildPodiumColumn(SubnetDrillScore item, int rank, Color color, double height, String badge) {
    final avatar = item.avatarConfig ??
        AvatarConfig.defaultFor(
          item.studentId.isEmpty ? item.studentName : item.studentId,
        );
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showPublicProfileSheet(
        context,
        userId: item.studentId,
        classId: widget.classId,
        fallbackName: item.studentName,
        fallbackAvatar: avatar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          NlAvatarWidget(
            config: avatar,
            size: rank == 1 ? 48 : 40,
            borderWidth: 2,
            borderColor: color,
          ),
          const SizedBox(height: 4),
          Text(
            item.studentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.score} pts',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.maxStreak}x streak',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8A8FA3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({required int index, required SubnetDrillScore score, required bool isDark}) {
    Color rankColor = const Color(0xFF8A8FA3);
    if (index == 1) rankColor = const Color(0xFFFFB300);
    if (index == 2) rankColor = const Color(0xFFB0BEC5);
    if (index == 3) rankColor = const Color(0xFFCD7F32);

    final avatar = score.avatarConfig ??
        AvatarConfig.defaultFor(
          score.studentId.isEmpty ? score.studentName : score.studentId,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showPublicProfileSheet(
          context,
          userId: score.studentId,
          classId: widget.classId,
          fallbackName: score.studentName,
          fallbackAvatar: avatar,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? NetLearnColors.darkApp : const Color(0xFFF7F6FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: index <= 3 ? rankColor.withValues(alpha: 0.3) : (isDark ? NetLearnColors.darkLine : const Color(0xFFEBE8F3)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$index',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: rankColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              NlAvatarWidget(
                config: avatar,
                size: 34,
                borderWidth: 1.5,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${score.maxStreak}x combo streak',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
                    ),
                  ],
                ),
              ),
              Text(
                '${score.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8C52FF),
                ),
              ),
              const SizedBox(width: 4),
              const Text('pts', style: TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
            ],
          ),
        ),
      ),
    );
  }
}
