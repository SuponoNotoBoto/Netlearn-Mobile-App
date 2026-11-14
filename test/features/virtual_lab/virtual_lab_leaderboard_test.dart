import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_leaderboard_models.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_leaderboard_service.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_mission.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VirtualLabLeaderboardService.normalizeMissionKey', () {
    test('normalizes mission ids and presets into valid tab keys', () {
      expect(VirtualLabLeaderboardService.normalizeMissionKey(null), 'overall');
      expect(VirtualLabLeaderboardService.normalizeMissionKey('custom'), 'overall');
      expect(VirtualLabLeaderboardService.normalizeMissionKey('module_1_p2p'), 'p2p');
      expect(VirtualLabLeaderboardService.normalizeMissionKey('star'), 'star');
      expect(
        VirtualLabLeaderboardService.normalizeMissionKey('module_3_dual_subnet'),
        'dual_subnet',
      );
      expect(
        VirtualLabLeaderboardService.normalizeMissionKey('dhcp_server'),
        'dhcp_server',
      );
    });
  });

  group('VirtualLabLeaderboardService.mergeScoreLists', () {
    test('merges remote and local scores keeping highest score per student and material', () {
      final t1 = DateTime(2026, 11, 12, 10, 0);
      final t2 = DateTime(2026, 11, 12, 11, 0);

      final remote = [
        VirtualLabScore(
          id: 'r1',
          studentId: 'u1',
          studentName: 'Budi',
          classId: 'c1',
          materialId: 'module_1_p2p',
          materialTitle: 'Modul 1: P2P',
          preset: 'p2p',
          score: 70,
          completedTasks: 2,
          totalTasks: 3,
          isPassed: true,
          date: t1,
        ),
        VirtualLabScore(
          id: 'r2',
          studentId: 'u2',
          studentName: 'Siti',
          classId: 'c1',
          materialId: 'module_1_p2p',
          materialTitle: 'Modul 1: P2P',
          preset: 'p2p',
          score: 90,
          completedTasks: 3,
          totalTasks: 3,
          isPassed: true,
          date: t1,
        ),
      ];

      final local = [
        VirtualLabScore(
          id: 'l1',
          studentId: 'u1',
          studentName: 'Budi',
          classId: 'c1',
          materialId: 'module_1_p2p',
          materialTitle: 'Modul 1: P2P',
          preset: 'p2p',
          score: 100,
          completedTasks: 3,
          totalTasks: 3,
          isPassed: true,
          date: t2,
        ),
      ];

      final merged = VirtualLabLeaderboardService.mergeScoreLists(remote, local);

      expect(merged.length, 2);
      expect(merged.first.studentId, 'u1');
      expect(merged.first.score, 100);
      expect(merged.last.studentId, 'u2');
      expect(merged.last.score, 90);
    });
  });

  group('VirtualLabLeaderboardService syncSubmissions & ranking', () {
    test('syncs submitted missions into overall and mission leaderboards sorted highest first', () async {
      await VirtualLabLeaderboardService.saveScore(
        classId: 'class-1',
        studentId: 'u2',
        studentName: 'Siti',
        materialId: 'module_1_p2p',
        materialTitle: 'Modul 1: P2P',
        preset: 'p2p',
        score: 85,
        completedTasks: 3,
        totalTasks: 3,
        isPassed: true,
      );

      await VirtualLabLeaderboardService.syncSubmissions(
        classId: 'class-1',
        studentName: 'Andi',
        submissions: {
          'module_1_p2p': VirtualLabMissionSubmission(
            id: 'sub-1',
            userId: 'u1',
            materialId: 'module_1_p2p',
            materialTitle: 'Modul 1: P2P',
            preset: 'p2p',
            score: 100,
            isPassed: true,
            submittedAt: DateTime(2026, 11, 12, 12, 0),
            completedTaskIds: const ['t1', 't2', 't3'],
            totalTasks: 3,
          ),
        },
      );

      final overall =
          await VirtualLabLeaderboardService.getOverallScores(classId: 'class-1');
      expect(overall.length, 2);
      expect(overall.first.studentName, 'Andi');
      expect(overall.first.totalScore, 100);

      final p2p = await VirtualLabLeaderboardService.getScoresByMission(
        missionKey: 'p2p',
        classId: 'class-1',
      );
      expect(p2p.length, 2);
      expect(p2p.first.studentName, 'Andi');
      expect(p2p.first.score, 100);

      // Empty preset in another mission should not leak into star mission
      await VirtualLabLeaderboardService.saveScore(
        classId: 'class-1',
        studentId: 'u3',
        studentName: 'Rina',
        materialId: 'custom_id',
        materialTitle: 'Custom Lab',
        preset: '',
        score: 95,
        completedTasks: 2,
        totalTasks: 2,
        isPassed: true,
      );
      final star = await VirtualLabLeaderboardService.getScoresByMission(
        missionKey: 'star',
        classId: 'class-1',
      );
      expect(star, isEmpty);
    });

    test('strictly isolates Virtual Lab scores per class', () async {
      await VirtualLabLeaderboardService.saveScore(
        classId: 'class-a',
        studentId: 'u1',
        studentName: 'Budi',
        materialId: 'module_1_p2p',
        materialTitle: 'Modul 1: P2P',
        preset: 'p2p',
        score: 95,
        completedTasks: 3,
        totalTasks: 3,
        isPassed: true,
      );

      // Tidak boleh bocor ke kelas B atau bucket global
      final classAScores = await VirtualLabLeaderboardService.getAllScores(
        classId: 'class-a',
      );
      final classBScores = await VirtualLabLeaderboardService.getAllScores(
        classId: 'class-b',
      );
      final globalScores = await VirtualLabLeaderboardService.getAllScores(
        classId: null,
      );

      expect(classAScores.length, 1);
      expect(classBScores, isEmpty);
      expect(globalScores, isEmpty);

      // syncSubmissions ke class-b harus melewati submission milik class-a
      await VirtualLabLeaderboardService.syncSubmissions(
        classId: 'class-b',
        studentName: 'Budi',
        submissions: {
          'module_1_p2p': VirtualLabMissionSubmission(
            id: 'sub-a',
            userId: 'u1',
            classId: 'class-a',
            materialId: 'module_1_p2p',
            materialTitle: 'Modul 1: P2P',
            preset: 'p2p',
            score: 95,
            isPassed: true,
            submittedAt: DateTime(2026, 11, 14, 9, 0),
            completedTaskIds: const ['t1', 't2', 't3'],
            totalTasks: 3,
          ),
        },
      );

      final refreshedClassB = await VirtualLabLeaderboardService.getAllScores(
        classId: 'class-b',
      );
      expect(refreshedClassB, isEmpty);

      // Submission membawa classId lewat toJson/fromJson
      final roundtrip = VirtualLabMissionSubmission.fromJson(
        VirtualLabMissionSubmission(
          id: 'sub-rt',
          userId: 'u2',
          classId: 'class-b',
          materialId: 'star',
          materialTitle: 'Topologi Star',
          preset: 'star',
          score: 88,
          isPassed: true,
          submittedAt: DateTime(2026, 11, 14, 9, 5),
          completedTaskIds: const ['t1', 't2'],
          totalTasks: 2,
        ).toJson(),
      );
      expect(roundtrip.classId, 'class-b');
    });
  });
}

