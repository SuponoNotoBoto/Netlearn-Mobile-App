import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_model.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_network.dart';

void main() {
  group('Virtual Lab Layer 3 Inter-Subnet Routing Test', () {
    test('Ping between two PCs in the same subnet succeeds via Switch', () {
      final pc1 = const VirtualLabDevice(
        id: 'pc_1',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(100, 100),
        name: 'PC1',
        ipAddress: '192.168.1.10',
        subnetMask: '255.255.255.0',
      );
      final pc2 = const VirtualLabDevice(
        id: 'pc_2',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(300, 100),
        name: 'PC2',
        ipAddress: '192.168.1.20',
        subnetMask: '255.255.255.0',
      );
      final sw1 = const VirtualLabDevice(
        id: 'sw_1',
        kind: VirtualLabDeviceKind.switch_,
        position: Offset(200, 100),
        name: 'Switch1',
      );

      final session = VirtualLabSession(
        devices: [pc1, sw1, pc2],
        cables: const [
          VirtualLabCable(id: 'c1', from: 'pc_1', to: 'sw_1'),
          VirtualLabCable(id: 'c2', from: 'sw_1', to: 'pc_2'),
        ],
      );

      final result = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: 'pc_1',
        targetId: 'pc_2',
      );

      expect(result.success, isTrue);
      expect(result.reason, equals('connected'));
      expect(result.details, equals(['pc_1', 'sw_1', 'pc_2']));
    });

    test('Ping between different subnets fails when no router exists', () {
      final pc1 = const VirtualLabDevice(
        id: 'pc_1',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(100, 100),
        name: 'PC1',
        ipAddress: '192.168.1.10',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
      );
      final pc2 = const VirtualLabDevice(
        id: 'pc_2',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(300, 100),
        name: 'PC2',
        ipAddress: '192.168.2.10',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.2.1',
      );
      final sw1 = const VirtualLabDevice(
        id: 'sw_1',
        kind: VirtualLabDeviceKind.switch_,
        position: Offset(200, 100),
        name: 'Switch1',
      );

      final session = VirtualLabSession(
        devices: [pc1, sw1, pc2],
        cables: const [
          VirtualLabCable(id: 'c1', from: 'pc_1', to: 'sw_1'),
          VirtualLabCable(id: 'c2', from: 'sw_1', to: 'pc_2'),
        ],
      );

      final result = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: 'pc_1',
        targetId: 'pc_2',
      );

      expect(result.success, isFalse);
      expect(result.reason, equals('different_subnet_no_router'));
    });

    test('Ping between different subnets succeeds through Router with valid Gateways', () {
      // Subnet A: 192.168.1.0/24
      final pc1 = const VirtualLabDevice(
        id: 'pc_1',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(50, 100),
        name: 'PC1',
        ipAddress: '192.168.1.10',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
      );
      final sw1 = const VirtualLabDevice(
        id: 'sw_1',
        kind: VirtualLabDeviceKind.switch_,
        position: Offset(150, 100),
        name: 'Switch1',
      );

      // Router connecting Subnet A (eth0) & Subnet B (eth1)
      final r1 = const VirtualLabDevice(
        id: 'r_1',
        kind: VirtualLabDeviceKind.router,
        position: Offset(250, 100),
        name: 'Router1',
        ipAddress: '192.168.1.1', // eth0
        subnetMask: '255.255.255.0',
        ipAddress2: '192.168.2.1', // eth1
        subnetMask2: '255.255.255.0',
      );

      // Subnet B: 192.168.2.0/24
      final sw2 = const VirtualLabDevice(
        id: 'sw_2',
        kind: VirtualLabDeviceKind.switch_,
        position: Offset(350, 100),
        name: 'Switch2',
      );
      final pc2 = const VirtualLabDevice(
        id: 'pc_2',
        kind: VirtualLabDeviceKind.pc,
        position: Offset(450, 100),
        name: 'PC2',
        ipAddress: '192.168.2.10',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.2.1',
      );

      final session = VirtualLabSession(
        devices: [pc1, sw1, r1, sw2, pc2],
        cables: const [
          VirtualLabCable(id: 'c1', from: 'pc_1', to: 'sw_1'),
          VirtualLabCable(id: 'c2', from: 'sw_1', to: 'r_1'),
          VirtualLabCable(id: 'c3', from: 'r_1', to: 'sw_2'),
          VirtualLabCable(id: 'c4', from: 'sw_2', to: 'pc_2'),
        ],
      );

      final result = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: 'pc_1',
        targetId: 'pc_2',
      );

      expect(result.success, isTrue);
      expect(result.reason, equals('routed_success'));
      expect(result.details, equals(['pc_1', 'sw_1', 'r_1', 'sw_2', 'pc_2']));
    });
  });
}

