// ============================================================================
// MODULE: Application Router & Role-Based Navigation Guard
// DESCRIPTION: Mengatur seluruh rute navigasi aplikasi menggunakan GoRouter,
//              dilengkapi dengan Auth Guard (proteksi sesi & peran pengguna),
//              Onboarding Gate, serta Class Gate (wajib bergabung/membuat kelas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/onboarding_status.dart';
import '../../features/about/student_about_page.dart';
import '../../features/subnet_drill/subnet_drill_page.dart';
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

// ---------------------------------------------------------------------------
// SECTION: Router Refresh Stream & Guard Decision Models
// ---------------------------------------------------------------------------

/// [GoRouterRefreshStream]
///
/// Mengonversi stream perubahan status autentikasi (`onAuthStateChange`) menjadi
/// [ChangeNotifier] agar [GoRouter] mengevaluasi ulang redirect secara otomatis
/// setiap kali pengguna login atau logout.
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

/// [AuthRedirect]
///
/// Merepresentasikan hasil keputusan dari fungsi evaluasi Auth Guard:
/// - [location]: Rute tujuan pengalihan (`null` berarti navigasi diizinkan lewat).
/// - [signOut]: Menandakan apakah sesi pengguna harus dihentikan (misal karena akun
///   tidak aktif atau peran tidak dikenali) sebelum dialihkan.
class AuthRedirect {
  const AuthRedirect(this.location, {this.signOut = false});

  final String? location;
  final bool signOut;
}

// ---------------------------------------------------------------------------
// SECTION: Pure Role & Session Guard Logic
// ---------------------------------------------------------------------------

/// [authRedirectNeedsProfile]
///
/// Menentukan apakah suatu rute memerlukan pemeriksaan data profil (`role` & `is_active`).
/// Dipisahkan dari [resolveAuthRedirect] agar router hanya melakukan pembacaan profil
/// saat benar-benar dibutuhkan oleh rute tujuan.
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

/// [resolveAuthRedirect]
///
/// Fungsi murni (pure function) untuk mengevaluasi aturan akses berbasis peran (RBAC):
/// - Hanya peran `student` dan `lecturer` yang diizinkan.
/// - Jika profil tidak ditemukan, akun nonaktif (`!isActive`), atau peran tidak valid,
///   pengguna akan di-sign out dan dikembalikan ke `/login`.
/// - Mencegah akses silang (cross-role deep-linking) antara `/student` dan `/lecturer`.
AuthRedirect resolveAuthRedirect({
  required bool hasSession,
  required String location,
  required String? role,
  required bool isActive,
}) {
  // Rute '/admin' sudah dihapus dari sistem: setiap percobaan navigasi ke sana
  // wajib diakhiri sesinya dan diarahkan kembali ke halaman login.
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
    // Rute `/splash` diizinkan tampil tanpa sesi aktif agar animasi pembuka
    // tetap berjalan sebelum diarahkan ke `/login`.
    if (location == '/splash') {
      return const AuthRedirect(null);
    }

    if (location == '/' || (!loggingIn && !registering && !resettingPassword)) {
      return const AuthRedirect('/login');
    }

    return const AuthRedirect(null);
  }

  // Pengguna yang sudah login tidak boleh kembali ke halaman login/register;
  // alihkan langsung ke area dashboard sesuai perannya.
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

// ---------------------------------------------------------------------------
// SECTION: Multi-Class Membership Gate (Google Classroom Style)
// ---------------------------------------------------------------------------

/// Konstanta rute onboarding kelas untuk Mahasiswa dan Dosen.
const String kStudentClassOnboardingPath = '/student/class-onboarding';
const String kLecturerClassOnboardingPath = '/lecturer/class-onboarding';

/// [resolveClassGateRedirect]
///
/// Memastikan mahasiswa telah bergabung ke minimal satu kelas dan dosen telah
/// membuat minimal satu kelas sebelum dapat mengakses fitur utama di dashboard.
/// Jika [hasClass] bernilai `null` (misal karena gangguan jaringan sementara),
/// gate dibiarkan terbuka agar aplikasi tidak mengunci pengguna.
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

/// [ClassMembershipCache]
///
/// Menyimpan status kepemilikan kelas secara in-memory selama sesi aktif.
/// Hanya status positif (`true`) yang di-cache agar setelah pengguna bergabung
/// atau membuat kelas, navigasi berikutnya berlangsung instan tanpa query berulang.
class ClassMembershipCache {
  String? _userId;

  bool hasClass(String userId) => _userId == userId;

  void markHasClass(String userId) => _userId = userId;

  void clear() => _userId = null;
}

/// [evaluateAuthRedirect]
///
/// Orkestrator asinkron di sekitar [resolveAuthRedirect] yang mengeksekusi
/// pembacaan profil serta efek samping sign-out & pembersihan sesi jika diperlukan.
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

// ---------------------------------------------------------------------------
// SECTION: GoRouter Provider & Route Tree Configuration
// ---------------------------------------------------------------------------

/// [appRouterProvider]
///
/// Provider utama yang membangun instance [GoRouter] beserta mekanisme caching
/// profil, evaluasi guard berlapis, dan definisi pohon rute (route tree).
final appRouterProvider = Provider<GoRouter>((ref) {
  // Menggunakan cache profil in-memory agar setiap perpindahan halaman (push/pop)
  // tidak terhambat oleh latensi query jaringan ke tabel `profiles`.
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

  /// Memeriksa apakah pengguna sudah memiliki kelas aktif melalui RPC Supabase.
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
    // Aplikasi selalu dimulai dari `/splash` saat cold-start, lalu diarahkan
    // ke `/` setelah animasi selesai untuk dievaluasi oleh Auth Guard.
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      final location = state.matchedLocation;

      // ---------------------------------------------------------------------
      // STEP 1: Role & Session Authentication Guard
      // ---------------------------------------------------------------------
      final decision = await evaluateAuthRedirect(
        userId: session?.user.id,
        location: location,
        loadProfile: loadProfile,
        signOut: () => supabase.auth.signOut(),
        resetSession: () {
          // Bersihkan seluruh cache sesi agar tidak bocor ke akun berikutnya.
          profileCache.clear();
          classMembershipCache.clear();
          resetUserSession(ref);
        },
      );

      if (decision.location != null) {
        return decision.location;
      }

      if (session == null) {
        return null;
      }

      // ---------------------------------------------------------------------
      // STEP 2: First-Time User Onboarding Gate
      // ---------------------------------------------------------------------
      final onboardingComplete = await _isOnboardingComplete();

      // Halaman `/reset-password` dan `/splash` dikecualikan dari pencegatan
      // onboarding agar alur pemulihan sandi dan animasi awal tidak terputus.
      if (!onboardingComplete &&
          location != '/onboarding' &&
          location != '/reset-password' &&
          location != '/splash') {
        return '/onboarding';
      }

      if (onboardingComplete && location == '/onboarding') {
        final profile = await loadProfile(session.user.id);

        final role = profile?['role']?.toString();
        return role == 'lecturer' ? '/lecturer' : '/student';
      }

      // ---------------------------------------------------------------------
      // STEP 3: Active Class Membership Gate
      // ---------------------------------------------------------------------
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

    // Menampilkan halaman error kustom yang terlokalisasi jika rute tidak ditemukan (404).
    errorBuilder: (context, state) {
      return RouterErrorPage(
        message: AppLocalizations.of(context)!.pageNotFound,
      );
    },

    routes: [
      // =====================================================================
      // SECTION: Root & Splash Routes
      // =====================================================================

      GoRoute(path: '/', redirect: (context, state) => '/login'),

      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const SplashPage();
        },
      ),

      // =====================================================================
      // SECTION: Public Authentication & Onboarding Routes
      // =====================================================================
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

      // Langkah ke-2 pemulihan kata sandi setelah pengguna memverifikasi kode OTP.
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

      // Alur pemilihan bahasa & pengenalan fitur untuk pengguna yang baru pertama kali login.
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          return const OnboardingFlowPage();
        },
      ),

      // =====================================================================
      // SECTION: Student Role Routes (/student/*)
      // =====================================================================
      GoRoute(
        path: '/student',
        builder: (context, state) {
          return const StudentDashboardPage();
        },
        routes: [
          // -----------------------------------------------------------------
          // SUB-SECTION: Learning Modules & Materials
          // -----------------------------------------------------------------

          GoRoute(
            path: 'materials',
            builder: (context, state) {
              return const StudentMaterialsPage();
            },
            routes: [
              // Menampilkan daftar materi dalam satu modul spesifik (:moduleNumber).
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

          // Detail ringkasan materi pembelajaran
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

          // Halaman pembaca materi interaktif (dilengkapi integrasi AI NetBot & Virtual Lab)
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

          // -----------------------------------------------------------------
          // SUB-SECTION: Video & PDF Viewers
          // -----------------------------------------------------------------
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

          // -----------------------------------------------------------------
          // SUB-SECTION: Student Assessments & Quizzes
          // -----------------------------------------------------------------
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

          GoRoute(
            path: 'assessment',
            builder: (context, state) {
              return const AssessmentListPage();
            },
            routes: [
              // Halaman pengerjaan soal ujian/kuis
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

          // Halaman hasil skor setelah menyelesaikan assessment
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

          // Riwayat seluruh percobaan assessment mahasiswa
          GoRoute(
            path: 'assessment-history',
            builder: (context, state) {
              return const StudentAssessmentHistoryPage();
            },
          ),

          // -----------------------------------------------------------------
          // SUB-SECTION: Interactive Simulators (Virtual Lab & Subnet Drill)
          // -----------------------------------------------------------------
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
              return const SubnetDrillPage();
            },
          ),


          // -----------------------------------------------------------------
          // SUB-SECTION: Class Leaderboard, Discussions & Extras
          // -----------------------------------------------------------------
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

          GoRoute(
            path: 'ar',
            builder: (context, state) {
              return const UnderDevelopmentPage(title: 'AR Scanner');
            },
          ),

          // -----------------------------------------------------------------
          // SUB-SECTION: Notifications, About & Student Profile
          // -----------------------------------------------------------------
          GoRoute(
            path: 'notifications',
            builder: (context, state) {
              return const StudentNotificationsPage();
            },
          ),

          GoRoute(
            path: 'about',
            builder: (context, state) {
              return const StudentAboutPage();
            },
          ),

          GoRoute(
            path: 'profile',
            builder: (context, state) {
              return const StudentProfilePage();
            },
          ),

          // Sub-halaman pengaturan profil, informasi akademik, dan keamanan akun mahasiswa
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
                  return ChangePasswordPage(
                    useStudentProfile: true,
                    backFallback: '/student/security',
                  );
                },
              ),
            ],
          ),

          // Halaman onboarding bergabung ke kelas menggunakan kode kelas 6 karakter
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

          // Entry point lupa kata sandi khusus mahasiswa yang sedang dalam sesi login
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              return const ForgotPasswordPage();
            },
          ),
        ],
      ),

      // =====================================================================
      // SECTION: Lecturer Role Routes (/lecturer/*)
      // =====================================================================
      GoRoute(
        path: '/lecturer',
        builder: (context, state) {
          return const LecturerDashboardPage();
        },
        routes: [
          // -----------------------------------------------------------------
          // SUB-SECTION: Multi-Class LMS Management
          // -----------------------------------------------------------------
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

          // -----------------------------------------------------------------
          // SUB-SECTION: Course Material Management (CRUD & AI Generator)
          // -----------------------------------------------------------------
          GoRoute(
            path: 'materials',
            builder: (context, state) {
              return const LecturerMaterialsPage();
            },
            routes: [
              // Form pembuatan materi baru (didahulukan sebelum `:materialId` agar segmen literal cocok lebih dulu)
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

              // Pratinjau bacaan materi dari sisi dosen (`fromLecturer: true`)
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

              // Form penyuntingan materi yang sudah ada
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

          // Penampil dokumen PDF materi untuk dosen
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

          // -----------------------------------------------------------------
          // SUB-SECTION: Assessment, Quiz & Task Management
          // -----------------------------------------------------------------
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

              // Halaman pembuatan butir soal kuis baru
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

              // Halaman penyuntingan butir soal kuis berdasarkan ID soal
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

              // Rute pengelolaan Tugas / Task (`assessment_type = 'task'`)
              GoRoute(
                path: 'task/create',
                builder: (context, state) {
                  return const LecturerTaskFormPage();
                },
              ),

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

          // -----------------------------------------------------------------
          // SUB-SECTION: Lecturer Learning Video & Virtual Lab Sandbox
          // -----------------------------------------------------------------
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

          // Virtual Lab untuk Dosen: menggunakan kanvas tersendiri per akun dosen
          GoRoute(
            path: 'virtual-lab',
            builder: (context, state) {
              final labBinding = state.extra is MaterialLabBinding
                  ? state.extra as MaterialLabBinding
                  : null;
              return VirtualLabPage(labBinding: labBinding);
            },
          ),

          // -----------------------------------------------------------------
          // SUB-SECTION: Lecturer Leaderboard, Discussions & AR
          // -----------------------------------------------------------------
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

          GoRoute(
            path: 'ar',
            builder: (context, state) {
              return const UnderDevelopmentPage(title: 'AR Scanner');
            },
          ),

          // -----------------------------------------------------------------
          // SUB-SECTION: Lecturer Profile, Students Score & Announcements
          // -----------------------------------------------------------------
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

          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              return const ForgotPasswordPage();
            },
          ),

          GoRoute(
            path: 'about',
            builder: (context, state) {
              return const LecturerAboutPage();
            },
          ),

          GoRoute(
            path: 'notifications',
            builder: (context, state) {
              return const LecturerNotificationsPage();
            },
          ),

          // Daftar mahasiswa dan rincian rekap nilai per mahasiswa
          GoRoute(
            path: 'students',
            builder: (context, state) {
              return const LecturerStudentListPage();
            },
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

          // Pengelolaan pengumuman kelas oleh dosen
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

/// [_isOnboardingComplete]
///
/// Memeriksa apakah akun pengguna yang sedang login telah menyelesaikan alur
/// onboarding (tersimpan pada user metadata Supabase Auth).
Future<bool> _isOnboardingComplete() =>
    isOnboardingCompleteForCurrentUser();
