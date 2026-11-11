import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../shared/widgets/nl_walkthrough_overlay.dart';
import '../profile/student_profile_controller.dart';

/// Shared widget keys targeted by the student app walkthrough across dashboard and profile.
class StudentWalkthroughKeys {
  StudentWalkthroughKeys._();

  static final profileAvatarKey = GlobalKey();
  static final customProfileKey = GlobalKey();
  static final materiTileKey = GlobalKey();
  static final assessmentTileKey = GlobalKey();
  static final virtualLabTileKey = GlobalKey();
  static final arScannerTileKey = GlobalKey();
  static final leaderboardButtonKey = GlobalKey();
}

/// Manages the interactive 7-step spotlight walkthrough for the student role:
/// 1. Click Profile -> 2. Custom Profile -> 3. Materi -> 4. Assessment ->
/// 5. Virtual Lab -> 6. AR Scanner -> 7. Leaderboard.
class StudentWalkthroughManager {
  StudentWalkthroughManager._();

  static final instance = StudentWalkthroughManager._();

  OverlayEntry? _entry;
  bool _pendingStart = false;

  bool get isActive => _entry != null;

  /// Launches the walkthrough automatically once per user account on first
  /// arrival at the student dashboard after enrolling in a class.
  Future<void> maybeStartFirstTime(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
  }) async {
    if (userId.isEmpty || isActive || _pendingStart) return;
    _pendingStart = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final seenKey = 'student_walkthrough_seen_$userId';
      final alreadySeen = prefs.getBool(seenKey) ?? false;
      if (alreadySeen) {
        _pendingStart = false;
        return;
      }

      await prefs.setBool(seenKey, true);
      if (!context.mounted) {
        _pendingStart = false;
        return;
      }

      _scheduleStartAfterRouteTransition(context, ref);
    } catch (_) {
      _pendingStart = false;
    }
  }

  void _scheduleStartAfterRouteTransition(
    BuildContext context,
    WidgetRef ref,
  ) {
    final routeAnim = ModalRoute.of(context)?.animation;
    if (routeAnim == null || routeAnim.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingStart = false;
        if (context.mounted) {
          start(context, ref);
        }
      });
      return;
    }

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        routeAnim.removeStatusListener(listener);
        _pendingStart = false;
        if (!context.mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            start(context, ref);
          }
        });
      }
    }

    routeAnim.addStatusListener(listener);
  }

  /// Starts the student interactive walkthrough immediately.
  void start(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return;
    dismiss();

    final GoRouter router = ref.read(appRouterProvider);
    final isId = Localizations.localeOf(context).languageCode == 'id';

    // Pre-warm student profile so Step 2 (/student/profile) renders without delay.
    ref.read(studentProfileProvider);

    void ensureRoute(String path) {
      final currentPath = router.routeInformationProvider.value.uri.path;
      if (currentPath != path) {
        router.go(path);
      }
    }

    final steps = <NlWalkthroughStep>[
      // 1. Klik Profile
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.profileAvatarKey,
        icon: Icons.account_circle_rounded,
        accentColor: const Color(0xFF6C2CE2),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 999,
        title: isId ? 'Buka Halaman Profil' : 'Open Profile Page',
        description: isId
            ? 'Ketuk foto profil di kiri atas (atau tab Profil di bawah) untuk membuka halaman Profil Anda dan melihat progres serta lencana pencapaian.'
            : 'Tap your profile avatar at the top left (or the Profile tab below) to open your Profile page, progress stats, and earned badges.',
        onPrepare: () async => ensureRoute('/student'),
      ),

      // 2. Custom Profile
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.customProfileKey,
        icon: Icons.face_retouching_natural_rounded,
        accentColor: const Color(0xFFE6A100),
        highlightPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        highlightRadius: 999,
        title: isId
            ? 'Kustomisasi Profil & Avatar'
            : 'Customize Profile & Avatar',
        description: isId
            ? 'Di halaman Profil ini, ketuk tombol "Kustomisasi Avatar" (atau foto profil Anda) untuk mengubah gaya rambut, ekspresi, kacamata, pakaian, serta mengisi bio singkat.'
            : 'On your Profile page, tap "Customize Avatar" (or your avatar) to personalize hair, expressions, glasses, outfits, and add a short bio.',
        onPrepare: () async => ensureRoute('/student/profile'),
      ),

      // 3. Materi
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.materiTileKey,
        icon: Icons.menu_book_rounded,
        accentColor: const Color(0xFF8C52FF),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 16,
        title: isId ? 'Materi Pembelajaran' : 'Learning Materials',
        description: isId
            ? 'Ketuk Materi untuk mempelajari modul jaringan komputer secara berurutan, lengkap dengan bacaan teks, file PDF, dan video penjelasan.'
            : 'Open Modules to study computer networking materials step by step, complete with reading articles, downloadable PDFs, and videos.',
        onPrepare: () async => ensureRoute('/student'),
      ),

      // 4. Assessment
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.assessmentTileKey,
        icon: Icons.assignment_rounded,
        accentColor: const Color(0xFF7C3AED),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 16,
        title: isId ? 'Asesmen & Tugas' : 'Assessments & Assignments',
        description: isId
            ? 'Akses Pretest, kuis, tugas kelas, serta Posttest melalui menu Asesmen untuk menguji pemahaman Anda dan membuka tahap belajar berikutnya.'
            : 'Access Pretest, quizzes, assignments, and Posttest from Assessments to test your knowledge and unlock subsequent stages.',
        onPrepare: () async => ensureRoute('/student'),
      ),

      // 5. Virtual Lab
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.virtualLabTileKey,
        icon: Icons.lan_rounded,
        accentColor: const Color(0xFF0D9488),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 16,
        title: isId ? 'Virtual Lab Jaringan' : 'Network Virtual Lab',
        description: isId
            ? 'Latih praktik jaringan secara interaktif di Virtual Lab! Pasang router, switch, dan PC, konfigurasi IP Address, uji ping, lalu selesaikan misi praktikum.'
            : 'Practice networking hands-on in Virtual Lab! Wire routers, switches, and PCs, configure IP addresses, test ping, and complete lab missions.',
        onPrepare: () async => ensureRoute('/student'),
      ),

      // 6. AR Scanner
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.arScannerTileKey,
        icon: Icons.view_in_ar_rounded,
        accentColor: const Color(0xFFD97706),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 16,
        title: isId ? 'AR Scanner Perangkat' : 'AR Hardware Scanner',
        description: isId
            ? 'Gunakan AR Scanner (atau tombol AR besar di tengah navigasi bawah) untuk memindai marker perangkat jaringan dan melihat model 3D secara langsung.'
            : 'Use AR Scanner (or the center AR button on the bottom navigation bar) to scan network hardware markers in 3D.',
        onPrepare: () async => ensureRoute('/student'),
      ),

      // 7. Leaderboard
      NlWalkthroughStep(
        targetKey: StudentWalkthroughKeys.leaderboardButtonKey,
        icon: Icons.emoji_events_rounded,
        accentColor: const Color(0xFF5B2EE8),
        highlightPadding: const EdgeInsets.all(6),
        highlightRadius: 12,
        title: isId ? 'Papan Peringkat (Leaderboard)' : 'Class Leaderboard',
        description: isId
            ? 'Pantau peringkat dan poin Anda bersama teman sekelas pada tab Keseluruhan, Asesmen, Subnet Drill, dan Virtual Lab!'
            : 'Track your rank and points against classmates across Overall, Assessment, Subnet Drill, and Virtual Lab categories!',
        onPrepare: () async => ensureRoute('/student'),
      ),
    ];

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) => NlWalkthroughOverlay(
        steps: steps,
        isIndonesian: isId,
        onFinish: ({required bool completed}) {
          dismiss();
          if (completed) {
            ensureRoute('/student');
          }
        },
      ),
    );
    overlay.insert(_entry!);
  }

  /// Safely removes the active walkthrough overlay, if any.
  void dismiss() {
    _pendingStart = false;
    _entry?.remove();
    _entry = null;
  }
}

