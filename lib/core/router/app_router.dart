import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/lecturer',
    routes: [
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
            ],
          ),
        ],
      ),
    ],
  );
});
