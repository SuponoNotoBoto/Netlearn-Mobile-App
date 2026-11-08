import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/onboarding_status.dart';
import '../../features/about/student_about_page.dart';
import '../../features/dashboard_lecturer/lecturer_about_page.dart';
import '../../features/dashboard_lecturer/lecturer_change_password_page.dart';
import '../../shared/widgets/under_development_page.dart';
import '../../features/classes/class_leaderboard_page.dart';
import '../../features/classes/class_onboarding_page.dart';
import '../../features/classes/lecturer_archived_classes_page.dart';
import '../../features/classes/lecturer_class_detail_page.dart';
import '../../features/classes/lecturer_create_class_page.dart';
import '../../features/classes/lecturer_manage_classes_page.dart';
import '../../features/assessment/assessment_instructions_page.dart';
import '../../features/assessment/assessment_list_page.dart';
import '../../features/assessment/assessment_page.dart';
import '../../features/assessment/assessment_result_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/onboarding_flow_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/reset_password_page.dart';
import '../../features/dashboard_lecturer/announcement_form_page.dart';
import '../../features/dashboard_lecturer/announcement_list_page.dart';
import '../../features/dashboard_lecturer/lecturer_academic_info_page.dart';
import '../../features/dashboard_lecturer/lecturer_assessments_page.dart';
import '../../features/dashboard_lecturer/lecturer_dashboard_page.dart';
import '../../features/dashboard_lecturer/lecturer_material_form_page.dart';
import '../../features/dashboard_lecturer/lecturer_materials_page.dart';
import '../../features/dashboard_lecturer/lecturer_profile_info_page.dart';
import '../../features/dashboard_lecturer/lecturer_profile_page.dart';
import '../../features/dashboard_lecturer/lecturer_question_form_page.dart';
import '../../features/dashboard_lecturer/lecturer_questions_page.dart';
import '../../features/dashboard_lecturer/lecturer_security_page.dart';
import '../../features/dashboard_lecturer/lecturer_student_list_page.dart';
import '../../features/dashboard_lecturer/lecturer_student_score_detail_page.dart';
import '../../features/dashboard_lecturer/lecturer_task_detail_page.dart';
import '../../features/dashboard_lecturer/lecturer_task_form_page.dart';
import '../../features/dashboard_student/student_dashboard_page.dart';
import '../../features/discussions/class_discussion_page.dart';
import '../../features/discussions/discussion_thread_detail_page.dart';
import '../../features/materials/material_detail_page.dart';
import '../../features/materials/material_reader_page.dart';
import '../../features/materials/module_materials_page.dart';
import '../../features/materials/pdf_viewer_page.dart';
import '../../features/materials/student_materials_page.dart';
import '../../features/materials/material_lab_binding.dart';
import '../../features/notifications/student_notifications_page.dart';
import '../../features/notifications/lecturer_notifications_page.dart';
import '../../features/profile/student_profile_page.dart';
import '../../features/profile/student_profile_info_page.dart';
import '../../features/profile/student_academic_info_page.dart';
import '../../features/profile/student_security_page.dart';
import '../../features/profile/change_password_page.dart';
import '../../features/profile/student_assessment_history_page.dart';
import '../../features/video/video_list_page.dart';
import '../../features/video/video_page.dart';
import '../../features/virtual_lab/virtual_lab_page.dart';
import '../supabase/supabase_client.dart';
import '../session/session_reset.dart';
import '../../l10n/app_localizations.dart';
import 'profile_cache.dart';
import 'router_error_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();

    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Outcome of the auth guard for a single navigation.
///
/// [location] is where to redirect (`null` lets the navigation through);
/// [signOut] tells the caller to drop the current session before honouring it.
class AuthRedirect {
  const AuthRedirect(this.location, {this.signOut = false});

  final String? location;
  final bool signOut;
}

/// Routes whose reachability depends on the signed-in user's role.
///
/// Kept separate from [resolveAuthRedirect] so the redirect can decide whether
/// a profile read is needed before doing any I/O.
bool authRedirectNeedsProfile(String location) {
  final onStudentRoute =
      location == '/student' || location.startsWith('/student/');
  final onLecturerRoute =
      location == '/lecturer' || location.startsWith('/lecturer/');

  return location == '/' ||
      location == '/login' ||
      location == '/register' ||
      location == '/forgot-password' ||
      location == '/onboarding' ||
      onStudentRoute ||
      onLecturerRoute;
}

/// Pure auth-guard decision, extracted so the deep-link rules can be unit
/// tested without Supabase.
///
/// Only `student` and `lecturer` are supported roles. A missing profile, an
/// inactive account, `admin`, or any unknown role is signed out and sent to
/// `/login` rather than being mapped onto a student or lecturer screen. A
/// supported role is bounced to its own area, which also stops a deep link
/// into the other role's area.
AuthRedirect resolveAuthRedirect({
  required bool hasSession,
  required String location,
  required String? role,
  required bool isActive,
}) {
  // '/admin' and '/admin/**' are dead routes: the admin side was removed, so
  // a legacy admin session (or anyone) deep-linking there must have its session
  // ended rather than leave a stale privileged session behind. Checked before
  // anything else so it can never be skipped or swallowed by the error page.
  // Matched per path segment: '/administrator' is NOT the admin route.
  final onAdminRoute = location == '/admin' || location.startsWith('/admin/');

  if (onAdminRoute) {
    return AuthRedirect('/login', signOut: hasSession);
  }

  final loggingIn = location == '/login';
  final registering = location == '/register';
  final resettingPassword = location == '/forgot-password';

  final onStudentRoute =
      location == '/student' || location.startsWith('/student/');
  final onLecturerRoute =
      location == '/lecturer' || location.startsWith('/lecturer/');

  if (!hasSession) {
    // `/splash` harus tetap terlihat tanpa sesi: ia hanya memutar animasi
    // lalu menyerahkan keputusan ke funnel `/`. Memantulkannya ke `/login`
    // di sini berarti splash tak pernah tampil untuk calon pengguna baru —
    // sudah pernah terjadi ketika semua lokasi tak-knowledge dipantulkan.
    if (location == '/splash') {
      return const AuthRedirect(null);
    }

    if (location == '/' || (!loggingIn && !registering && !resettingPassword)) {
      return const AuthRedirect('/login');
    }

    return const AuthRedirect(null);
  }

  // Authenticated users should not access login/register/forgot-password pages.
  // Bounce them to their respective role area.
  if (loggingIn || registering || resettingPassword) {
    switch (role) {
      case 'student':
        return const AuthRedirect('/student');
      case 'lecturer':
        return const AuthRedirect('/lecturer');
      default:
        return const AuthRedirect('/login', signOut: true);
    }
  }

  if (!authRedirectNeedsProfile(location)) {
    return const AuthRedirect(null);
  }

  if (role == null || !isActive) {
    return const AuthRedirect('/login', signOut: true);
  }

  switch (role) {
    case 'student':
      if (location == '/' || loggingIn || onLecturerRoute) {
        return const AuthRedirect('/student');
      }

      return const AuthRedirect(null);

    case 'lecturer':
      if (location == '/' || loggingIn || onStudentRoute) {
        return const AuthRedirect('/lecturer');
      }

      return const AuthRedirect(null);

    default:
      return const AuthRedirect('/login', signOut: true);
  }
}

/// Class gate (Google Classroom style, NETLEARN_PRD v7): a student who has not
/// joined any class and a lecturer who owns no class cannot reach their role
/// area. They are held on the class onboarding screen (join by code / create
/// class) until they have one.
///
/// Pure so it can be unit tested. [hasClass] is `null` when membership could
/// not be determined (e.g. network failure) — the gate then stays open and the
/// dashboards' own embedded gate still applies, so a flaky link never locks a
/// user out of the app.
const String kStudentClassOnboardingPath = '/student/class-onboarding';
const String kLecturerClassOnboardingPath = '/lecturer/class-onboarding';

String? resolveClassGateRedirect({
  required String? role,
  required String location,
  required bool? hasClass,
}) {
  if (hasClass == null) {
    return null;
  }

  switch (role) {
    case 'student':
      final onStudentRoute =
          location == '/student' || location.startsWith('/student/');
      if (!onStudentRoute) return null;
      final onGateRoute = location == kStudentClassOnboardingPath ||
          location == '/student/forgot-password';
      if (!hasClass) {
        return onGateRoute ? null : '$kStudentClassOnboardingPath?required=1';
      }
      return null;

    case 'lecturer':
      final onLecturerRoute =
          location == '/lecturer' || location.startsWith('/lecturer/');
      if (!onLecturerRoute) return null;
      final onGateRoute = location == kLecturerClassOnboardingPath ||
          location == '/lecturer/classes/create' ||
          location == '/lecturer/classes/archived' ||
          location == '/lecturer/forgot-password';
      if (!hasClass) {
        return onGateRoute ? null : '$kLecturerClassOnboardingPath?required=1';
      }
      return null;

    default:
      return null;
  }
}

/// Remembers, per user, that the account already has a class. Only a positive
/// answer is cached: once a student joins / a lecturer creates a class the gate
/// never needs to ask again this session, while a negative answer is re-checked
/// on every navigation so the user is let through right after joining.
class ClassMembershipCache {
  String? _userId;

  bool hasClass(String userId) => _userId == userId;

  void markHasClass(String userId) => _userId = userId;

  void clear() => _userId = null;
}

/// Async orchestration around [resolveAuthRedirect].
///
/// The pure decision is unchanged; this only performs the side effects the
/// decision asks for, with every effect injected so the whole flow can be
/// tested offline. [loadProfile] runs only when the route actually needs a
/// profile, mirroring the guard. When the decision asks to sign out, [signOut]
/// runs first and [resetSession] only after it returns: a failed sign out must
/// not be reported as a cleaned session, so it propagates instead of being
/// swallowed.
Future<AuthRedirect> evaluateAuthRedirect({
  required String? userId,
  required String location,
  required Future<Map<String, dynamic>?> Function(String userId) loadProfile,
  required Future<void> Function() signOut,
  required void Function() resetSession,
}) async {
  Map<String, dynamic>? profile;

  if (userId != null && authRedirectNeedsProfile(location)) {
    profile = await loadProfile(userId);
  }

  final decision = resolveAuthRedirect(
    hasSession: userId != null,
    location: location,
    role: profile?['role']?.toString(),
    isActive: profile?['is_active'] as bool? ?? false,
  );

  if (decision.signOut) {
    await signOut();
    resetSession();
  }

  return decision;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // The guard below needs the account row (`role` + `is_active`) on every
  // navigation into /student or /lecturer, and `redirect` runs on *every* push
  // and pop. Reading it from `profiles` each time put a network round-trip in
  // front of every page transition -- the round-trip is 1-2 s on a slow link
  // even though the query itself takes ~0.1 ms, which is the delay felt after
  // tapping a nav item. Cache it per user for a few minutes instead, so
  // navigation never waits on the network; sign-out clears it.
  final profileCache = ProfileCache();

  Future<Map<String, dynamic>?> loadProfile(String userId) async {
    final cached = profileCache.read(userId);

    if (cached != null) {
      return cached;
    }

    final profile = await supabase
        .from('profiles')
        .select('role, is_active')
        .eq('id', userId)
        .maybeSingle();

    if (profile != null) {
      profileCache.write(userId, profile);
    }

    return profile;
  }

  final classMembershipCache = ClassMembershipCache();

  /// `true`/`false` when known, `null` when the membership read failed.
  Future<bool?> loadHasClass(String userId, String role) async {
    if (classMembershipCache.hasClass(userId)) {
      return true;
    }
    try {
      final dynamic response = await supabase.rpc(
        role == 'lecturer' ? 'lecturer_classes' : 'my_classes',
      );
      final has = response is List && response.isNotEmpty;
      if (has) {
        classMembershipCache.markHasClass(userId);
      }
      return has;
    } catch (error) {
      debugPrint('class gate membership check failed: $error');
      return null;
    }
  }

  return GoRouter(
    // Cold start selalu dibuka splash; di akhir animasinya splash menyerahkan
    // keputusan ke guard lewat `/` (initialLocation lama). Lihat
    // [resolveAuthRedirect]: `/splash` tetap terlihat tanpa sesi, dan saat ada
    // sesi tidak membaca profile sama sekali.
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      final location = state.matchedLocation;

      // =========================================================
      // SUDAH LOGIN
      // =========================================================
      //
      // The guard runs on '/', '/login' and the two role areas. It used to
      // only run on '/' and '/login', so an admin or an unknown-role session
      // could deep-link straight into /student or /lecturer; the pages carry
      // no per-route guard. Role decides which area is reachable: anything
      // else (admin, empty, malformed) is signed out instead of being mapped
      // onto a student or lecturer screen. The decision itself lives in
      // [resolveAuthRedirect] and the effects in [evaluateAuthRedirect] so both
      // can be tested without Supabase.

      final decision = await evaluateAuthRedirect(
        userId: session?.user.id,
        location: location,
        loadProfile: loadProfile,
        signOut: () => supabase.auth.signOut(),
        resetSession: () {
          // A signed-out session must not leave a row behind for the next
          // account on this device.
          profileCache.clear();
          classMembershipCache.clear();
          resetUserSession(ref);
        },
      );

      // If the auth guard bounced the user (e.g. to /login), honour that
      // first — onboarding is irrelevant without a session.
      if (decision.location != null) {
        return decision.location;
      }

      // From here the user is authenticated with a valid role. Check
      // onboarding: a first-time user who has not picked a language is sent
      // to /onboarding; a user who has already completed it and is sitting
      // on /onboarding is pushed onward to their role area. Unauthenticated
      // users must never be redirected to /onboarding (require session).
      if (session == null) {
        return null;
      }

      final onboardingComplete = await _isOnboardingComplete();

      // The recovery completion page is exempt: a user resetting a password on
      // a device that has never finished onboarding would otherwise lose the new
      // password they are halfway through choosing to the language picker.
      // `/splash` is exempt for a different reason: the splash must itself be
      // shown first, and the hand-off '/' afterwards re-runs this gate so the
      // first-time logged-in user still lands in the language picker.
      if (!onboardingComplete &&
          location != '/onboarding' &&
          location != '/reset-password' &&
          location != '/splash') {
        return '/onboarding';
      }

      if (onboardingComplete && location == '/onboarding') {
        // Same cached row as the guard above: this branch runs while the user
        // sits on /onboarding, so a second query here was the only other
        // network read in the navigation path.
        final profile = await loadProfile(session.user.id);

        final role = profile?['role']?.toString();
        return role == 'lecturer' ? '/lecturer' : '/student';
      }

      // Class gate: no dashboard (or any other role page) until the student
      // has joined a class / the lecturer has created one.
      final onRoleArea = location == '/student' ||
          location.startsWith('/student/') ||
          location == '/lecturer' ||
          location.startsWith('/lecturer/');
      if (onRoleArea) {
        final profile = await loadProfile(session.user.id);
        final role = profile?['role']?.toString();
        if (role == 'student' || role == 'lecturer') {
          final hasClass = await loadHasClass(session.user.id, role!);
          final gate = resolveClassGateRedirect(
            role: role,
            location: location,
            hasClass: hasClass,
          );
          if (gate != null) {
            return gate;
          }
        }
      }

      return null;
    },

    // Unknown locations have always fallen through to go_router's built-in
    // error screen, which is not localised and does not match the app shell.
    // This renders the same error widget the guarded routes use. It never signs
    // anyone out: a 404 says nothing about whether the session is valid.
    errorBuilder: (context, state) {
      return RouterErrorPage(
        message: AppLocalizations.of(context)!.pageNotFound,
      );
    },

    routes: [
      // =========================================================
      // ROOT
      // =========================================================

      GoRoute(path: '/', redirect: (context, state) => '/login'),

      // =========================================================
      // SPLASH
      // =========================================================
      //
      // `initialLocation` aplikasi. Splash tidak memutuskan tujuan sendiri:
      // di akhir animasi ia `context.go('/')` dan funnel `/` di atas (plus
      // guard di [resolveAuthRedirect]) yang menentukan login, onboarding,
      // atau dashboard sesuai sesi aktif. `/splash` sendiri lolos guard baik
      // dengan maupun tanpa sesi — periksanya di [resolveAuthRedirect].

      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const SplashPage();
        },
      ),

      // =========================================================
      // AUTH
      // =========================================================
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          return const ForgotPasswordPage();
        },
      ),

      // --------------------------------------------------------
      // SET NEW PASSWORD (recovery completion)
      // --------------------------------------------------------
      //
      // Step 2 of the recovery flow, entered only from ForgotPasswordPage once
      // the one-time code has been verified. It is intentionally *not* one of
      // the profile-guarded routes: the guard would bounce `/reset-password`
      // the moment the recovery code signs the user in, which is exactly when
      // the page is needed. Without a session it falls back to `/login`, where
      // there is nothing to change anyway.
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          return const ResetPasswordPage();
        },
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) {
          return const RegisterPage();
        },
      ),

      // --------------------------------------------------------
      // ONBOARDING
      // --------------------------------------------------------
      //
      // Language selection + the three-screen journey flow, shown
      // once after the user's first successful login (Make
      // `OnboardingFlow`). The redirect below sends an authenticated
      // user here when onboarding is not yet complete, and pushes
      // onward to the role area once the flow finishes at '/'.
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          return const OnboardingFlowPage();
        },
      ),

      // =========================================================
      // STUDENT
      // =========================================================
      GoRoute(
        path: '/student',
        builder: (context, state) {
          return const StudentDashboardPage();
        },
        routes: [
          // -------------------------------------------------------
          // DAFTAR MATERI
          // -------------------------------------------------------

          GoRoute(
            path: 'materials',
            builder: (context, state) {
              return const StudentMaterialsPage();
            },

            // ---------------------------------------------------
            // DAFTAR MATERI SATU MODUL
            //
            // Child dari `materials` supaya URIT menjadi
            // `/student/materials/1` dan tetap lolos role guard prefix
            // `/student/`. Segment `:moduleNumber` dijamin angka oleh
            // builder ini: string lain jatuh ke halaman error, bukan dipeta
            // ke modul 0.
            // ---------------------------------------------------
            routes: [
              GoRoute(
                path: ':moduleNumber',
                builder: (context, state) {
                  final moduleNumber =
                      int.tryParse(state.pathParameters['moduleNumber'] ?? '');

                  if (moduleNumber == null) {
                    return RouterErrorPage(
                      message:
                          AppLocalizations.of(context)!.failedToLoad,
                    );
                  }

                  return ModuleMaterialsPage(moduleNumber: moduleNumber);
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // DETAIL MATERI
          // -------------------------------------------------------
          GoRoute(
            path: 'material/:materialId',
            builder: (context, state) {
              final materialId = state.pathParameters['materialId'];

              if (materialId == null || materialId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.materialIdMissing,
                );
              }

              return MaterialDetailPage(materialId: materialId);
            },
          ),

          // -------------------------------------------------------
          // BACA MATERI
          // -------------------------------------------------------
          GoRoute(
            path: 'material/:materialId/read',
            builder: (context, state) {
              final materialId = state.pathParameters['materialId'];

              if (materialId == null || materialId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.materialIdMissing,
                );
              }

              return MaterialReaderPage(materialId: materialId);
            },
          ),

          // -------------------------------------------------------
          // VIDEO
          // -------------------------------------------------------
          GoRoute(
            path: 'video-list',
            builder: (context, state) {
              return const VideoListPage();
            },
          ),

          GoRoute(
            path: 'video/:materialId',
            builder: (context, state) {
              final materialId = state.pathParameters['materialId'];

              if (materialId == null || materialId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.videoMaterialIdMissing,
                );
              }

              return VideoPage(materialId: materialId);
            },
          ),

          // -------------------------------------------------------
          // PDF MATERI
          // -------------------------------------------------------
          GoRoute(
            path: 'material/:materialId/pdf',
            builder: (context, state) {
              final materialId = state.pathParameters['materialId'];

              if (materialId == null || materialId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.materialIdMissing,
                );
              }

              return PdfViewerPage(materialId: materialId);
            },
          ),

          // -------------------------------------------------------
          // INSTRUKSI ASSESSMENT (PRETEST)
          // -------------------------------------------------------
          GoRoute(
            path: 'assessment-instructions/:assessmentType',
            builder: (context, state) {
              final assessmentType = state.pathParameters['assessmentType'];

              if (assessmentType == null || assessmentType.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.assessmentTypeMissing,
                );
              }

              final isValidType = assessmentType == 'pretest' ||
                  assessmentType == 'posttest' ||
                  assessmentType == 'task' ||
                  RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(assessmentType);

              if (!isValidType) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.assessmentTypeInvalid,
                );
              }

              return AssessmentInstructionsPage(assessmentType: assessmentType);
            },
          ),

          // =======================================================
          // ASSESSMENT
          // =======================================================
          GoRoute(
            path: 'assessment',
            builder: (context, state) {
              return const AssessmentListPage();
            },
            routes: [
              // ---------------------------------------------------
              // PENGERJAAN ASSESSMENT
              // ---------------------------------------------------

              GoRoute(
                path: ':assessmentType',
                builder: (context, state) {
                  final assessmentType = state.pathParameters['assessmentType'];

                  if (assessmentType == null || assessmentType.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!
                          .assessmentTypeMissing,
                    );
                  }

                  final isValidType = assessmentType == 'pretest' ||
                      assessmentType == 'posttest' ||
                      assessmentType == 'task' ||
                      RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(assessmentType);

                  if (!isValidType) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!
                          .assessmentTypeInvalid,
                    );
                  }

                  return AssessmentPage(assessmentType: assessmentType);
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // HASIL ASSESSMENT
          // -------------------------------------------------------
          GoRoute(
            path: 'assessment-result/:attemptId',
            builder: (context, state) {
              final attemptId = state.pathParameters['attemptId'];

              if (attemptId == null || attemptId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!
                      .assessmentResultIdMissing,
                );
              }

              return AssessmentResultPage(attemptId: attemptId);
            },
          ),

          // -------------------------------------------------------
          // RIWAYAT ASSESSMENT
          // -------------------------------------------------------
          GoRoute(
            path: 'assessment-history',
            builder: (context, state) {
              return const StudentAssessmentHistoryPage();
            },
          ),

           GoRoute(
             path: 'virtual-lab',
             builder: (context, state) {
               final labBinding = state.extra is MaterialLabBinding
                   ? state.extra as MaterialLabBinding
                   : null;
               return VirtualLabPage(labBinding: labBinding);
             },
           ),

           GoRoute(
             path: 'subnet-drill',
             builder: (context, state) {
               return const UnderDevelopmentPage(title: 'Speed Drill');
             },
           ),

          // -------------------------------------------------------
          GoRoute(
            path: 'leaderboard',
            builder: (context, state) {
              return ClassLeaderboardPage(
                classId: state.uri.queryParameters['classId'],
              );
            },
          ),
          GoRoute(
            path: 'discussions',
            builder: (context, state) {
              return ClassDiscussionPage(
                classId: state.uri.queryParameters['classId'],
                initialModuleNumber: int.tryParse(
                  state.uri.queryParameters['module'] ?? '',
                ),
                initialMaterialId: state.uri.queryParameters['materialId'],
                isLecturer: false,
              );
            },
            routes: [
              GoRoute(
                path: ':threadId',
                builder: (context, state) {
                  final threadId = state.pathParameters['threadId'] ?? '';
                  return DiscussionThreadDetailPage(
                    threadId: threadId,
                    isLecturer: false,
                  );
                },
              ),
            ],
          ),
          // AR SCANNER
          // -------------------------------------------------------
          GoRoute(
            path: 'ar',
            builder: (context, state) {
              return const UnderDevelopmentPage(title: 'AR Scanner');
            },
          ),

          // -------------------------------------------------------
          // NOTIFIKASI
          //
          // Tujuan "View All Notifications" pada dashboard. Panel lonceng tetap
          // memakai overlay yang sama; halaman ini yang memuat daftar penuhnya,
          // jadi keduanya membaca provider yang sama.
          // -------------------------------------------------------
          GoRoute(
            path: 'notifications',
            builder: (context, state) {
              return const StudentNotificationsPage();
            },
          ),

          // -------------------------------------------------------
          // TENTANG APLIKASI
          //
          // Tujuan tombol `?` di hero dashboard. Halaman ini bercabang dari
          // dashboard, bukan tab tersendiri, jadi tab Dashboard tetap aktif.
          // -------------------------------------------------------
          GoRoute(
            path: 'about',
            builder: (context, state) {
              return const StudentAboutPage();
            },
          ),

          // -------------------------------------------------------
          // PROFIL
          // -------------------------------------------------------
          GoRoute(
            path: 'profile',
            builder: (context, state) {
              return const StudentProfilePage();
            },
          ),

          // -------------------------------------------------------
          // PROFIL — SUB-HALAMAN
          //
          // Mirrors the lecturer side so both roles walk the same path:
          // Profile Information -> Academic Information -> Security. The rows
          // on `/student/profile` push here and each page falls back safely.
          // -------------------------------------------------------
          GoRoute(
            path: 'profile-info',
            builder: (context, state) {
              return const StudentProfileInfoPage();
            },
          ),

          GoRoute(
            path: 'academic',
            builder: (context, state) {
              return const StudentAcademicInfoPage();
            },
          ),

          GoRoute(
            path: 'security',
            builder: (context, state) {
              return const StudentSecurityPage();
            },
            routes: [
              GoRoute(
                path: 'change-password',
                builder: (context, state) {
                  // Form ubah kata sandi yang sama dengan dosen; navbar
                  // bawah tidak dibawa karena sub-page profil mahasiswa
                  // yang lain juga tidak membawanya.
                  return ChangePasswordPage(
                    useStudentProfile: true,
                    backFallback: '/student/security',
                  );
                },
              ),
            ],
          ),

          // FORGOT PASSWORD (student entry point)
          GoRoute(
            path: 'class-onboarding',
            builder: (context, state) {
              return ClassOnboardingPage(
                role: ClassOnboardingRole.student,
                hasExistingClass:
                    state.uri.queryParameters['required'] != '1',
              );
            },
          ),
          //
          // Satu lagi penggunaan [ForgotPasswordPage] yang sama dengan
          // kombinasi entry point lainnya. Nested di bawah /student karena
          // `/forgot-password` yang publik dibuang oleh auth guard ketika
          // mahasiswa sedang login — bug yang sama dengan yang menyebabkan
          // cabang /lecturer/forgot-password dibuat.
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              return const ForgotPasswordPage();
            },
          ),
        ],
      ),

      // =========================================================
      // LECTURER
      // =========================================================
      GoRoute(
        path: '/lecturer',
        builder: (context, state) {
          return const LecturerDashboardPage();
        },
        routes: [
          // -------------------------------------------------------
          // -------------------------------------------------------
          // KELOLA KELAS (v7 Multi-Class LMS)
          GoRoute(
            path: 'class-onboarding',
            builder: (context, state) {
              return ClassOnboardingPage(
                role: ClassOnboardingRole.lecturer,
                hasExistingClass:
                    state.uri.queryParameters['required'] != '1',
              );
            },
          ),
          // -------------------------------------------------------
          GoRoute(
            path: 'classes',
            builder: (context, state) {
              return const LecturerManageClassesPage();
            },
          ),
          GoRoute(
            path: 'classes/create',
            builder: (context, state) {
              return const LecturerCreateClassPage();
            },
          ),
          GoRoute(
            path: 'classes/archived',
            builder: (context, state) {
              return const LecturerArchivedClassesPage();
            },
          ),
          GoRoute(
            path: 'classes/:classId',
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              return LecturerClassDetailPage(classId: classId);
            },
            routes: [
              GoRoute(
                path: 'leaderboard',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'];
                  return ClassLeaderboardPage(classId: classId);
                },
              ),
              GoRoute(
                path: 'discussions',
                builder: (context, state) {
                  final classId = state.pathParameters['classId'];
                  return ClassDiscussionPage(
                    classId: classId,
                    isLecturer: true,
                  );
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // KELOLA MATERI
          // -------------------------------------------------------

          GoRoute(
            path: 'materials',
            builder: (context, state) {
              return const LecturerMaterialsPage();
            },
            routes: [
              // ---------------------------------------------------
              // TAMBAH MATERI
              //
              // Registered before the ':materialId' sibling so the literal
              // segment wins; GoRouter matches in order.
              // ---------------------------------------------------

              GoRoute(
                path: 'create',
                builder: (context, state) {
                  return LecturerMaterialFormPage(
                    classId: state.uri.queryParameters['classId'],
                    moduleId: state.uri.queryParameters['moduleId'],
                    initialModuleNumber: int.tryParse(
                      state.uri.queryParameters['moduleNumber'] ?? '',
                    ),
                  );
                },
              ),

              // ---------------------------------------------------
              // BACA MATERI (lecturer)
              //
              // Dosen melihat materi seperti mahasiswa: dari sini body
              // materi tampil penuh, tanpa footer progres mahasiswa
              // (`fromLecturer`). MaterialDetailPage tidak pernah
              // menampilkan isi bacaan, jadi route ini tidak lagi menyeret
              // dosen ke halaman ringkas yang kosong.
              // ---------------------------------------------------
              GoRoute(
                path: ':materialId/view',
                builder: (context, state) {
                  final materialId = state.pathParameters['materialId'];

                  if (materialId == null || materialId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!.materialIdMissing,
                    );
                  }

                  return MaterialReaderPage(
                    materialId: materialId,
                    fromLecturer: true,
                  );
                },
              ),

              // ---------------------------------------------------
              // EDIT MATERI
              // ---------------------------------------------------
              GoRoute(
                path: ':materialId/edit',
                builder: (context, state) {
                  final materialId = state.pathParameters['materialId'];

                  if (materialId == null || materialId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!.materialIdMissing,
                    );
                  }

                  return LecturerMaterialFormPage(materialId: materialId);
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // PDF MATERI (lecturer)
          //
          // Sibling dari `materials` — bukan nested di dalamnya — supaya
          // lokasinya `/lecturer/material/:materialId/pdf`, target yang
          // sama dengan yang di-push reader bentuk dosen. Route mahasiswa
          // `/student/material/:materialId/pdf` tidak berubah.
          // -------------------------------------------------------
          GoRoute(
            path: 'material/:materialId/pdf',
            builder: (context, state) {
              final materialId = state.pathParameters['materialId'];

              if (materialId == null || materialId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.materialIdMissing,
                );
              }

              return PdfViewerPage(
                materialId: materialId,
                fromLecturer: true,
              );
            },
          ),

          // -------------------------------------------------------
          // KELOLA ASSESSMENT
          // -------------------------------------------------------
          GoRoute(
            path: 'assessments',
            builder: (context, state) {
              return const LecturerAssessmentsPage();
            },
            routes: [
              GoRoute(
                path: ':quizId/questions',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId'];

                  if (quizId == null || quizId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!
                          .assessmentTypeMissing,
                    );
                  }

                  return LecturerQuestionsPage(quizId: quizId);
                },
              ),

              // Add a question. A page rather than the modal sheet the list used
              // to open, matching the design's `question-form` screen; the form
              // writes the row and invalidates the list itself.
              GoRoute(
                path: ':quizId/questions/create',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId'];

                  if (quizId == null || quizId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!
                          .assessmentTypeMissing,
                    );
                  }

                  return LecturerQuestionFormPage(quizId: quizId);
                },
              ),

              // Edit a question. The id is a path parameter rather than an
              // object passed through `extra`, so a restored route resolves the
              // question from the same assessment it belongs to.
              GoRoute(
                path: ':quizId/questions/:questionId/edit',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId'];
                  final questionId = state.pathParameters['questionId'];

                  if (quizId == null ||
                      quizId.isEmpty ||
                      questionId == null ||
                      questionId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!
                          .assessmentTypeMissing,
                    );
                  }

                  return LecturerQuestionFormPage(
                    quizId: quizId,
                    questionId: questionId,
                  );
                },
              ),

              // ---------------------------------------------------
              // TASK ROUTES (assessment_type = 'task')
              // ---------------------------------------------------

              // Create new task
              GoRoute(
                path: 'task/create',
                builder: (context, state) {
                  return const LecturerTaskFormPage();
                },
              ),

              // Task detail
              GoRoute(
                path: 'task/:taskId',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'];

                  if (taskId == null || taskId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!.taskIdMissing,
                    );
                  }

                  return LecturerTaskDetailPage(taskId: taskId);
                },
              ),

              // Edit task
              GoRoute(
                path: 'task/:taskId/edit',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'];

                  if (taskId == null || taskId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!.taskIdMissing,
                    );
                  }

                  return LecturerTaskFormPage(taskId: taskId);
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // LEARNING VIDEO
          // -------------------------------------------------------
          GoRoute(
            path: 'video-list',
            builder: (context, state) {
              return const VideoListPage();
            },
          ),

          // The player itself. Same page as the student side (`VideoPage`);
          // the lecturer branch exists only so the role guard never bounces a
          // lecturer off a `/student/video/...` push back to the dashboard.
          GoRoute(
            path: 'video/:materialId',
            builder: (context, state) {
              final materialId = state.pathParameters['materialId'];

              if (materialId == null || materialId.isEmpty) {
                return RouterErrorPage(
                  message: AppLocalizations.of(context)!.videoMaterialIdMissing,
                );
              }

              return VideoPage(materialId: materialId);
            },
          ),

          // -------------------------------------------------------
          // VIRTUAL LAB
          // -------------------------------------------------------
          //
          // The student page is reused as-is: the 2D topology editor has no
          // student-only data, and the canvas is stored per account
          // (`virtual_lab_canvases`), so a lecturer editing the lab gets their
          // own canvas instead of seeing a student's. The separate /lecturer
          // route exists so the role guard does not bounce the lecturer back to
          // /lecturer; a student opening it is bounced to /student.
          GoRoute(
            path: 'virtual-lab',
            builder: (context, state) {
              final labBinding = state.extra is MaterialLabBinding
                  ? state.extra as MaterialLabBinding
                  : null;
              return VirtualLabPage(labBinding: labBinding);
            },
          ),

          // -------------------------------------------------------
          GoRoute(
            path: 'leaderboard',
            builder: (context, state) {
              return ClassLeaderboardPage(
                classId: state.uri.queryParameters['classId'],
              );
            },
          ),
          GoRoute(
            path: 'discussions',
            builder: (context, state) {
              return ClassDiscussionPage(
                classId: state.uri.queryParameters['classId'],
                initialModuleNumber: int.tryParse(
                  state.uri.queryParameters['module'] ?? '',
                ),
                initialMaterialId: state.uri.queryParameters['materialId'],
                isLecturer: true,
              );
            },
            routes: [
              GoRoute(
                path: ':threadId',
                builder: (context, state) {
                  final threadId = state.pathParameters['threadId'] ?? '';
                  return DiscussionThreadDetailPage(
                    threadId: threadId,
                    isLecturer: true,
                  );
                },
              ),
            ],
          ),
          // AR SCANNER
          // -------------------------------------------------------
          //
          // Separate route from /student/ar on purpose so a lecturer never
          // lands on the student navbar. The role guard in the redirect now
          // also covers these deep links, so a student opening /lecturer/ar
          // is bounced back to /student.
          GoRoute(
            path: 'ar',
            builder: (context, state) {
              return const UnderDevelopmentPage(title: 'AR Scanner');
            },
          ),

          // -------------------------------------------------------
          // PROFIL
          // -------------------------------------------------------
          GoRoute(
            path: 'profile',
            builder: (context, state) {
              return const LecturerProfilePage();
            },
          ),

          GoRoute(
            path: 'profile-info',
            builder: (context, state) {
              return const LecturerProfileInfoPage();
            },
          ),

          GoRoute(
            path: 'academic',
            builder: (context, state) {
              return const LecturerAcademicInfoPage();
            },
          ),

          GoRoute(
            path: 'security',
            builder: (context, state) {
              return const LecturerSecurityPage();
            },
            routes: [
              GoRoute(
                path: 'change-password',
                builder: (context, state) {
                  return const LecturerChangePasswordPage();
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // FORGOT PASSWORD (lecturer entry point)
          //
          // Reuses the same ForgotPasswordPage as the login entry point.
          // Nested under /lecturer so an authenticated lecturer is not bounced
          // by the login/register/forgot-password auth guard.
          // -------------------------------------------------------
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              return const ForgotPasswordPage();
            },
          ),

          // -------------------------------------------------------
          // ABOUT (lecturer)
          // -------------------------------------------------------
          GoRoute(
            path: 'about',
            builder: (context, state) {
              return const LecturerAboutPage();
            },
          ),

          // -------------------------------------------------------
          // NOTIFIKASI (lecturer)
          // -------------------------------------------------------
          GoRoute(
            path: 'notifications',
            builder: (context, state) {
              return const LecturerNotificationsPage();
            },
          ),

          // -------------------------------------------------------
          // STUDENT LIST (lecturer)
          // -------------------------------------------------------
          GoRoute(
            path: 'students',
            builder: (context, state) {
              return const LecturerStudentListPage();
            },

            // Detail "Rekap Nilai Mahasiswa" untuk satu mahasiswa —
            // pengganti bottom sheet lama yang berisiko overflow di 360dp.
            // studentId kosong/malformed jatuh ke RouterErrorPage, bukan
            // halaman kosong tanpa petunjuk.
            routes: [
              GoRoute(
                path: ':studentId',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId'] ?? '';
                  if (studentId.isEmpty) {
                    return RouterErrorPage(
                      message:
                          AppLocalizations.of(context)!.profileNotFound,
                    );
                  }

                  return LecturerStudentScoreDetailPage(
                    studentId: studentId,
                  );
                },
              ),
            ],
          ),

          // -------------------------------------------------------
          // ANNOUNCEMENTS
          // -------------------------------------------------------
          GoRoute(
            path: 'announcements',
            builder: (context, state) {
              return const LecturerAnnouncementListPage();
            },
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  return const LecturerAnnouncementFormPage();
                },
              ),
              GoRoute(
                path: ':announcementId/edit',
                builder: (context, state) {
                  final announcementId = state.pathParameters['announcementId'];

                  if (announcementId == null || announcementId.isEmpty) {
                    return RouterErrorPage(
                      message: AppLocalizations.of(context)!.materialIdMissing,
                    );
                  }

                  return LecturerAnnouncementFormPage(
                    announcementId: announcementId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Whether the signed-in account has completed the onboarding flow.
///
/// The status is the account's Supabase auth user metadata
/// (`onboarding_status.dart`), not a device boolean: a per-account flag is
/// what lets the flow appear for a fresh account on any device and stay away
/// for an account that already finished it. Kept as a wrapper so the router
/// redirect can await it behind one named call.
Future<bool> _isOnboardingComplete() =>
    isOnboardingCompleteForCurrentUser();
