import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_model.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_terminal.dart';

void main() {
  group('Virtual Lab Terminal Engine Tests', () {
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
      ipAddress: '192.168.1.20',
      subnetMask: '255.255.255.0',
      defaultGateway: '192.168.1.1',
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

    test('help command returns guidance list', () {
      final lines = VirtualLabTerminalEngine.execute(
        command: 'help',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
      );

      expect(lines.isNotEmpty, isTrue);
      expect(lines.any((l) => l.contains('ipconfig')), isTrue);
      expect(lines.any((l) => l.contains('ping')), isTrue);
      expect(lines.any((l) => l.contains('tracert')), isTrue);
    });

    test('ipconfig command displays accurate adapter info', () {
      final lines = VirtualLabTerminalEngine.execute(
        command: 'ipconfig',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
      );

      expect(lines.any((l) => l.contains('192.168.1.10')), isTrue);
      expect(lines.any((l) => l.contains('255.255.255.0')), isTrue);
      expect(lines.any((l) => l.contains('192.168.1.1')), isTrue);
      expect(lines.any((l) => l.contains('Connected')), isTrue);
    });

    test('ping command to reachable target returns 4 replies', () {
      bool pingReported = false;
      final lines = VirtualLabTerminalEngine.execute(
        command: 'ping 192.168.1.20',
        session: session,
        currentDevice: pc1,
        onPingResult: (result) {
          pingReported = true;
          expect(result.success, isTrue);
        },
      );

      expect(pingReported, isTrue);
      expect(lines.any((l) => l.contains('Reply from 192.168.1.20')), isTrue);
      expect(lines.any((l) => l.contains('Lost = 0 (0% loss)')), isTrue);
    });

    test('ping command to non-existent target returns request timed out', () {
      final lines = VirtualLabTerminalEngine.execute(
        command: 'ping 192.168.1.99',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
      );

      expect(lines.any((l) => l.contains('Request timed out')), isTrue);
      expect(lines.any((l) => l.contains('Lost = 4 (100% loss)')), isTrue);
    });

    test('tracert command traces hops to target host', () {
      final lines = VirtualLabTerminalEngine.execute(
        command: 'tracert 192.168.1.20',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
      );

      expect(lines.any((l) => l.contains('Tracing route to 192.168.1.20')), isTrue);
      expect(lines.any((l) => l.contains('Trace complete')), isTrue);
    });
  });
}

