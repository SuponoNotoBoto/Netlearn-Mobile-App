import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netlearn/features/notifications/cheer_notification_service.dart';

void main() {
  group('Cheer Notification & Class Scoping', () {
    test('CheerNotificationItem serialization works properly', () {
      final now = DateTime(2026, 11, 13, 9, 30);
      final item = CheerNotificationItem(
        id: 'cheer_123',
        senderId: 'user-001',
        senderName: 'Budi Santoso',
        classId: 'class-abc',
        className: 'PTI 2025 A',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['id'], 'cheer_123');
      expect(map['sender_id'], 'user-001');
      expect(map['sender_name'], 'Budi Santoso');
      expect(map['class_id'], 'class-abc');
      expect(map['class_name'], 'PTI 2025 A');

      final reconstructed = CheerNotificationItem.fromMap(map);
      expect(reconstructed.id, item.id);
      expect(reconstructed.senderName, 'Budi Santoso');
      expect(reconstructed.className, 'PTI 2025 A');
      expect(reconstructed.classId, 'class-abc');
    });

    test('StudentClassCheersState holds class-scoped count and history', () {
      final item = CheerNotificationItem(
        id: 'cheer_1',
        senderId: 'user-002',
        senderName: 'Siti Aminah',
        classId: 'class-pti-a',
        className: 'PTI 2025 A',
        createdAt: DateTime.now(),
      );

      final stateA = StudentClassCheersState(
        count: 5,
        history: [item],
        classId: 'class-pti-a',
        className: 'PTI 2025 A',
      );

      expect(stateA.count, 5);
      expect(stateA.history.length, 1);
      expect(stateA.className, 'PTI 2025 A');
      expect(stateA.classId, 'class-pti-a');

      // Beda kelas memiliki state berbeda
      const stateB = StudentClassCheersState(
        count: 0,
        history: [],
        classId: 'class-pti-b',
        className: 'PTI 2025 B',
      );

      expect(stateB.count, 0);
      expect(stateB.history, isEmpty);
      expect(stateB.className, 'PTI 2025 B');
    });

    test('studentClassCheersProvider handles empty userId gracefully', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(studentClassCheersProvider('').future);
      expect(state.count, 0);
      expect(state.history, isEmpty);
    });
  });
}

