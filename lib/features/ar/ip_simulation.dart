// Pure IPv4 / subnet simulation engine for Modul 4 (AR marker 6).
//
// This file deliberately has no Flutter, AR or Supabase imports: the NetLearn
// PRD requires the network simulation engine to be testable *without* a camera
// ("Mesin simulasi jaringan Modul 4 harus terpisah dari renderer AR agar
// validasi jaringan tetap bisa diuji tanpa kamera"). Everything here is a plain
// function over `String`/`int`, so the whole rule set is unit tested offline.
//
// The rules implement AR_PRD §6.4B and NETLEARN_PRD §9.6:
//   1. IPv4 format must be valid.
//   2. Subnet mask must be a valid, contiguous IPv4 mask with a usable host
//      range for this two-computer simulation.
//   3. Each address must be usable as a host address (not the network address,
//      the broadcast address, or a reserved/special range).
//   4. The two computers must not share an address.
//   5. Both must compute the same network address with the same mask; a switch
//      alone does not route between subnets.
//
// The simulation never touches the device's real network (AR_PRD §6.4D).

/// Why a configuration failed the simulation (never returned on success).
enum IpSimulationFailure {
  invalidIpA,
  invalidMaskA,
  unusableHostA,
  invalidIpB,
  invalidMaskB,
  unusableHostB,
  duplicateAddress,
  differentSubnet,
}

/// Outcome of [evaluateConnection].
///
/// On success [failure] is `null`; on failure [failure] explains the first rule
/// that failed and the UI maps it to a localized message.
class IpConnectionResult {
  const IpConnectionResult._({
    required this.failure,
    this.ipA,
    this.ipB,
    this.networkA,
    this.networkB,
  });

  const IpConnectionResult.success({
    required int network,
    int? ipA,
    int? ipB,
  }) : this._(
          failure: null,
          ipA: ipA,
          ipB: ipB,
          networkA: network,
          networkB: network,
        );

  const IpConnectionResult.failed(
    IpSimulationFailure failure, {
    int? ipA,
    int? ipB,
    int? networkA,
    int? networkB,
  }) : this._(
          failure: failure,
          ipA: ipA,
          ipB: ipB,
          networkA: networkA,
          networkB: networkB,
        );

  final IpSimulationFailure? failure;

  /// Parsed 32-bit addresses, when parsing got that far.
  final int? ipA;
  final int? ipB;

  /// Computed network addresses, when both mask and IP parsed.
  final int? networkA;
  final int? networkB;

  bool get success => failure == null;

  /// Dotted-quad network address label, or `null` if it could not be computed.
  String? get networkAddressLabel =>
      networkA == null ? null : intToIpv4(networkA!);
}

/// Evaluates the fixed two-computer-one-switch simulation.
///
/// Checks run in a fixed order (A's fields, then B's, then cross-computer
/// rules) so the reported reason is deterministic and specific rather than a
/// generic "invalid".
IpConnectionResult evaluateConnection({
  required String ipA,
  required String maskA,
  required String ipB,
  required String maskB,
}) {
  final int? parsedIpA = ipv4ToInt(ipA);
  if (parsedIpA == null) {
    return const IpConnectionResult.failed(IpSimulationFailure.invalidIpA);
  }
  final int? parsedMaskA = subnetMaskToInt(maskA);
  if (parsedMaskA == null) {
    return IpConnectionResult.failed(
      IpSimulationFailure.invalidMaskA,
      ipA: parsedIpA,
    );
  }

  final int? parsedIpB = ipv4ToInt(ipB);
  if (parsedIpB == null) {
    return IpConnectionResult.failed(
      IpSimulationFailure.invalidIpB,
      ipA: parsedIpA,
      networkA: parsedIpA & parsedMaskA,
    );
  }
  final int? parsedMaskB = subnetMaskToInt(maskB);
  if (parsedMaskB == null) {
    return IpConnectionResult.failed(
      IpSimulationFailure.invalidMaskB,
      ipA: parsedIpA,
      ipB: parsedIpB,
      networkA: parsedIpA & parsedMaskA,
    );
  }

  final int networkA = parsedIpA & parsedMaskA;
  final int networkB = parsedIpB & parsedMaskB;

  if (!isUsableHost(parsedIpA, parsedMaskA)) {
    return IpConnectionResult.failed(
      IpSimulationFailure.unusableHostA,
      ipA: parsedIpA,
      ipB: parsedIpB,
      networkA: networkA,
      networkB: networkB,
    );
  }
  if (!isUsableHost(parsedIpB, parsedMaskB)) {
    return IpConnectionResult.failed(
      IpSimulationFailure.unusableHostB,
      ipA: parsedIpA,
      ipB: parsedIpB,
      networkA: networkA,
      networkB: networkB,
    );
  }
  if (parsedIpA == parsedIpB) {
    return IpConnectionResult.failed(
      IpSimulationFailure.duplicateAddress,
      ipA: parsedIpA,
      ipB: parsedIpB,
      networkA: networkA,
      networkB: networkB,
    );
  }
  // Same subnet requires both the same network address *and* the same mask;
  // matching text alone is not enough (AR_PRD §6.4B).
  if (networkA != networkB || parsedMaskA != parsedMaskB) {
    return IpConnectionResult.failed(
      IpSimulationFailure.differentSubnet,
      ipA: parsedIpA,
      ipB: parsedIpB,
      networkA: networkA,
      networkB: networkB,
    );
  }

  return IpConnectionResult.success(
    network: networkA,
    ipA: parsedIpA,
    ipB: parsedIpB,
  );
}

/// Parses a dotted-quad IPv4 string to a 32-bit `int`, or `null` when invalid.
///
/// Requires exactly four numeric octets in `0..255`. Surrounding whitespace on
/// each octet is tolerated (mobile keyboards add it); anything else is invalid.
int? ipv4ToInt(String input) {
  final List<String> parts = input.trim().split('.');
  if (parts.length != 4) return null;

  int value = 0;
  for (final String rawPart in parts) {
    final String part = rawPart.trim();
    if (part.isEmpty || part.length > 3) return null;
    for (final int code in part.codeUnits) {
      if (code < 0x30 || code > 0x39) return null; // non-digit
    }
    final int octet = int.parse(part);
    if (octet > 255) return null;
    value = (value << 8) | octet;
  }
  return value & 0xFFFFFFFF;
}

/// Formats a 32-bit value as a dotted-quad IPv4 string.
String intToIpv4(int value) {
  return '${(value >> 24) & 0xFF}.${(value >> 16) & 0xFF}'
      '.${(value >> 8) & 0xFF}.${value & 0xFF}';
}

/// Parses a subnet mask, or `null` when it is not a usable IPv4 mask.
///
/// A valid mask is contiguous from the most significant bit (all 1s then all
/// 0s). Masks that leave fewer than two host bits — `/31` and `/32`, and the
/// all-zero mask — are rejected: this simulation needs a network address, a
/// broadcast address and at least two host addresses.
int? subnetMaskToInt(String input) {
  final int? value = ipv4ToInt(input);
  if (value == null || value == 0) return null;

  // The host bits are the trailing zeros of the mask, i.e. the ones of ~mask.
  final int hostBits = (~value) & 0xFFFFFFFF;
  if (hostBits < 3) return null; // /31, /32: no usable host range.
  if ((hostBits & (hostBits + 1)) != 0) return null; // not contiguous.
  return value;
}

/// Whether [ip] can be used as a host address under [mask].
///
/// Rejects the network address, the directed broadcast address, and the
/// special-purpose ranges a basic simulation should not accept: `0.0.0.0`,
/// `255.255.255.255`, loopback `127.0.0.0/8`, link-local `169.254.0.0/16`, and
/// everything from `224.0.0.0` up (multicast + reserved).
bool isUsableHost(int ip, int mask) {
  if (ip == 0) return false; // 0.0.0.0 — unspecified.
  if (ip == 0xFFFFFFFF) return false; // limited broadcast.

  final int firstOctet = (ip >> 24) & 0xFF;
  final int secondOctet = (ip >> 16) & 0xFF;
  if (firstOctet == 127) return false; // loopback.
  if (firstOctet == 169 && secondOctet == 254) return false; // link-local.
  if (firstOctet >= 224) return false; // multicast + reserved.

  final int hostBits = (~mask) & 0xFFFFFFFF;
  final int network = ip & mask;
  if (ip == network) return false; // network address.
  if (ip == (network | hostBits)) return false; // broadcast address.

  return true;
}
