import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ip_simulation.dart';

void main() {
  group('ipv4ToInt / intToIpv4', () {
    test('parses a dotted quad to a 32-bit value and back', () {
      expect(ipv4ToInt('192.168.1.10'), 0xC0A8010A);
      expect(intToIpv4(0xC0A8010A), '192.168.1.10');
    });

    test('handles the boundaries 0.0.0.0 and 255.255.255.255', () {
      expect(ipv4ToInt('0.0.0.0'), 0);
      expect(ipv4ToInt('255.255.255.255'), 0xFFFFFFFF);
    });

    test('rejects malformed input', () {
      expect(ipv4ToInt('192.168.1'), isNull);
      expect(ipv4ToInt('192.168.1.1.1'), isNull);
      expect(ipv4ToInt('192.168.1.'), isNull);
      expect(ipv4ToInt('192.168.1.256'), isNull);
      expect(ipv4ToInt('192.168.1.abc'), isNull);
      expect(ipv4ToInt(''), isNull);
      expect(ipv4ToInt('192.168.1.1000'), isNull); // > 3 digits
    });

    test('tolerates surrounding whitespace on each octet', () {
      expect(ipv4ToInt(' 192.168.1.10 '), 0xC0A8010A);
      expect(ipv4ToInt('192 . 168 . 1 . 10'), 0xC0A8010A);
    });
  });

  group('subnetMaskToInt', () {
    test('accepts contiguous masks with a usable host range', () {
      expect(subnetMaskToInt('255.255.255.0'), 0xFFFFFF00); // /24
      expect(subnetMaskToInt('255.255.254.0'), 0xFFFFFE00); // /23
      expect(subnetMaskToInt('255.255.255.252'), 0xFFFFFFFC); // /30
    });

    test('rejects non-contiguous masks', () {
      expect(subnetMaskToInt('255.0.255.0'), isNull);
      expect(subnetMaskToInt('255.255.0.255'), isNull);
      expect(subnetMaskToInt('0.255.255.0'), isNull);
    });

    test('rejects the all-zero mask and masks with no host range', () {
      expect(subnetMaskToInt('0.0.0.0'), isNull);
      expect(subnetMaskToInt('255.255.255.255'), isNull); // /32
      expect(subnetMaskToInt('255.255.255.254'), isNull); // /31
    });
  });

  group('evaluateConnection', () {
    IpConnectionResult run({
      String ipA = '192.168.1.10',
      String maskA = '255.255.255.0',
      String ipB = '192.168.1.20',
      String maskB = '255.255.255.0',
    }) {
      return evaluateConnection(ipA: ipA, maskA: maskA, ipB: ipB, maskB: maskB);
    }

    test('succeeds for two hosts in the same subnet', () {
      final result = run();
      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(result.networkAddressLabel, '192.168.1.0');
    });

    test('fails for two hosts in different subnets', () {
      final result = run(ipB: '10.0.0.20');
      expect(result.failure, IpSimulationFailure.differentSubnet);
    });

    test('fails when the masks differ even with overlapping addresses', () {
      final result = run(maskB: '255.255.0.0');
      expect(result.failure, IpSimulationFailure.differentSubnet);
    });

    test('fails on invalid IPv4 input', () {
      expect(run(ipA: '999.1.1.1').failure,
          IpSimulationFailure.invalidIpA);
      expect(run(ipB: 'nope').failure, IpSimulationFailure.invalidIpB);
    });

    test('fails on invalid subnet masks', () {
      expect(run(maskA: '255.0.255.0').failure,
          IpSimulationFailure.invalidMaskA);
      expect(run(maskB: '255.255.0.255').failure,
          IpSimulationFailure.invalidMaskB);
    });

    test('rejects the network address as a host address', () {
      final result = run(ipA: '192.168.1.0');
      expect(result.failure, IpSimulationFailure.unusableHostA);
    });

    test('rejects the broadcast address as a host address', () {
      final result = run(ipB: '192.168.1.255');
      expect(result.failure, IpSimulationFailure.unusableHostB);
    });

    test('rejects loopback and link-local addresses', () {
      expect(run(ipA: '127.0.0.1').failure,
          IpSimulationFailure.unusableHostA);
      expect(run(ipB: '169.254.1.1').failure,
          IpSimulationFailure.unusableHostB);
    });

    test('rejects multicast/reserved addresses', () {
      expect(run(ipA: '224.0.0.1').failure,
          IpSimulationFailure.unusableHostA);
    });

    test('rejects a duplicate address', () {
      final result = run(ipA: '192.168.1.10', ipB: '192.168.1.10');
      expect(result.failure, IpSimulationFailure.duplicateAddress);
    });

    test('reports the first failing rule deterministically', () {
      // A's mask is checked before B's IP, so an invalid A mask wins.
      final result = run(maskA: '0.0.0.0', ipB: 'not-an-ip');
      expect(result.failure, IpSimulationFailure.invalidMaskA);
    });
  });

  group('isUsableHost', () {
    test('accepts a normal host and rejects the network/broadcast edges', () {
      expect(isUsableHost(ipv4ToInt('192.168.1.10')!, 0xFFFFFF00), isTrue);
      expect(isUsableHost(ipv4ToInt('192.168.1.0')!, 0xFFFFFF00), isFalse);
      expect(isUsableHost(ipv4ToInt('192.168.1.255')!, 0xFFFFFF00), isFalse);
    });
  });
}
