import 'dart:core';

import 'virtual_lab_model.dart';

class VirtualLabIpv4 {
  const VirtualLabIpv4(this.octets);
  final List<int> octets;

  static VirtualLabIpv4? parse(String raw) {
    final parts = raw.trim().split('.');
    if (parts.length != 4) return null;
    final out = <int>[];
    for (final p in parts) {
      if (p.isEmpty || RegExp(r'[^0-9]').hasMatch(p)) return null;
      if (p.length > 1 && p.startsWith('0')) return null;
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return null;
      out.add(n);
    }
    return VirtualLabIpv4(out);
  }

  bool get isValid => octets.length == 4 && octets.every((n) => n >= 0 && n <= 255);

  int get asNum => (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];

  @override
  String toString() => octets.join('.');
}

class VirtualLabSubnetMask {
  const VirtualLabSubnetMask(this.octets);
  final List<int> octets;

  static VirtualLabSubnetMask? parse(String raw) {
    final ip = VirtualLabIpv4.parse(raw);
    if (ip == null) return null;
    final n = ip.asNum;
    bool seenZero = false;
    for (int i = 31; i >= 0; i--) {
      final bit = (n >> i) & 1;
      if (bit == 0) seenZero = true;
      if (seenZero && bit == 1) return null;
    }
    return VirtualLabSubnetMask(ip.octets);
  }

  int get prefixLength {
    int p = 0;
    for (final n in octets) {
      if (n == 255) {
        p += 8;
      } else if (n == 0) {
        break;
      } else {
        final bits = n.toRadixString(2).padLeft(8, '0');
        for (final c in bits.split('')) {
          if (c == '1') {
            p++;
          } else {
            break;
          }
        }
        break;
      }
    }
    return p;
  }

  int get toMaskNum {
    final p = prefixLength;
    if (p == 0) return 0;
    return (-1 << (32 - p)) & 0xFFFFFFFF;
  }

  VirtualLabIpv4 toNetwork(VirtualLabIpv4 ip) {
    final network = ip.asNum & toMaskNum;
    return VirtualLabIpv4([
      (network >> 24) & 0xFF,
      (network >> 16) & 0xFF,
      (network >> 8) & 0xFF,
      network & 0xFF,
    ]);
  }
}

class VirtualLabEngine {
  static bool sameSubnet(String ipA, String maskA, String ipB, String maskB) {
    final a = VirtualLabIpv4.parse(ipA);
    final b = VirtualLabIpv4.parse(ipB);
    final ma = VirtualLabSubnetMask.parse(maskA);
    final mb = VirtualLabSubnetMask.parse(maskB);
    if (a == null || b == null || ma == null || mb == null) return false;
    return ma.toNetwork(a).asNum == mb.toNetwork(b).asNum;
  }

  static bool isHostAddress(String ip, String mask) {
    final a = VirtualLabIpv4.parse(ip);
    final m = VirtualLabSubnetMask.parse(mask);
    if (a == null || m == null) return false;
    final prefix = m.prefixLength;
    if (prefix >= 31) return true;
    final network = m.toNetwork(a).asNum;
    final broadcast = network | (~m.toMaskNum & 0xFFFFFFFF);
    final aNum = a.asNum;
    if (aNum == network) return false;
    if (aNum == broadcast) return false;
    return true;
  }
}

class VirtualLabConnectivityResult {
  const VirtualLabConnectivityResult({
    required this.success,
    required this.reason,
    this.details = const [],
  });

  final bool success;
  final String reason;
  final List<String> details;
}

/// Status ringkas satu perangkat untuk dot di kanvas — mengikuti legenda
/// desain: Connected (hijau), Needs config (oranye), Not cabled (abu).
enum VirtualLabDeviceStatus { connected, needsConfig, notCabled }

class VirtualLabConnectivityEngine {
  static VirtualLabDeviceStatus deviceStatus(
    VirtualLabSession session,
    VirtualLabDevice device,
  ) {
    final cabled = session.cables.any((c) => c.involves(device.id));
    if (device.kind == VirtualLabDeviceKind.switch_) {
      // Switch tidak butuh IP: cukup tersambung atau belum.
      return cabled
          ? VirtualLabDeviceStatus.connected
          : VirtualLabDeviceStatus.notCabled;
    }
    if (!cabled) return VirtualLabDeviceStatus.notCabled;
    final ip = VirtualLabIpv4.parse(device.ipAddress ?? '');
    final mask = VirtualLabSubnetMask.parse(device.subnetMask ?? '');
    if (ip == null ||
        mask == null ||
        !VirtualLabEngine.isHostAddress(device.ipAddress!, device.subnetMask!)) {
      return VirtualLabDeviceStatus.needsConfig;
    }
    return VirtualLabDeviceStatus.connected;
  }

  /// Ping berarah source → target untuk tab "Ping Test": memakai jalur kabel
  /// aktual (boleh melewati switch) dan mengembalikan jalur perangkat pada
  /// `details` ketika berhasil — dipakai animasi paket agar mengikuti jalur
  /// yang benar, bukan seluruh kabel di kanvas.
  static VirtualLabConnectivityResult ping(
    VirtualLabSession session, {
    required VirtualLabDeviceId sourceId,
    required VirtualLabDeviceId targetId,
  }) {
    final source = session.deviceById(sourceId);
    final target = session.deviceById(targetId);
    if (source == null || target == null) {
      return const VirtualLabConnectivityResult(
          success: false, reason: 'missing_device');
    }
    if (sourceId == targetId) {
      return const VirtualLabConnectivityResult(
          success: false, reason: 'same_device');
    }
    for (final device in [source, target]) {
      if ((device.ipAddress ?? '').trim().isEmpty ||
          (device.subnetMask ?? '').trim().isEmpty) {
        return VirtualLabConnectivityResult(
            success: false, reason: 'not_configured', details: [device.id]);
      }
      final ip = VirtualLabIpv4.parse(device.ipAddress!);
      final mask = VirtualLabSubnetMask.parse(device.subnetMask!);
      if (ip == null) {
        return VirtualLabConnectivityResult(
            success: false, reason: 'invalid_ip', details: [device.id]);
      }
      if (mask == null) {
        return VirtualLabConnectivityResult(
            success: false, reason: 'invalid_mask', details: [device.id]);
      }
      if (!VirtualLabEngine.isHostAddress(device.ipAddress!, device.subnetMask!)) {
        return VirtualLabConnectivityResult(
            success: false, reason: 'host_address', details: [device.id]);
      }
    }
    if (source.ipAddress!.trim() == target.ipAddress!.trim()) {
      return VirtualLabConnectivityResult(success: false, reason: 'duplicate', details: [
        source.ipAddress!.trim(),
      ]);
    }
    final path = _shortestPath(session, sourceId, targetId);
    if (path == null) {
      return VirtualLabConnectivityResult(
          success: false, reason: 'no_path', details: [sourceId, targetId]);
    }
    if (!VirtualLabEngine.sameSubnet(source.ipAddress!, source.subnetMask!,
        target.ipAddress!, target.subnetMask!)) {
      return VirtualLabConnectivityResult(
          success: false,
          reason: 'different_subnet',
          details: [sourceId, targetId]);
    }
    return VirtualLabConnectivityResult(
        success: true, reason: 'connected', details: path);
  }

  /// BFS sederhana pada graf kabel (switch ikut sebagai simpul) untuk
  /// mendapatkan jalur terpendek antar dua perangkat.
  static List<String>? _shortestPath(
    VirtualLabSession session,
    String from,
    String to,
  ) {
    final adjacency = <String, List<String>>{};
    for (final device in session.devices) {
      adjacency.putIfAbsent(device.id, () => <String>[]);
    }
    for (final cable in session.cables) {
      if (session.deviceById(cable.from) == null ||
          session.deviceById(cable.to) == null) {
        continue;
      }
      adjacency[cable.from]!.add(cable.to);
      adjacency[cable.to]!.add(cable.from);
    }
    final previous = <String, String?>{from: null};
    final queue = <String>[from];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == to) {
        final path = <String>[];
        String? step = to;
        while (step != null) {
          path.insert(0, step);
          step = previous[step];
        }
        return path;
      }
      for (final neighbor in adjacency[current] ?? const <String>[]) {
        if (!previous.containsKey(neighbor)) {
          previous[neighbor] = current;
          queue.add(neighbor);
        }
      }
    }
    return null;
  }

  static VirtualLabConnectivityResult evaluate(VirtualLabSession session) {
    final devicesWithIp = session.devices.where((d) => (d.ipAddress ?? '').trim().isNotEmpty).toList();
    if (devicesWithIp.length < 2) {
      return const VirtualLabConnectivityResult(success: false, reason: 'need_two_ip_devices');
    }
    for (final d in devicesWithIp) {
      final ip = VirtualLabIpv4.parse(d.ipAddress!);
      final mask = VirtualLabSubnetMask.parse(d.subnetMask ?? '');
      if (ip == null) return VirtualLabConnectivityResult(success: false, reason: 'invalid_ip', details: [d.id]);
      if (mask == null) return VirtualLabConnectivityResult(success: false, reason: 'invalid_mask', details: [d.id]);
      if (!VirtualLabEngine.isHostAddress(d.ipAddress!, d.subnetMask!)) {
        return VirtualLabConnectivityResult(success: false, reason: 'host_address', details: [d.id]);
      }
    }
    // duplicate
    final seen = <String>{};
    for (final d in devicesWithIp) {
      final ip = d.ipAddress!.trim();
      if (seen.contains(ip)) return VirtualLabConnectivityResult(success: false, reason: 'duplicate', details: [ip]);
      seen.add(ip);
    }
    // adjacency via cables with switch bridging
    final ids = devicesWithIp.map((d) => d.id).toSet();
    final adj = <String, Set<String>>{};
    for (final id in ids) { adj[id] = <String>{}; }
    for (final c in session.cables) {
      if (ids.contains(c.from) && ids.contains(c.to)) {
        adj[c.from]!.add(c.to);
        adj[c.to]!.add(c.from);
      }
    }
    final switchIds = session.devices.where((d) => d.kind == VirtualLabDeviceKind.switch_).map((d) => d.id).toSet();
    for (final sw in switchIds) {
      final neighbors = <String>{};
      for (final c in session.cables) {
        if (c.from == sw && ids.contains(c.to)) { neighbors.add(c.to); }
        if (c.to == sw && ids.contains(c.from)) { neighbors.add(c.from); }
      }
      if (neighbors.length >= 2) {
        for (final a in neighbors) {
          for (final b in neighbors) {
            adj[a]!.add(b);
            adj[b]!.add(a);
          }
        }
      }
    }
    final first = devicesWithIp.first;
    for (final d in devicesWithIp.skip(1)) {
      if (!VirtualLabConnectivityEngine._reachable(adj, first.id, d.id)) {
        return VirtualLabConnectivityResult(success: false, reason: 'no_path', details: [first.id, d.id]);
      }
    }
    for (final d in devicesWithIp.skip(1)) {
      if (!VirtualLabEngine.sameSubnet(first.ipAddress!, first.subnetMask!, d.ipAddress!, d.subnetMask!)) {
        return VirtualLabConnectivityResult(success: false, reason: 'different_subnet', details: [first.id, d.id]);
      }
    }
    return const VirtualLabConnectivityResult(success: true, reason: 'connected');
  }

  static bool _reachable(Map<String, Set<String>> adj, String start, String target) {
    final seen = <String>{};
    final queue = <String>[start];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (cur == target) return true;
      if (!seen.add(cur)) continue;
      for (final n in adj[cur] ?? <String>{}) { queue.add(n); }
    }
    return false;
  }
}
