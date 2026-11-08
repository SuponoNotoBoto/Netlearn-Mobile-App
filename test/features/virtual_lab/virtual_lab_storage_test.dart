import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_controller.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_model.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_repository.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_saved_topology.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVirtualLabRepository extends VirtualLabRepository {
  List<Map<String, dynamic>> cloudTopologies = [];

  _FakeVirtualLabRepository([List<Map<String, dynamic>>? initial]) {
    cloudTopologies = initial ?? [];
  }

  @override
  String? get currentUserId => 'user_123';

  @override
  Future<List<Map<String, dynamic>>> loadSavedTopologies() async {
    return cloudTopologies;
  }

  @override
  Future<void> saveSavedTopologies(
    List<Map<String, dynamic>> topologies, {
    required String forUserId,
  }) async {
    cloudTopologies = topologies;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Virtual Lab Phase 5: Custom Topology Storage & JSON Tests', () {
    late VirtualLabSession session;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      session = VirtualLabController.scenarioOne();
    });

    test('VirtualLabSavedTopology serializes and deserializes correctly', () {
      final saved = VirtualLabSavedTopology.fromSession(
        id: 'topo_test_1',
        name: 'Topologi Uji Star LAN',
        description: 'Catatan praktikum subnetting',
        session: session,
      );

      expect(saved.id, equals('topo_test_1'));
      expect(saved.name, equals('Topologi Uji Star LAN'));
      expect(saved.description, equals('Catatan praktikum subnetting'));
      expect(saved.deviceCount, equals(session.devices.length));
      expect(saved.cableCount, equals(session.cables.length));

      final json = saved.toJson();
      final restored = VirtualLabSavedTopology.fromJson(json);

      expect(restored.id, equals(saved.id));
      expect(restored.name, equals(saved.name));
      expect(restored.description, equals(saved.description));
      expect(restored.deviceCount, equals(saved.deviceCount));
      expect(restored.cableCount, equals(saved.cableCount));

      final restoredSession = restored.toSession();
      expect(restoredSession.devices.length, equals(session.devices.length));
      expect(restoredSession.cables.length, equals(session.cables.length));
    });

    test('VirtualLabSavedTopology encodeList and decodeList roundtrip works', () {
      final t1 = VirtualLabSavedTopology.fromSession(
        id: 't1',
        name: 'Topologi 1',
        session: session,
      );
      final t2 = VirtualLabSavedTopology.fromSession(
        id: 't2',
        name: 'Topologi 2',
        session: session,
      );

      final encoded = VirtualLabSavedTopology.encodeList([t1, t2]);
      final decoded = VirtualLabSavedTopology.decodeList(encoded);

      expect(decoded.length, equals(2));
      expect(decoded[0].id, equals('t1'));
      expect(decoded[1].id, equals('t2'));
    });

    test('VirtualLabStorageService saves, lists, updates, and deletes topologies', () async {
      final storage = const VirtualLabStorageService();

      // 1. Initial list is empty
      var list = await storage.getSavedTopologies();
      expect(list.isEmpty, isTrue);

      // 2. Save new topology
      final saved1 = await storage.saveTopology(
        name: 'Jaringan Kantor Lantai 1',
        description: '3 PC dan 1 Switch',
        session: session,
      );
      expect(saved1.name, equals('Jaringan Kantor Lantai 1'));

      list = await storage.getSavedTopologies();
      expect(list.length, equals(1));
      expect(list.first.id, equals(saved1.id));
      expect(list.first.name, equals('Jaringan Kantor Lantai 1'));

      // 3. Update existing topology
      await storage.saveTopology(
        existingId: saved1.id,
        name: 'Jaringan Kantor Lantai 1 (Updated)',
        description: 'Deskripsi diperbarui',
        session: session,
      );

      list = await storage.getSavedTopologies();
      expect(list.length, equals(1));
      expect(list.first.name, equals('Jaringan Kantor Lantai 1 (Updated)'));
      expect(list.first.description, equals('Deskripsi diperbarui'));

      // 4. Save second topology
      final saved2 = await storage.saveTopology(
        name: 'Lab Server DHCP',
        session: session,
      );

      list = await storage.getSavedTopologies();
      expect(list.length, equals(2));
      expect(list.first.id, equals(saved2.id)); // Most recently updated is first

      // 5. Delete first topology
      final deleted = await storage.deleteTopology(saved1.id);
      expect(deleted, isTrue);

      list = await storage.getSavedTopologies();
      expect(list.length, equals(1));
      expect(list.first.id, equals(saved2.id));
    });

    test('VirtualLabStorageService parses valid exported JSON and handles corrupt data', () {
      final storage = const VirtualLabStorageService();

      // 1. Valid export payload structure
      final validPayload = {
        'format': 'NetLearn_VirtualLab',
        'version': 1,
        'name': 'Test Lab Export',
        'exportedAt': DateTime.now().toIso8601String(),
        'session': session.toJson(),
      };
      final jsonString = jsonEncode(validPayload);

      final parsedSession = storage.parseTopologyJson(jsonString);
      expect(parsedSession, isNotNull);
      expect(parsedSession!.devices.length, equals(session.devices.length));
      expect(parsedSession.cables.length, equals(session.cables.length));

      // 2. Direct session structure
      final directSessionString = jsonEncode(session.toJson());
      final directParsed = storage.parseTopologyJson(directSessionString);
      expect(directParsed, isNotNull);
      expect(directParsed!.devices.length, equals(session.devices.length));

      // 3. Corrupt/Invalid JSON
      expect(storage.parseTopologyJson(''), isNull);
      expect(storage.parseTopologyJson('{ invalid json }'), isNull);
      expect(storage.parseTopologyJson('{"some_key": 123}'), isNull);
    });

    test('VirtualLabController loads imported session seamlessly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialSession = container.read(virtualLabControllerProvider);
      expect(initialSession.devices.isNotEmpty, isTrue);

      // Create a custom session with 1 Router and 1 PC
      final customSession = VirtualLabSession(
        devices: const [
          VirtualLabDevice(
            id: 'r_test',
            kind: VirtualLabDeviceKind.router,
            position: Offset(100, 100),
            name: 'Router_Test',
            ipAddress: '192.168.10.1',
          ),
        ],
        cables: const [],
      );

      container
          .read(virtualLabControllerProvider.notifier)
          .loadSession(customSession);

      final updated = container.read(virtualLabControllerProvider);
      expect(updated.devices.length, equals(1));
      expect(updated.devices.first.name, equals('Router_Test'));
      expect(updated.devices.first.kind, equals(VirtualLabDeviceKind.router));
    });

    test(
        'VirtualLabStorageService restores saved topologies from cloud when local storage is empty (Chrome restart)',
        () async {
      final cloudData = [
        VirtualLabSavedTopology.fromSession(
          id: 'cloud_topo_1',
          name: 'Topologi Cloud dari Sesi Sebelumnya',
          session: session,
        ).toJson(),
      ];
      final fakeRepo = _FakeVirtualLabRepository(cloudData);

      // Local storage kosong (mensimulasikan restart Chrome dengan profil sementara baru)
      SharedPreferences.setMockInitialValues({});
      final storage = VirtualLabStorageService(null, 'user_123', fakeRepo);

      final list = await storage.getSavedTopologies();
      expect(list.length, equals(1));
      expect(list.first.id, equals('cloud_topo_1'));
      expect(list.first.name, equals('Topologi Cloud dari Sesi Sebelumnya'));

      // Simpan topologi baru - verifikasi data tersimpan sampai ke cloud repository
      await storage.saveTopology(
        name: 'Topologi Baru di Cloud',
        session: session,
      );
      expect(fakeRepo.cloudTopologies.length, equals(2));
      expect(
        fakeRepo.cloudTopologies.any((t) => t['name'] == 'Topologi Baru di Cloud'),
        isTrue,
      );
    });
  });
}
