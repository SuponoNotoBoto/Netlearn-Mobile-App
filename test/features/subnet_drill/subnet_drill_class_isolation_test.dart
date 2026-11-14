import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/subnet_drill/subnet_drill_leaderboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubnetDrill Class Isolation Tests', () {
    test('scores are strictly isolated per class', () async {
      // 1. Save score in Class A
      await SubnetDrillLeaderboardService.saveScore(
        classId: 'class-a',
        studentId: 'student-123',
        studentName: 'Budi Santoso',
        score: 85,
        maxStreak: 5,
      );

      // 2. Query scores for Class A
      final scoresClassA = await SubnetDrillLeaderboardService.getTopScores(classId: 'class-a');
      expect(scoresClassA.length, 1);
      expect(scoresClassA.first.score, 85);
      expect(scoresClassA.first.studentId, 'student-123');

      // 3. Query scores for Class B (should be empty / 0 because student has not played in Class B)
      final scoresClassB = await SubnetDrillLeaderboardService.getTopScores(classId: 'class-b');
      expect(scoresClassB.isEmpty, isTrue);

      // 4. Now save score in Class B
      await SubnetDrillLeaderboardService.saveScore(
        classId: 'class-b',
        studentId: 'student-123',
        studentName: 'Budi Santoso',
        score: 40,
        maxStreak: 2,
      );

      // 5. Verify Class B has score 40 and Class A still retains score 85
      final refreshedClassB = await SubnetDrillLeaderboardService.getTopScores(classId: 'class-b');
      expect(refreshedClassB.length, 1);
      expect(refreshedClassB.first.score, 40);

      final refreshedClassA = await SubnetDrillLeaderboardService.getTopScores(classId: 'class-a');
      expect(refreshedClassA.length, 1);
      expect(refreshedClassA.first.score, 85);

      // 6. Save a global score (classId: null) and verify an empty class does NOT inherit it
      await SubnetDrillLeaderboardService.saveScore(
        classId: null,
        studentId: 'student-999',
        studentName: 'Global User',
        score: 120,
        maxStreak: 9,
      );

      final emptyClassC = await SubnetDrillLeaderboardService.getTopScores(classId: 'class-c');
      expect(emptyClassC, isEmpty);
    });
  });
}

