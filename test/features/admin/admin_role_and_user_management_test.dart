import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/core/router/app_router.dart';
import 'package:netlearn/features/admin/user_management_models.dart';
import 'package:netlearn/features/auth/auth_controller.dart';
import 'package:netlearn/features/dashboard_lecturer/lecturer_dashboard_controller.dart';

void main() {
  group('Role Admin Auth & Routing', () {
    test('AppUserRole contains student, lecturer, and admin with correct values', () {
      expect(AppUserRole.student.value, 'student');
      expect(AppUserRole.lecturer.value, 'lecturer');
      expect(AppUserRole.admin.value, 'admin');
    });

    test('resolveAuthRedirect sends active admin to /lecturer from /login or /student', () {
      final fromLogin = resolveAuthRedirect(
        hasSession: true,
        location: '/login',
        role: 'admin',
        isActive: true,
      );
      expect(fromLogin.location, '/lecturer');
      expect(fromLogin.signOut, isFalse);

      final fromStudent = resolveAuthRedirect(
        hasSession: true,
        location: '/student',
        role: 'admin',
        isActive: true,
      );
      expect(fromStudent.location, '/lecturer');
      expect(fromStudent.signOut, isFalse);
    });

    test('resolveAuthRedirect allows active admin on /lecturer and /admin/users', () {
      final onLecturer = resolveAuthRedirect(
        hasSession: true,
        location: '/lecturer',
        role: 'admin',
        isActive: true,
      );
      expect(onLecturer.location, isNull);

      final onAdminUsers = resolveAuthRedirect(
        hasSession: true,
        location: '/admin/users',
        role: 'admin',
        isActive: true,
      );
      expect(onAdminUsers.location, isNull);
    });

    test('resolveAuthRedirect prevents student and lecturer from accessing /admin/users', () {
      final studentOnAdmin = resolveAuthRedirect(
        hasSession: true,
        location: '/admin/users',
        role: 'student',
        isActive: true,
      );
      expect(studentOnAdmin.location, '/student');

      final lecturerOnAdmin = resolveAuthRedirect(
        hasSession: true,
        location: '/admin/users',
        role: 'lecturer',
        isActive: true,
      );
      expect(lecturerOnAdmin.location, '/lecturer');
    });

    test('resolveAuthRedirect signs out inactive admin', () {
      final inactiveAdmin = resolveAuthRedirect(
        hasSession: true,
        location: '/admin/users',
        role: 'admin',
        isActive: false,
      );
      expect(inactiveAdmin.location, '/login');
      expect(inactiveAdmin.signOut, isTrue);
    });
  });

  group('ManagedUserAccount & LecturerProfile admin helpers', () {
    test('ManagedUserAccount parses student, lecturer, and admin rows', () {
      final student = ManagedUserAccount.fromMap({
        'id': 'u-1',
        'name': 'Rendy Aditya',
        'email': 'rendy@unesa.ac.id',
        'identity_number': '23050974001',
        'program': 'Pendidikan TI',
        'role': 'student',
        'is_active': true,
      });
      expect(student.isStudent, isTrue);
      expect(student.isLecturer, isFalse);
      expect(student.isAdmin, isFalse);
      expect(student.isActive, isTrue);

      final lecturer = ManagedUserAccount.fromMap({
        'id': 'u-2',
        'name': 'Dr. Budi',
        'email': 'budi@unesa.ac.id',
        'identity_number': '19880101',
        'role': 'lecturer',
        'is_active': false,
      });
      expect(lecturer.isLecturer, isTrue);
      expect(lecturer.isActive, isFalse);

      final admin = ManagedUserAccount.fromMap({
        'id': 'u-3',
        'name': 'Admin Kampus',
        'email': 'admin@unesa.ac.id',
        'role': 'admin',
        'is_active': true,
      });
      expect(admin.isAdmin, isTrue);
      expect(admin.name, 'Admin Kampus');
    });

    test('LecturerProfile exposes isAdmin flag accurately', () {
      final adminProfile = LecturerProfile.fromMap({
        'id': 'a-1',
        'name': 'Super Admin',
        'identity_number': 'ADM01',
        'email': 'admin@unesa.ac.id',
        'is_active': true,
        'role': 'admin',
      });
      expect(adminProfile.isAdmin, isTrue);

      final lecturerProfile = LecturerProfile.fromMap({
        'id': 'l-1',
        'name': 'Dosen Pengampu',
        'identity_number': '12345',
        'email': 'dosen@unesa.ac.id',
        'is_active': true,
        'role': 'lecturer',
      });
      expect(lecturerProfile.isAdmin, isFalse);
    });
  });
}

