import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/supabase/supabase_client.dart';

class BadgeItem {
  final String id;
  final String titleId;
  final String titleEn;
  final String descriptionId;
  final String descriptionEn;
  final String requirementId;
  final String requirementEn;
  final IconData icon;
  final Color color;

  const BadgeItem({
    required this.id,
    required this.titleId,
    required this.titleEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.requirementId,
    required this.requirementEn,
    required this.icon,
    required this.color,
  });
}

class AchievementService {
  static const List<BadgeItem> allBadges = [
    BadgeItem(
      id: 'subnet_master',
      titleId: 'Subnet Master',
      titleEn: 'Subnet Master',
      descriptionId: 'Mencapai skor 100+ dalam Speed Subnetting Drill.',
      descriptionEn: 'Scored 100+ in Speed Subnetting Drill.',
      requirementId: 'Mainkan Speed Subnetting Drill di menu Latihan Jaringan dan raih skor 100 poin atau lebih.',
      requirementEn: 'Play Speed Subnetting Drill under Network Practice and reach 100+ points.',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFF9800),
    ),
    BadgeItem(
      id: 'packet_slinger',
      titleId: 'Packet Slinger',
      titleEn: 'Packet Slinger',
      descriptionId: 'Berhasil menghubungkan perangkat dan tes ping sukses di Virtual Lab.',
      descriptionEn: 'Successfully wired devices and pinged in Virtual Lab.',
      requirementId: 'Buka Virtual Lab Simulasi di kelas mana saja, hubungkan perangkat menggunakan kabel, lalu lakukan uji Ping yang berhasil.',
      requirementEn: 'Open Virtual Lab in any class, connect devices with cables, and achieve a successful Ping test.',
      icon: Icons.cable_rounded,
      color: Color(0xFF2196F3),
    ),
    BadgeItem(
      id: 'ar_pioneer',
      titleId: 'AR Pioneer',
      titleEn: 'AR Pioneer',
      descriptionId: 'Berhasil memindai marker AR 3D perangkat jaringan.',
      descriptionEn: 'Successfully scanned a 3D AR network marker.',
      requirementId: 'Buka fitur AR Scanner di menu Beranda dan arahkan kamera ke kartu marker AR perangkat keras jaringan 3D.',
      requirementEn: 'Open the AR Scanner on the Home screen and scan any 3D network hardware AR marker card.',
      icon: Icons.view_in_ar_rounded,
      color: Color(0xFF9C27B0),
    ),
    BadgeItem(
      id: 'fast_learner',
      titleId: 'Fast Learner',
      titleEn: 'Fast Learner',
      descriptionId: 'Menyelesaikan modul pembelajaran dan tes kompetensi.',
      descriptionEn: 'Completed a learning module and competency test.',
      requirementId: 'Selesaikan dan kumpulkan (submit) tes kompetensi (Pretest, Kuis Modul, atau Posttest) di kelas mana saja.',
      requirementEn: 'Complete and submit any competency assessment (Pretest, Module Quiz, or Posttest) in any class.',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF4CAF50),
    ),
    BadgeItem(
      id: 'network_scholar',
      titleId: 'Network Scholar',
      titleEn: 'Network Scholar',
      descriptionId: 'Membaca dan menuntaskan materi literasi jaringan.',
      descriptionEn: 'Read and finished network literacy materials.',
      requirementId: 'Buka materi modul pembelajaran di kelas mana saja, pelajari hingga selesai, lalu tekan tombol "Tandai Selesai Dibaca".',
      requirementEn: 'Open any module learning material in any class, read through, and tap the "Mark as Read" button.',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF009688),
    ),
  ];

  /// Returns the set of badge IDs unlocked by the user.
  ///
  /// Strictly user-scoped by [userId] (or [supabase.auth.currentUser.id]).
  /// Never leaks or shares unlocked badges across different accounts on the same device.
  static Future<Set<String>> getUnlockedBadges({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();

    // Clean up legacy device-global keys to prevent cross-account pollution
    if (prefs.containsKey('unlocked_badges')) {
      await prefs.remove('unlocked_badges');
    }
    if (prefs.containsKey('has_completed_reading')) {
      await prefs.remove('has_completed_reading');
    }
    if (prefs.containsKey('subnet_drill_personal_best')) {
      await prefs.remove('subnet_drill_personal_best');
    }

    String? uid = userId;
    if (uid == null) {
      try {
        uid = supabase.auth.currentUser?.id;
      } catch (_) {}
    }

    final userKey = uid != null ? 'unlocked_badges_$uid' : 'unlocked_badges_guest';
    final cachedList = prefs.getStringList(userKey) ?? [];
    final set = cachedList.toSet();

    if (uid == null) {
      return set;
    }

    try {
      Set<String> remoteBadges = <String>{};
      try {
        final prof = await supabase
            .from('profiles')
            .select('unlocked_badges')
            .eq('id', uid)
            .maybeSingle();
        final raw = prof?['unlocked_badges'];
        if (raw is List) {
          remoteBadges = raw
              .map((e) => e?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet();
        }
      } catch (e) {
        debugPrint('AchievementService getUnlockedBadges remote fetch warning: $e');
      }

      set.addAll(remoteBadges);

      // Verify legitimacy of fast_learner: student must have at least 1 submitted attempt
      if (set.contains('fast_learner')) {
        try {
          final submitted = await supabase
              .from('quiz_attempts')
              .select('id')
              .eq('user_id', uid)
              .eq('status', 'submitted')
              .limit(1)
              .maybeSingle();
          if (submitted == null) {
            set.remove('fast_learner');
          }
        } catch (_) {}
      }

      // Verify legitimacy of subnet_master: student must have personal best >= 100
      if (set.contains('subnet_master')) {
        final pb = prefs.getInt('subnet_drill_high_score_$uid') ??
            prefs.getInt('subnet_drill_personal_best_$uid') ??
            0;
        if (pb < 100) {
          try {
            final row = await supabase
                .from('subnet_drill_scores')
                .select('score')
                .eq('user_id', uid)
                .gte('score', 100)
                .limit(1)
                .maybeSingle();
            if (row == null) {
              set.remove('subnet_master');
            }
          } catch (_) {}
        }
      }

      // Verify legitimacy of network_scholar: must have completed reading in any class
      if (set.contains('network_scholar')) {
        final localReading = prefs.getBool('has_completed_reading_$uid') ?? false;
        if (!localReading) {
          try {
            final reading = await supabase
                .from('learning_progress')
                .select('id')
                .eq('user_id', uid)
                .eq('reading_completed', true)
                .limit(1)
                .maybeSingle();
            if (reading == null) {
              // Juga periksa progres materi kelas mana saja di tabel material_progress
              final classReading = await supabase
                  .from('material_progress')
                  .select('id')
                  .eq('student_id', uid)
                  .eq('reading_completed', true)
                  .limit(1)
                  .maybeSingle();
              if (classReading == null) {
                set.remove('network_scholar');
              }
            }
          } catch (_) {}
        }
      }

      // Dynamic Auto-Recovery checks for legitimately earned badges:
      // a) Subnet Master:
      if (!set.contains('subnet_master')) {
        final pb = prefs.getInt('subnet_drill_high_score_$uid') ??
            prefs.getInt('subnet_drill_personal_best_$uid') ??
            0;
        if (pb >= 100) {
          set.add('subnet_master');
        } else {
          try {
            final row = await supabase
                .from('subnet_drill_scores')
                .select('score')
                .eq('user_id', uid)
                .gte('score', 100)
                .limit(1)
                .maybeSingle();
            if (row != null) {
              set.add('subnet_master');
            }
          } catch (_) {}
        }
      }

      // b) Fast Learner:
      if (!set.contains('fast_learner')) {
        try {
          final submitted = await supabase
              .from('quiz_attempts')
              .select('id')
              .eq('user_id', uid)
              .or('status.eq.submitted,status.eq.completed')
              .limit(1)
              .maybeSingle();
          if (submitted != null) {
            set.add('fast_learner');
          }
        } catch (_) {}
      }

      // c) Network Scholar (berlaku untuk materi di kelas mana saja):
      if (!set.contains('network_scholar')) {
        final localReading = prefs.getBool('has_completed_reading_$uid') ?? false;
        if (localReading) {
          set.add('network_scholar');
        } else {
          try {
            final reading = await supabase
                .from('learning_progress')
                .select('id')
                .eq('user_id', uid)
                .eq('reading_completed', true)
                .limit(1)
                .maybeSingle();
            if (reading != null) {
              set.add('network_scholar');
            } else {
              final classReading = await supabase
                  .from('material_progress')
                  .select('id')
                  .eq('student_id', uid)
                  .eq('reading_completed', true)
                  .limit(1)
                  .maybeSingle();
              if (classReading != null) {
                set.add('network_scholar');
              }
            }
          } catch (_) {}
        }
      }

      // d) Packet Slinger (berlaku untuk Virtual Lab di kelas mana saja):
      if (!set.contains('packet_slinger')) {
        final localPing = prefs.getBool('has_completed_vlab_ping_$uid') ?? false;
        if (localPing) {
          set.add('packet_slinger');
        } else {
          try {
            final vlabRow = await supabase
                .from('virtual_lab_scores')
                .select('id')
                .eq('user_id', uid)
                .limit(1)
                .maybeSingle();
            if (vlabRow != null) {
              set.add('packet_slinger');
            }
          } catch (_) {}
        }
      }

      // Sync back to Supabase if set was sanitized or legitimately earned new badges
      if (set.length != remoteBadges.length || !set.containsAll(remoteBadges)) {
        try {
          await supabase
              .from('profiles')
              .update({'unlocked_badges': set.toList()})
              .eq('id', uid);
        } catch (e) {
          debugPrint('AchievementService update remote error: $e');
        }
      }

      // Persist user-scoped local cache
      await prefs.setStringList(userKey, set.toList());
    } catch (_) {}

    return set;
  }

  static Future<bool> unlockBadge(
    BuildContext? context,
    String badgeId, {
    String? userId,
  }) async {
    String? uid = userId;
    if (uid == null) {
      try {
        uid = supabase.auth.currentUser?.id;
      } catch (_) {}
    }

    final userKey = uid != null ? 'unlocked_badges_$uid' : 'unlocked_badges_guest';
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(userKey) ?? [];
    if (list.contains(badgeId)) {
      return false; // Already unlocked
    }

    list.add(badgeId);
    await prefs.setStringList(userKey, list);

    // Best-effort sync to Supabase profiles.unlocked_badges for this user
    if (uid != null) {
      try {
        final prof = await supabase
            .from('profiles')
            .select('unlocked_badges')
            .eq('id', uid)
            .maybeSingle();
        final remote = (prof?['unlocked_badges'] as List?)
                ?.map((e) => e?.toString().trim() ?? '')
                .where((s) => s.isNotEmpty)
                .toSet() ??
            <String>{};
        remote.add(badgeId);

        await supabase
            .from('profiles')
            .update({'unlocked_badges': remote.toList()})
            .eq('id', uid);
      } catch (_) {}
    }

    HapticFeedback.heavyImpact();
    SfxService.instance.playSuccess();

    if (context != null && context.mounted) {
      final badge = allBadges.firstWhere(
        (b) => b.id == badgeId,
        orElse: () => allBadges.first,
      );
      final isId = Localizations.localeOf(context).languageCode == 'id';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1D1B26),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(badge.icon, color: badge.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 ${isId ? 'Lencana Baru Terbuka!' : 'New Badge Unlocked!'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    Text(
                      isId ? badge.titleId : badge.titleEn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isId ? badge.descriptionId : badge.descriptionEn,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return true;
  }
}

/// Reactive provider for the currently signed-in student's unlocked badges.
/// Automatically invalidated on sign-out / sign-in via [resetUserSession].
final studentUnlockedBadgesProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  return AchievementService.getUnlockedBadges();
});

