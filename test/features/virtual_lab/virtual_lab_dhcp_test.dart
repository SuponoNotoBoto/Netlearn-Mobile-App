import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_controller.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_model.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_network.dart';
import 'package:netlearn/features/virtual_lab/virtual_lab_terminal.dart';

void main() {
  group('Virtual Lab Phase 4: Server, DHCP & HTTP Tests', () {
    late VirtualLabSession session;

    setUp(() {
      session = VirtualLabController.presetDhcpServer();
    });

    test('presetDhcpServer initializes 1 Server, 1 Switch, and 2 PCs with valid connectivity', () {
      expect(session.devices.length, equals(4));
      expect(session.cables.length, equals(3));

      final server = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.server,
      );
      final pcs = session.devices
          .where((d) => d.kind == VirtualLabDeviceKind.pc)
          .toList();

      expect(server.ipAddress, equals('192.168.1.254'));
      expect(server.dhcpServerEnabled, isTrue);
      expect(server.httpServerEnabled, isTrue);
      expect(pcs.length, equals(2));

      // PC1 can ping Server
      final pingServer = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: pcs[0].id,
        targetId: server.id,
      );
      expect(pingServer.success, isTrue);
      expect(pingServer.reason, equals('connected'));

      // PC1 can ping PC2
      final pingPc = VirtualLabConnectivityEngine.ping(
        session,
        sourceId: pcs[0].id,
        targetId: pcs[1].id,
      );
      expect(pingPc.success, isTrue);
      expect(pingPc.reason, equals('connected'));
    });

    test('DHCP Engine allocates dynamic IP sequentially to client PCs', () {
      // Create empty PC without IP
      final newPc = const VirtualLabDevice(
        id: 'pc_new',
        kind: VirtualLabDeviceKind.pc,
        position: Offset.zero,
        name: 'PC_New',
      );
      final sw = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.switch_,
      );

      final updatedSession = session.copyWith(
        devices: [...session.devices, newPc],
        cables: [
          ...session.cables,
          VirtualLabCable(id: 'c_new', from: newPc.id, to: sw.id),
        ],
      );

      final lease = VirtualLabDhcpEngine.requestLease(
        updatedSession,
        newPc.id,
      );

      expect(lease.success, isTrue);
      // Since 192.168.1.100 and 192.168.1.101 are used by PC1 and PC2, next is .102
      expect(lease.ipAddress, equals('192.168.1.102'));
      expect(lease.subnetMask, equals('255.255.255.0'));
      expect(lease.defaultGateway, equals('192.168.1.1'));
      expect(lease.dnsServer, equals('8.8.8.8'));
    });

    test('DHCP Engine distributes updated server default gateway (e.g. 192.168.2.1)', () {
      final serverIdx = session.devices.indexWhere(
        (d) => d.kind == VirtualLabDeviceKind.server,
      );
      final updatedDevices = [...session.devices];
      // Server gateway updated to 192.168.2.1 while dhcpGateway was 192.168.1.1
      updatedDevices[serverIdx] = updatedDevices[serverIdx].copyWith(
        ipAddress: '192.168.2.254',
        defaultGateway: '192.168.2.1',
      );

      final newPc = const VirtualLabDevice(
        id: 'pc_dhcp_gw_test',
        kind: VirtualLabDeviceKind.pc,
        position: Offset.zero,
        name: 'PC_Gateway_Test',
      );
      final sw = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.switch_,
      );

      final updatedSession = session.copyWith(
        devices: [...updatedDevices, newPc],
        cables: [
          ...session.cables,
          VirtualLabCable(id: 'c_gw_test', from: newPc.id, to: sw.id),
        ],
      );

      final lease = VirtualLabDhcpEngine.requestLease(
        updatedSession,
        newPc.id,
      );

      expect(lease.success, isTrue);
      expect(lease.defaultGateway, equals('192.168.2.1'));
      expect(lease.ipAddress, startsWith('192.168.2.'));
    });

    test('DHCP Engine returns no_dhcp_server when server is disabled or not reachable', () {
      final serverIdx = session.devices.indexWhere(
        (d) => d.kind == VirtualLabDeviceKind.server,
      );
      final updatedDevices = [...session.devices];
      updatedDevices[serverIdx] =
          updatedDevices[serverIdx].copyWith(dhcpServerEnabled: false);

      final sessionNoDhcp = session.copyWith(devices: updatedDevices);

      final pc1 = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.pc,
      );

      final lease = VirtualLabDhcpEngine.requestLease(
        sessionNoDhcp,
        pc1.id,
      );

      expect(lease.success, isFalse);
      expect(lease.reason, equals('no_dhcp_server'));
    });

    test('HTTP Web Engine serves web portal content to reachable PCs', () {
      final pc1 = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.pc,
      );
      final server = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.server,
      );

      final httpRes = VirtualLabHttpEngine.get(
        session,
        sourceId: pc1.id,
        targetIp: server.ipAddress!,
      );

      expect(httpRes.success, isTrue);
      expect(httpRes.statusCode, equals(200));
      expect(httpRes.title, contains('NetLearn'));
      expect(httpRes.body, isNotNull);
    });

    test('Terminal CLI executes ipconfig /renew, /release, and curl commands', () {
      final pc1 = session.devices.firstWhere(
        (d) => d.kind == VirtualLabDeviceKind.pc,
      );

      // 1. ipconfig
      final ipconfigOut = VirtualLabTerminalEngine.execute(
        command: 'ipconfig',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
      );
      expect(
        ipconfigOut.any((line) => line.contains('IPv4 Address')),
        isTrue,
      );

      // 2. ipconfig /renew
      VirtualLabDhcpResult? renewedLease;
      final renewOut = VirtualLabTerminalEngine.execute(
        command: 'ipconfig /renew',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
        onDhcpLease: (lease) => renewedLease = lease,
      );
      expect(renewedLease, isNotNull);
      expect(renewedLease!.success, isTrue);
      expect(renewOut.any((line) => line.contains('DHCP Acknowledged')), isTrue);

      // 3. ipconfig /release
      bool releaseCalled = false;
      final releaseOut = VirtualLabTerminalEngine.execute(
        command: 'ipconfig /release',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
        onDhcpRelease: () => releaseCalled = true,
      );
      expect(releaseCalled, isTrue);
      expect(releaseOut.any((line) => line.contains('0.0.0.0')), isTrue);

      // 4. curl server
      final curlOut = VirtualLabTerminalEngine.execute(
        command: 'curl 192.168.1.254',
        session: session,
        currentDevice: pc1,
        onPingResult: null,
      );
      expect(curlOut.any((line) => line.contains('HTTP/1.1 200 OK')), isTrue);
      expect(curlOut.any((line) => line.contains('NetLearn')), isTrue);
    });
  });
}

