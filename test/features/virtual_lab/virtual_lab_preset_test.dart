import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_controller.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_model.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_network.dart';

void main() {
  group('Virtual Lab Presets and Templates Tests', () {
    test('presetStar initializes 1 switch and 3 PCs with successful ping', () {
      final session = VirtualLabController.presetStar();

      expect(session.devices.length, equals(4));
      expect(session.cables.length, equals(3));

      final pcs = session.devices
          .where((d) => d.kind == VirtualLabDeviceKind.pc)
          .toList();
      final switches = session.devices
          .where((d) => d.kind == VirtualLabDeviceKind.switch_)
          .toList();

      expect(pcs.length, equals(3));
      expect(switches.length, equals(1));

      // Test connectivity PC1 -> PC2
      final pingResult = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: pcs[0].id,
        targetId: pcs[1].id,
      );
      expect(pingResult.success, isTrue);
      expect(pingResult.reason, equals('connected'));
      expect(pingResult.details, equals([pcs[0].id, switches[0].id, pcs[1].id]));
    });

    test('presetDualSubnet initializes multi-subnet routing that pings across router', () {
      final session = VirtualLabController.presetDualSubnet();

      expect(session.devices.length, equals(5)); // 1 router, 2 switches, 2 PCs
      expect(session.cables.length, equals(4));

      final router = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.router,
      );
      final pcs = session.devices
          .where((d) => d.kind == VirtualLabDeviceKind.pc)
          .toList();

      expect(router.ipAddress, equals('192.168.1.1'));
      expect(router.ipAddress2, equals('192.168.2.1'));
      expect(pcs.length, equals(2));

      // Test inter-subnet ping from PC1 (192.168.1.10) to PC2 (192.168.2.10)
      final pingResult = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: pcs[0].id,
        targetId: pcs[1].id,
      );
      expect(pingResult.success, isTrue);
      expect(pingResult.reason, equals('routed_success'));
      expect(pingResult.details.contains(router.id), isTrue);
    });

    test('presetPeerToPeer initializes direct connection between 2 PCs', () {
      final session = VirtualLabController.presetPeerToPeer();

      expect(session.devices.length, equals(2));
      expect(session.cables.length, equals(1));

      final pcs = session.devices
          .where((d) => d.kind == VirtualLabDeviceKind.pc)
          .toList();

      final pingResult = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: pcs[0].id,
        targetId: pcs[1].id,
      );
      expect(pingResult.success, isTrue);
      expect(pingResult.reason, equals('connected'));
      expect(pingResult.details, equals([pcs[0].id, pcs[1].id]));
    });

    test('presetBlank creates empty session', () {
      final session = VirtualLabController.presetBlank();

      expect(session.devices.isEmpty, isTrue);
      expect(session.cables.isEmpty, isTrue);
    });

    test('loadPreset updates controller session properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(virtualLabControllerProvider).devices.isNotEmpty,
        isTrue,
      );

      container
          .read(virtualLabControllerProvider.notifier)
          .loadPreset(VirtualLabController.presetBlank());
      expect(
        container.read(virtualLabControllerProvider).devices.isEmpty,
        isTrue,
      );
      expect(
        container.read(virtualLabControllerProvider).cables.isEmpty,
        isTrue,
      );

      container
          .read(virtualLabControllerProvider.notifier)
          .loadPreset(VirtualLabController.presetStar());
      expect(
        container.read(virtualLabControllerProvider).devices.length,
        equals(4),
      );
      expect(
        container.read(virtualLabControllerProvider).cables.length,
        equals(3),
      );
    });
  });
}
