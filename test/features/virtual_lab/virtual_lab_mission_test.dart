import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/materials/material_lab_binding.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_controller.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_mission.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_mission_service.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_model.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_network.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeMissionLabRepository extends VirtualLabRepository {
  Map<String, dynamic> storedSubmissions = {};

  @override
  String? get currentUserId => 'test_user_mission';

  @override
  Future<Map<String, dynamic>> loadLabSubmissions() async {
    return Map<String, dynamic>.from(storedSubmissions);
  }

  @override
  Future<void> saveLabSubmissions(
    Map<String, dynamic> submissions, {
    required String forUserId,
  }) async {
    storedSubmissions = Map<String, dynamic>.from(submissions);
  }
}

void main() {
  group('Virtual Lab Phase 7: Mission Evaluator & Checker Tests', () {
    test('Modul 1 (P2P): Evaluates blank canvas to 0 tasks completed', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'p2p',
        title: 'Praktikum Jaringan Dasar & Pengkabelan Peer-to-Peer',
      );

      final session = VirtualLabController.presetBlank();
      final report = VirtualLabMissionEvaluator.evaluate(
        session: session,
        binding: binding,
      );

      expect(report.preset, 'p2p');
      expect(report.totalTasks, 4);
      expect(report.completedTasks, 0);
      expect(report.score, 0);
      expect(report.isPassed, false);
      expect(report.tasks[0].isCompleted, false);
      expect(report.tasks[0].failureReason, contains('dibutuhkan minimal 2'));
    });

    test('Modul 1 (P2P): Fully completed when 2 PCs are cabled, configured, and pinged', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'p2p',
        title: 'Praktikum Jaringan Dasar & Pengkabelan Peer-to-Peer',
      );

      // Gunakan preset P2P siap pakai
      final session = VirtualLabController.presetPeerToPeer();
      const testResult = VirtualLabConnectivityResult(
        success: true,
        reason: 'Ping successful',
      );

      final report = VirtualLabMissionEvaluator.evaluate(
        session: session,
        binding: binding,
        lastTest: testResult,
      );

      expect(report.totalTasks, 4);
      expect(report.completedTasks, 4);
      expect(report.score, 100);
      expect(report.isPassed, true);
      expect(report.tasks.every((t) => t.isCompleted), true);
    });

    test('Modul 2 (Star LAN): Evaluates switch, cabling, subnet, and ping', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'star',
        title: 'Praktikum Topologi Jaringan & Switch LAN',
      );

      // Skenario bawaan star: 1 switch + 3 PC terhubung dan 1 subnet
      final session = VirtualLabController.presetStar();
      const testResult = VirtualLabConnectivityResult(
        success: true,
        reason: 'Ping LAN successful',
      );

      final report = VirtualLabMissionEvaluator.evaluate(
        session: session,
        binding: binding,
        lastTest: testResult,
      );

      expect(report.totalTasks, 4);
      expect(report.completedTasks, 4);
      expect(report.score, 100);
      expect(report.isPassed, true);
    });

    test('Modul 3 (Dual Subnet Routing): Evaluates router, multi-subnet, and gateways', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'dual_subnet',
        title: 'Praktikum Routing Statis & Multi-Subnet',
      );

      final session = VirtualLabController.presetDualSubnet();
      const testResult = VirtualLabConnectivityResult(
        success: true,
        reason: 'Cross router ping successful',
      );

      final report = VirtualLabMissionEvaluator.evaluate(
        session: session,
        binding: binding,
        lastTest: testResult,
      );

      expect(report.totalTasks, 4);
      expect(report.completedTasks, 4);
      expect(report.score, 100);
      expect(report.isPassed, true);
    });

    test('Modul 4 (DHCP & Web Server): Evaluates server and client dynamic IP', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'dhcp_server',
        title: 'Praktikum Server Layanan Jaringan (DHCP & HTTP)',
      );

      final server = const VirtualLabDevice(
        id: 'srv_1',
        kind: VirtualLabDeviceKind.server,
        position: Offset(100, 100),
        name: 'Server Kampus',
        ipAddress: '192.168.1.254',
        subnetMask: '255.255.255.0',
        dhcpServerEnabled: true,
        httpServerEnabled: true,
      );
      final pc = const VirtualLabDevice(
        id: 'pc_1',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(200, 100),
        name: 'PC Client',
        ipMode: VirtualLabIpMode.dhcp,
        ipAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.254',
      );
      final cable = const VirtualLabCable(id: 'c1', from: 'srv_1', to: 'pc_1');

      final session = VirtualLabSession(
        devices: [server, pc],
        cables: [cable],
      );

      final report = VirtualLabMissionEvaluator.evaluate(
        session: session,
        binding: binding,
      );

      expect(report.totalTasks, 4);
      expect(report.completedTasks, 4);
      expect(report.score, 100);
      expect(report.isPassed, true);
    });

    test('VirtualLabMissionSubmission: Serializes and deserializes accurately', () {
      final sub = VirtualLabMissionSubmission(
        id: 'sub_123',
        userId: 'user_456',
        materialId: 'core_module_1',
        materialTitle: 'Praktikum P2P',
        preset: 'p2p',
        score: 100,
        isPassed: true,
        submittedAt: DateTime(2026, 11, 8, 17, 30),
        completedTaskIds: const ['t1', 't2', 't3', 't4'],
        totalTasks: 4,
        topologySnapshot: {'device_count': 2},
      );

      final json = sub.toJson();
      final roundtrip = VirtualLabMissionSubmission.fromJson(json);

      expect(roundtrip.id, 'sub_123');
      expect(roundtrip.userId, 'user_456');
      expect(roundtrip.materialId, 'core_module_1');
      expect(roundtrip.score, 100);
      expect(roundtrip.isPassed, true);
      expect(roundtrip.completedTaskIds.length, 4);
      expect(roundtrip.topologySnapshot?['device_count'], 2);
    });

    test('VirtualLabMissionService: Hybrid Cloud & Local Cache saves and restores submissions', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepo = FakeMissionLabRepository();
      final service = VirtualLabMissionService(
        null,
        'test_user_mission',
        fakeRepo,
      );

      final submission = VirtualLabMissionSubmission(
        id: 'sub_m1',
        userId: 'test_user_mission',
        materialId: 'core_module_1',
        materialTitle: 'Praktikum P2P',
        preset: 'p2p',
        score: 100,
        isPassed: true,
        submittedAt: DateTime(2026, 11, 8, 17, 35),
        completedTaskIds: const ['t1', 't2', 't3', 't4'],
        totalTasks: 4,
      );

      // Simpan submission
      await service.saveSubmission(submission);

      // Verifikasi tersimpan di cloud repo
      expect(fakeRepo.storedSubmissions.containsKey('core_module_1'), true);

      // Ambil kembali submission dari service
      final retrieved = await service.getSubmission('core_module_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.score, 100);
      expect(retrieved.isPassed, true);
      expect(retrieved.materialTitle, 'Praktikum P2P');
    });

    test('Bilingual Mission Evaluator: Evaluates in English when languageCode is en', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'p2p',
        title: 'Peer-to-Peer Lab',
      );

      final session = VirtualLabController.presetBlank();
      final reportEn = VirtualLabMissionEvaluator.evaluate(
        session: session,
        binding: binding,
        languageCode: 'en',
      );

      expect(reportEn.languageCode, 'en');
      expect(reportEn.tasks[0].title, contains('Add at Least 2 PCs'));
      expect(reportEn.tasks[0].failureReason, contains('at least 2 required'));
      expect(reportEn.tasks[1].title, contains('Connect Both PCs'));
      expect(reportEn.tasks[2].title, contains('Configure Static IP'));
      expect(reportEn.tasks[3].title, contains('Test Ping Connectivity'));

      final summary = reportEn.summary('en');
      expect(summary, contains('0 of 4 practical objectives completed'));
    });

    test('Submission State Persistence: Preserves completed tasks when canvas is blank', () {
      const binding = MaterialLabBinding(
        preset: 'blank',
        referencePreset: 'star',
        materialId: 'core_module_2',
        title: 'Praktikum Topologi Star',
      );

      final sub = VirtualLabMissionSubmission(
        id: 'sub_saved',
        userId: 'user_1',
        materialId: 'core_module_2',
        materialTitle: 'Praktikum Topologi Star',
        preset: 'star',
        score: 100,
        isPassed: true,
        submittedAt: DateTime(2026, 11, 8, 17, 00),
        completedTaskIds: const ['star_devices', 'star_cables', 'star_ips', 'star_ping'],
        totalTasks: 4,
      );

      // Canvas is now completely blank (student deleted devices or reset canvas)
      final blankSession = VirtualLabController.presetBlank();
      final baseReport = VirtualLabMissionEvaluator.evaluate(
        session: blankSession,
        binding: binding,
      );
      expect(baseReport.completedTasks, 0); // Active canvas is 0

      // When building mission sheet with existing submission, completed state is preserved
      final completedIds = sub.completedTaskIds.toSet();
      final preservedTasks = baseReport.tasks.map((t) {
        final isDone = sub.isPassed || completedIds.contains(t.id);
        return t.copyWith(
          isCompleted: isDone,
          failureReason: isDone ? null : t.failureReason,
        );
      }).toList();

      expect(preservedTasks.every((t) => t.isCompleted), true);
      expect(sub.score, 100);
      expect(sub.isPassed, true);
    });
  });
}
