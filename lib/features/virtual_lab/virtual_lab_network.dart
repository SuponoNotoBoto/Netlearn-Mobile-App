// ============================================================================
// MODULE: Virtual Lab Network Simulation Engine (Layer 2, Layer 3 & Services)
// DESCRIPTION: Mesin simulasi logika jaringan komputer murni yang menangani
//              kalkulasi IPv4, Subnetting CIDR, Switching Layer 2 (BFS Graph),
//              Routing Antar-Subnet Layer 3, alokasi DHCP DORA, dan HTTP Server.
// ============================================================================

import 'dart:core';
import 'package:flutter/material.dart' show Offset;

import 'virtual_lab_model.dart';

// ---------------------------------------------------------------------------
// SECTION: IPv4 & Subnet Mask Mathematical Primitives
// ---------------------------------------------------------------------------

/// [VirtualLabIpv4]
///
/// Representasi terstruktur alamat IPv4 32-bit (4 oktet) yang menyediakan
/// validasi format ketat dan konversi ke bilangan bulat (integer 32-bit)
/// untuk operasi bitwise jaringan.
class VirtualLabIpv4 {
  const VirtualLabIpv4(this.octets);
  final List<int> octets;

  /// Mem-parsing string alamat IPv4 (contoh: `192.168.1.10`).
  /// Mengembalikan `null` jika jumlah oktet bukan 4, terdapat karakter non-angka,
  /// leading zero tidak valid, atau nilai oktet di luar rentang 0..255.
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

  /// Memastikan ke-4 oktet berada dalam rentang nilai byte yang sah (0..255).
  bool get isValid => octets.length == 4 && octets.every((n) => n >= 0 && n <= 255);

  /// Mengonversi 4 oktet menjadi satu nilai integer 32-bit unsigned untuk
  /// memudahkan perhitungan Network ID dan Broadcast Address secara bitwise.
  int get asNum => (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];

  @override
  String toString() => octets.join('.');
}

/// [VirtualLabSubnetMask]
///
/// Representasi Subnet Mask IPv4 yang memvalidasi kontiguitas bit `1` diikuti bit `0`
/// (mencegah mask tidak valid seperti `255.0.255.0`), serta menghitung panjang
/// prefix CIDR (misal `/24`) dan alamat Network ID.
class VirtualLabSubnetMask {
  const VirtualLabSubnetMask(this.octets);
  final List<int> octets;

  /// Memvalidasi apakah string masukan merupakan subnet mask yang sah (bit 1 berurutan
  /// dari MSB ke LSB tanpa selang-seling bit 0).
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

  /// Menghitung panjang prefix CIDR (`/0` hingga `/32`) dari jumlah bit `1`.
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

  /// Mengembalikan nilai bitmask 32-bit untuk operasi bitwise AND.
  int get toMaskNum {
    final p = prefixLength;
    if (p == 0) return 0;
    return (-1 << (32 - p)) & 0xFFFFFFFF;
  }

  /// Menghitung Network Address hasil operasi bitwise AND antara [ip] dan subnet mask.
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

/// [VirtualLabEngine]
///
/// Kumpulan fungsi bantu untuk memverifikasi kesamaan subnet dan kelayakan
/// alamat IP sebagai Host Address yang dapat digunakan perangkat.
class VirtualLabEngine {
  /// Memeriksa apakah dua pasang alamat IP dan Subnet Mask berada pada Network ID yang sama.
  static bool sameSubnet(String ipA, String maskA, String ipB, String maskB) {
    final a = VirtualLabIpv4.parse(ipA);
    final b = VirtualLabIpv4.parse(ipB);
    final ma = VirtualLabSubnetMask.parse(maskA);
    final mb = VirtualLabSubnetMask.parse(maskB);
    if (a == null || b == null || ma == null || mb == null) return false;
    return ma.toNetwork(a).asNum == mb.toNetwork(b).asNum;
  }

  /// Memvalidasi bahwa alamat IP bukan merupakan Network Address maupun
  /// Broadcast Address pada subnet yang bersangkutan (kecuali prefix `/31` atau `/32`).
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

// ---------------------------------------------------------------------------
// SECTION: Layer 2 & Layer 3 Connectivity Simulation Engine
// ---------------------------------------------------------------------------

/// [VirtualLabConnectivityResult]
///
/// Menyimpan status keberhasilan simulasi konektivitas (Ping / Evaluasi Topologi),
/// kode alasan kegagalan/keberhasilan ([reason]), dan daftar ID node yang dilalui ([details]).
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

/// Indikator status visual untuk badge titik (dot) pada setiap perangkat di kanvas:
/// - [connected] (Hijau): Tersambung kabel dan konfigurasi IP valid.
/// - [needsConfig] (Oranye): Tersambung kabel tetapi IP/Subnet belum diatur atau salah.
/// - [notCabled] (Abu-abu): Belum ada kabel yang terpasang ke perangkat.
enum VirtualLabDeviceStatus { connected, needsConfig, notCabled }

/// [VirtualLabConnectivityEngine]
///
/// Mesin inti evaluasi topologi yang menyimulasikan pergerakan paket data pada:
/// - **Layer 2 (Data Link)**: Komunikasi langsung dalam satu subnet melewati Switch
///   menggunakan algoritma pencarian jalur terpendek Breadth-First Search (BFS).
/// - **Layer 3 (Network)**: Komunikasi lintas subnet yang memvalidasi Default Gateway
///   pada host pengirim/penerima serta tabel interface (`eth0`/`eth1`) pada Router.
class VirtualLabConnectivityEngine {
  /// Mengevaluasi status kesiapan satu perangkat di kanvas secara real-time.
  static VirtualLabDeviceStatus deviceStatus(
    VirtualLabSession session,
    VirtualLabDevice device,
  ) {
    final cabled = session.cables.any((c) => c.involves(device.id));
    if (device.kind == VirtualLabDeviceKind.switch_) {
      // Switch bekerja di Layer 2 (Unmanged Switch) dan tidak membutuhkan alamat IP.
      return cabled
          ? VirtualLabDeviceStatus.connected
          : VirtualLabDeviceStatus.notCabled;
    }
    if (device.kind == VirtualLabDeviceKind.router) {
      if (!cabled) return VirtualLabDeviceStatus.notCabled;
      // Router membutuhkan minimal interface pertama (eth0) terkonfigurasi dengan benar.
      final ip1 = VirtualLabIpv4.parse(device.ipAddress ?? '');
      final mask1 = VirtualLabSubnetMask.parse(device.subnetMask ?? '');
      if (ip1 == null ||
          mask1 == null ||
          !VirtualLabEngine.isHostAddress(
              device.ipAddress!, device.subnetMask!)) {
        return VirtualLabDeviceStatus.needsConfig;
      }
      // Apabila Router menghubungkan 2 segmen kabel atau lebih, interface kedua (eth1) wajib valid.
      final count = VirtualLabSession.cableCount(session, device.id);
      if (count >= 2) {
        final ip2 = VirtualLabIpv4.parse(device.ipAddress2 ?? '');
        final mask2 = VirtualLabSubnetMask.parse(device.subnetMask2 ?? '');
        if (ip2 == null ||
            mask2 == null ||
            !VirtualLabEngine.isHostAddress(
                device.ipAddress2!, device.subnetMask2!)) {
          return VirtualLabDeviceStatus.needsConfig;
        }
      }
      return VirtualLabDeviceStatus.connected;
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

  /// Menyimulasikan pengiriman paket ICMP Echo Request (Ping) berarah dari
  /// [sourceId] menuju [targetId] dan mengembalikan urutan hop perangkat pada `details`
  /// untuk dianimasikan di atas kanvas.
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

    // Validasi kelengkapan dan keabsahan IP/Subnet pada perangkat pengirim dan tujuan.
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

    // Deteksi konflik alamat IP (IP Address Conflict).
    if (source.ipAddress!.trim() == target.ipAddress!.trim()) {
      return VirtualLabConnectivityResult(success: false, reason: 'duplicate', details: [
        source.ipAddress!.trim(),
      ]);
    }

    final isSameSubnet = VirtualLabEngine.sameSubnet(
      source.ipAddress!,
      source.subnetMask!,
      target.ipAddress!,
      target.subnetMask!,
    );

    // KASUS A — Komunikasi Layer 2 (Satu Subnet / Local Broadcast Domain):
    // Paket diteruskan langsung atau melalui Switch tanpa melibatkan Router.
    if (isSameSubnet) {
      final switches = session.devices
          .where((d) => d.kind == VirtualLabDeviceKind.switch_)
          .map((d) => d.id);
      final allowedNodes = {sourceId, targetId, ...switches};
      final path = _shortestPath(session, sourceId, targetId, allowDevices: allowedNodes);
      if (path == null) {
        return VirtualLabConnectivityResult(
            success: false, reason: 'no_path', details: [sourceId, targetId]);
      }
      return VirtualLabConnectivityResult(
          success: true, reason: 'connected', details: path);
    }

    // KASUS B — Komunikasi Layer 3 (Lintas Subnet Berbeda):
    // Wajib melewati Default Gateway dan Router yang menghubungkan kedua network.
    final srcGw = (source.defaultGateway ?? '').trim();
    if (srcGw.isEmpty) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'source_missing_gateway',
        details: [source.id],
      );
    }
    final srcGwIp = VirtualLabIpv4.parse(srcGw);
    if (srcGwIp == null) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'source_invalid_gateway',
        details: [source.id],
      );
    }
    if (!VirtualLabEngine.sameSubnet(
      source.ipAddress!,
      source.subnetMask!,
      srcGw,
      source.subnetMask!,
    )) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'gateway_subnet_mismatch',
        details: [source.id],
      );
    }

    final tgtGw = (target.defaultGateway ?? '').trim();
    if (tgtGw.isEmpty) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'target_missing_gateway',
        details: [target.id],
      );
    }
    final tgtGwIp = VirtualLabIpv4.parse(tgtGw);
    if (tgtGwIp == null) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'target_invalid_gateway',
        details: [target.id],
      );
    }
    if (!VirtualLabEngine.sameSubnet(
      target.ipAddress!,
      target.subnetMask!,
      tgtGw,
      target.subnetMask!,
    )) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'target_gateway_subnet_mismatch',
        details: [target.id],
      );
    }

    // Cari perangkat Router yang memiliki sepasang interface sesuai dengan
    // Default Gateway pengirim (srcGw) dan Default Gateway tujuan (tgtGw).
    final routers = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.router)
        .toList();
    if (routers.isEmpty) {
      return VirtualLabConnectivityResult(
        success: false,
        reason: 'different_subnet_no_router',
        details: [sourceId, targetId],
      );
    }

    final switches = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.switch_)
        .map((d) => d.id)
        .toSet();

    for (final router in routers) {
      final matchesSrcEth0 = router.ipAddress?.trim() == srcGw;
      final matchesSrcEth1 = router.ipAddress2?.trim() == srcGw;
      if (!matchesSrcEth0 && !matchesSrcEth1) continue;

      final matchesTgtEth0 = router.ipAddress?.trim() == tgtGw;
      final matchesTgtEth1 = router.ipAddress2?.trim() == tgtGw;
      if (!matchesTgtEth0 && !matchesTgtEth1) continue;

      // Pastikan kedua subnet terhubung pada dua interface Router yang berbeda (eth0 vs eth1).
      if ((matchesSrcEth0 && matchesTgtEth0) || (matchesSrcEth1 && matchesTgtEth1)) {
        continue;
      }

      // Verifikasi jalur fisik Layer 2 dari Pengirim menuju Router Gateway.
      final pathToRouter = _shortestPath(
        session,
        sourceId,
        router.id,
        allowDevices: {sourceId, router.id, ...switches},
      );
      if (pathToRouter == null) continue;

      // Verifikasi jalur fisik Layer 2 dari Router Gateway menuju Penerima.
      final pathFromRouter = _shortestPath(
        session,
        router.id,
        targetId,
        allowDevices: {router.id, targetId, ...switches},
      );
      if (pathFromRouter == null) continue;

      final fullPath = [
        ...pathToRouter,
        ...pathFromRouter.skip(1),
      ];

      return VirtualLabConnectivityResult(
        success: true,
        reason: 'routed_success',
        details: fullPath,
      );
    }

    return VirtualLabConnectivityResult(
      success: false,
      reason: 'gateway_unreachable',
      details: [sourceId, targetId],
    );
  }

  /// Algoritma Breadth-First Search (BFS) pada graf kabel fisik untuk mencari
  /// rute hop terpendek antara perangkat [from] dan [to].
  static List<String>? _shortestPath(
    VirtualLabSession session,
    String from,
    String to, {
    Iterable<String>? allowDevices,
  }) {
    final allowed = allowDevices?.toSet();
    final adjacency = <String, List<String>>{};
    for (final device in session.devices) {
      if (allowed != null && !allowed.contains(device.id)) continue;
      adjacency.putIfAbsent(device.id, () => <String>[]);
    }
    for (final cable in session.cables) {
      if (session.deviceById(cable.from) == null ||
          session.deviceById(cable.to) == null) {
        continue;
      }
      if (allowed != null &&
          (!allowed.contains(cable.from) || !allowed.contains(cable.to))) {
        continue;
      }
      adjacency[cable.from]?.add(cable.to);
      adjacency[cable.to]?.add(cable.from);
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

  /// Mengevaluasi kesehatan konfigurasi topologi kanvas secara menyeluruh.
  static VirtualLabConnectivityResult evaluate(VirtualLabSession session) {
    final devicesWithIp = session.devices
        .where((d) =>
            d.kind == VirtualLabDeviceKind.pc &&
            (d.ipAddress ?? '').trim().isNotEmpty)
        .toList();
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
    // Pemeriksaan duplikasi alamat IP antar PC
    final seen = <String>{};
    for (final d in devicesWithIp) {
      final ip = d.ipAddress!.trim();
      if (seen.contains(ip)) return VirtualLabConnectivityResult(success: false, reason: 'duplicate', details: [ip]);
      seen.add(ip);
    }
    // Pembentukan graf keterhubungan kabel dengan jembatan Switch Layer 2
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

// ---------------------------------------------------------------------------
// SECTION: DHCP Server & DORA Lease Allocation Engine
// ---------------------------------------------------------------------------

/// [VirtualLabDhcpResult]
///
/// Menyimpan hasil negosiasi peminjaman IP (DHCP Lease) antara PC Client dan Server.
class VirtualLabDhcpResult {
  const VirtualLabDhcpResult({
    required this.success,
    required this.reason,
    this.ipAddress,
    this.subnetMask,
    this.defaultGateway,
    this.dnsServer,
    this.serverName,
  });

  final bool success;
  final String reason;
  final String? ipAddress;
  final String? subnetMask;
  final String? defaultGateway;
  final String? dnsServer;
  final String? serverName;
}

/// [VirtualLabDhcpEngine]
///
/// Menyimulasikan siklus protokol DHCP (Discover, Offer, Request, Acknowledge):
/// mencari DHCP Server aktif dalam domain broadcast Layer 2 yang sama dan
/// mengalokasikan alamat IPv4 bebas pertama dari DHCP Pool.
class VirtualLabDhcpEngine {
  /// Memproses permintaan lease IP baru dari perangkat [clientId].
  static VirtualLabDhcpResult requestLease(
    VirtualLabSession session,
    String clientId,
  ) {
    final client = session.deviceById(clientId);
    if (client == null) {
      return const VirtualLabDhcpResult(
        success: false,
        reason: 'client_not_found',
      );
    }

    // 1. Broadcast DHCP Discover pada domain Layer 2 (melewati Switch, tidak menembus Router).
    final switches = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.switch_)
        .map((d) => d.id);
    final allowedL2Nodes = {client.id, ...switches};
    final servers = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.server)
        .toList();

    VirtualLabDevice? dhcpServer;
    for (final server in servers) {
      if (!server.dhcpServerEnabled) continue;
      final path = VirtualLabConnectivityEngine._shortestPath(
        session,
        client.id,
        server.id,
        allowDevices: {...allowedL2Nodes, server.id},
      );
      if (path != null) {
        dhcpServer = server;
        break;
      }
    }

    if (dhcpServer == null) {
      return const VirtualLabDhcpResult(
        success: false,
        reason: 'no_dhcp_server',
      );
    }

    // 2. Hitung dan alokasikan alamat IP yang tersedia dari DHCP Pool Server.
    final serverIpStr = (dhcpServer.ipAddress ?? '').trim();
    final maskStr = (dhcpServer.dhcpSubnetMask ?? '').trim().isNotEmpty
        ? dhcpServer.dhcpSubnetMask!.trim()
        : (dhcpServer.subnetMask ?? '255.255.255.0');
    final subnetMask = VirtualLabSubnetMask.parse(maskStr);
    if (subnetMask == null) {
      return const VirtualLabDhcpResult(
        success: false,
        reason: 'invalid_pool_mask',
      );
    }

    String poolStartStr = (dhcpServer.dhcpStartIp ?? '').trim().isNotEmpty
        ? dhcpServer.dhcpStartIp!.trim()
        : '192.168.1.100';

    // Penyesuaian otomatis subnet pool jika IP statis Server diubah oleh pengguna.
    if (serverIpStr.isNotEmpty) {
      if (!VirtualLabEngine.sameSubnet(serverIpStr, maskStr, poolStartStr, maskStr)) {
        final srvIpv4 = VirtualLabIpv4.parse(serverIpStr);
        final oldStartIpv4 = VirtualLabIpv4.parse(poolStartStr);
        if (srvIpv4 != null) {
          final lastOctet = oldStartIpv4 != null &&
                  oldStartIpv4.octets[3] > 0 &&
                  oldStartIpv4.octets[3] < 254
              ? oldStartIpv4.octets[3]
              : 100;
          poolStartStr =
              '${srvIpv4.octets[0]}.${srvIpv4.octets[1]}.${srvIpv4.octets[2]}.$lastOctet';
        }
      }
    }

    final startIpv4 = VirtualLabIpv4.parse(poolStartStr);
    if (startIpv4 == null) {
      return const VirtualLabDhcpResult(
        success: false,
        reason: 'invalid_pool_start',
      );
    }

    // Daftarkan seluruh IP yang sedang aktif digunakan di kanvas agar tidak terjadi tabrakan IP.
    final usedIps = <String>{};
    for (final d in session.devices) {
      if (d.id == clientId) continue;
      if ((d.ipAddress ?? '').trim().isNotEmpty) {
        usedIps.add(d.ipAddress!.trim());
      }
      if ((d.ipAddress2 ?? '').trim().isNotEmpty) {
        usedIps.add(d.ipAddress2!.trim());
      }
    }

    // Iterasi hingga 100 kandidat host di dalam pool untuk menemukan IP bebas pertama.
    String? allocatedIp;
    final baseNum = startIpv4.asNum;
    for (int offset = 0; offset < 100; offset++) {
      final candidateNum = baseNum + offset;
      final candIp = VirtualLabIpv4([
        (candidateNum >> 24) & 0xFF,
        (candidateNum >> 16) & 0xFF,
        (candidateNum >> 8) & 0xFF,
        candidateNum & 0xFF,
      ]);
      final candStr = candIp.toString();
      if (!VirtualLabEngine.isHostAddress(candStr, maskStr)) continue;
      if (!VirtualLabEngine.sameSubnet(candStr, maskStr, poolStartStr, maskStr)) {
        break;
      }
      if (!usedIps.contains(candStr)) {
        allocatedIp = candStr;
        break;
      }
    }

    if (allocatedIp == null) {
      return const VirtualLabDhcpResult(
        success: false,
        reason: 'pool_exhausted',
      );
    }

    // Resolusi Default Gateway yang akan didistribusikan kepada DHCP Client.
    final serverGw = (dhcpServer.defaultGateway ?? '').trim();
    final customDhcpGw = (dhcpServer.dhcpGateway ?? '').trim();

    String? distributedGateway;
    final isCustomGwInSubnet = customDhcpGw.isNotEmpty &&
        (serverIpStr.isEmpty ||
            VirtualLabEngine.sameSubnet(
                serverIpStr, maskStr, customDhcpGw, maskStr));

    if (serverGw.isNotEmpty) {
      if (!isCustomGwInSubnet ||
          (customDhcpGw == '192.168.1.1' && serverGw != '192.168.1.1')) {
        distributedGateway = serverGw;
      } else {
        distributedGateway = customDhcpGw;
      }
    } else if (isCustomGwInSubnet) {
      distributedGateway = customDhcpGw;
    } else {
      distributedGateway = dhcpServer.ipAddress;
    }

    return VirtualLabDhcpResult(
      success: true,
      reason: 'success',
      ipAddress: allocatedIp,
      subnetMask: maskStr,
      defaultGateway: distributedGateway,
      dnsServer: dhcpServer.dhcpDns ?? '8.8.8.8',
      serverName: dhcpServer.displayName,
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION: Application Layer HTTP Server Simulation Engine
// ---------------------------------------------------------------------------

/// [VirtualLabHttpResult]
///
/// Merepresentasikan respons HTTP dari simulasi Web Server pada Virtual Lab.
class VirtualLabHttpResult {
  const VirtualLabHttpResult({
    required this.success,
    required this.statusCode,
    required this.reason,
    this.title,
    this.body,
  });

  final bool success;
  final int statusCode;
  final String reason;
  final String? title;
  final String? body;
}

/// [VirtualLabHttpEngine]
///
/// Menyimulasikan komunikasi protokol HTTP GET pada Layer 7 (Application Layer)
/// yang terlebih dahulu memverifikasi konektivitas transport/network melalui
/// [VirtualLabConnectivityEngine.ping].
class VirtualLabHttpEngine {
  /// Mengirimkan request HTTP GET dari [sourceId] ke alamat IP [targetIp].
  static VirtualLabHttpResult get(
    VirtualLabSession session, {
    required String sourceId,
    required String targetIp,
  }) {
    final targetDevice = session.devices.firstWhere(
      (d) =>
          d.ipAddress?.trim() == targetIp.trim() ||
          d.ipAddress2?.trim() == targetIp.trim(),
      orElse: () => const VirtualLabDevice(
        id: '',
        kind: VirtualLabDeviceKind.pc,
        position: Offset.zero,
      ),
    );

    if (targetDevice.id.isEmpty) {
      return const VirtualLabHttpResult(
        success: false,
        statusCode: 404,
        reason: 'Host tidak ditemukan atau belum memiliki alamat IP.',
      );
    }

    // Pastikan terdapat rute jaringan (Layer 2 atau Layer 3) yang valid menuju server.
    final pingResult = VirtualLabConnectivityEngine.ping(
      session,
      sourceId: sourceId,
      targetId: targetDevice.id,
    );

    if (!pingResult.success) {
      return VirtualLabHttpResult(
        success: false,
        statusCode: 504,
        reason: 'Connection timed out: ${pingResult.reason}',
      );
    }

    if (targetDevice.kind != VirtualLabDeviceKind.server) {
      return const VirtualLabHttpResult(
        success: false,
        statusCode: 400,
        reason: 'Target bukan merupakan perangkat Server.',
      );
    }

    if (!targetDevice.httpServerEnabled) {
      return const VirtualLabHttpResult(
        success: false,
        statusCode: 503,
        reason:
            'Service Unavailable: Layanan HTTP Web Server pada server ini sedang nonaktif.',
      );
    }

    return VirtualLabHttpResult(
      success: true,
      statusCode: 200,
      reason: 'OK',
      title: targetDevice.httpWebTitle ?? 'NetLearn Server Portal',
      body: targetDevice.httpWebContent ??
          'Selamat datang di Web Server NetLearn! Layanan HTTP aktif.',
    );
  }
}
