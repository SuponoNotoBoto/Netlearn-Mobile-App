import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/reset_password_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/dashboard_lecturer/lecturer_academic_info_page.dart';
import '../../features/dashboard_lecturer/lecturer_assessments_page.dart';
import '../../features/dashboard_lecturer/lecturer_change_password_page.dart';
import '../../features/dashboard_lecturer/lecturer_dashboard_page.dart';
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
import '../../features/notifications/student_notifications_page.dart';
import '../session/session_reset.dart';
import '../supabase/supabase_client.dart';
import 'profile_cache.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final profileCache = ProfileCache();

  Future<Map<String, dynamic>?> loadProfile(String userId) async {
    final cached = profileCache.read(userId);
    if (cached != null) {
      return cached;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role, is_active')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        profileCache.write(userId, profile);
      }
      return profile;
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return null;
    }
  }

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      final location = state.matchedLocation;

      // Allow splash to run without early redirect
      if (location == '/splash') {
        return null;
      }

      final isPublicAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password';

      if (session == null) {
        if (isPublicAuthRoute) {
          return null;
        }
        return '/login';
      }

      // User has session, load profile and role
      final profile = await loadProfile(session.user.id);
      final role = profile?['role']?.toString();
      final isActive = profile?['is_active'] as bool? ?? false;

      // Invalid profile or deactivated account -> kick to login
      if (!isActive || (role != 'student' && role != 'lecturer')) {
        profileCache.clear();
        await supabase.auth.signOut();
        resetUserSession(ref);
        return '/login';
      }

      // If user is at root or public auth page, bounce to role dashboard
      if (location == '/' || isPublicAuthRoute) {
        return role == 'lecturer' ? '/lecturer' : '/student';
      }

      // Cross-role guard
      final onStudentRoute =
          location == '/student' || location.startsWith('/student/');
      final onLecturerRoute =
          location == '/lecturer' || location.startsWith('/lecturer/');

      if (role == 'student' && onLecturerRoute) {
        return '/student';
      }

      if (role == 'lecturer' && onStudentRoute) {
        return '/lecturer';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboardPage(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const StudentNotificationsPage(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/lecturer',
        builder: (context, state) => const LecturerDashboardPage(),
        routes: [
          GoRoute(
            path: 'assessments',
            builder: (context, state) => const LecturerAssessmentsPage(),
            routes: [
              GoRoute(
                path: ':quizId/questions',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId'] ?? '';
                  return LecturerQuestionsPage(quizId: quizId);
                },
              ),
              GoRoute(
                path: ':quizId/questions/create',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId'] ?? '';
                  return LecturerQuestionFormPage(quizId: quizId);
                },
              ),
              GoRoute(
                path: ':quizId/questions/:questionId/edit',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId'] ?? '';
                  final questionId = state.pathParameters['questionId'];
                  return LecturerQuestionFormPage(
                    quizId: quizId,
                    questionId: questionId,
                  );
                },
              ),
              GoRoute(
                path: 'task/create',
                builder: (context, state) => const LecturerTaskFormPage(),
              ),
              GoRoute(
                path: 'task/:taskId',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'] ?? '';
                  return LecturerTaskDetailPage(taskId: taskId);
                },
              ),
              GoRoute(
                path: 'task/:taskId/edit',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId'];
                  return LecturerTaskFormPage(taskId: taskId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'students',
            builder: (context, state) => const LecturerStudentListPage(),
            routes: [
              GoRoute(
                path: ':studentId',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId'] ?? '';
                  return LecturerStudentScoreDetailPage(studentId: studentId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const LecturerProfilePage(),
            routes: [
              GoRoute(
                path: 'info',
                builder: (context, state) => const LecturerProfileInfoPage(),
              ),
              GoRoute(
                path: 'security',
                builder: (context, state) => const LecturerSecurityPage(),
              ),
              GoRoute(
                path: 'change-password',
                builder: (context, state) => const LecturerChangePasswordPage(),
              ),
              GoRoute(
                path: 'academic',
                builder: (context, state) => const LecturerAcademicInfoPage(),
              ),
              GoRoute(
                path: 'forgot-password',
                builder: (context, state) => const ForgotPasswordPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
