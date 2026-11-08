import 'dart:async';

import 'package:flutter/material.dart' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'virtual_lab_model.dart';
import 'virtual_lab_network.dart';
import 'virtual_lab_repository.dart';

class VirtualLabController extends Notifier<VirtualLabSession> {
  Timer? _saveTimer;

  /// Whether [restore] already ran for this provider instance.
  bool _restored = false;

  /// Set by the first mutation. A change made while the stored canvas is still
  /// loading wins over it, because it is newer.
  bool _mutated = false;

  @override
  VirtualLabSession build() {
    // Riverpod 3 memakai ulang instance Notifier ini saat `ref.invalidate`
    // (elemen provider hanya di-rebuild, notifier-nya di-cache). Flag di bawah
    // karena itu harus direset di sini: tanpa ini akun kedua yang login tidak
    // pernah memuat canvas-nya sendiri, karena `restore()` langsung berhenti di
    // `_restored` dan `_mutated` sisa akun sebelumnya membuatnya batal.
    _saveTimer?.cancel();
    _saveTimer = null;
    _restored = false;
    _mutated = false;
    ref.onDispose(() => _saveTimer?.cancel());

    return VirtualLabController.scenarioOne();
  }

  /// Kondisi awal Skenario 1 — selaras dengan kartu skenario di halaman
  /// ("Connect PC2 to Switch1, give it an IP in 192.168.1.0/24, then ping from
  /// PC1 to PC2"): PC1 sudah tersambung ke Switch1 dan ber-IP, PC2 sudah ada
  /// di kanvas tetapi belum dikabeli dan belum memiliki IP.
  ///
  /// Kanvas tidak dimulai kosong karena kartu skenario selalu tampil — kalau
  /// kanvas kosong, mahasiswa tidak punya titik awal untuk mengerjakan
  /// instruksi skenario.
  static VirtualLabSession scenarioOne() {
    final pc1 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(64, 62),
      name: 'PC1',
      ipAddress: '192.168.1.10',
      subnetMask: '255.255.255.0',
    );
    final sw = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.switch_),
      kind: VirtualLabDeviceKind.switch_,
      position: const Offset(164, 48),
      name: 'Switch1',
    );
    final pc2 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(264, 62),
      name: 'PC2',
    );
    return VirtualLabSession(
      devices: [pc1, sw, pc2],
      cables: [
        VirtualLabCable(
          id: VirtualLabSession.nextCableId(),
          from: pc1.id,
          to: sw.id,
        ),
      ],
      selectedDeviceId: pc2.id,
    );
  }

  /// Template 1: Topologi Star (1 Switch + 3 PC satu subnet)
  static VirtualLabSession presetStar() {
    final sw = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.switch_),
      kind: VirtualLabDeviceKind.switch_,
      position: const Offset(160, 110),
      name: 'Switch1',
    );
    final pc1 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(60, 45),
      name: 'PC1',
      ipAddress: '192.168.1.10',
      subnetMask: '255.255.255.0',
    );
    final pc2 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(260, 45),
      name: 'PC2',
      ipAddress: '192.168.1.20',
      subnetMask: '255.255.255.0',
    );
    final pc3 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(160, 185),
      name: 'PC3',
      ipAddress: '192.168.1.30',
      subnetMask: '255.255.255.0',
    );
    return VirtualLabSession(
      devices: [sw, pc1, pc2, pc3],
      cables: [
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: pc1.id, to: sw.id),
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: pc2.id, to: sw.id),
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: pc3.id, to: sw.id),
      ],
      selectedDeviceId: pc1.id,
    );
  }

  /// Template 2: Inter-Network Dual Subnet (Router + 2 Switch + 2 PC)
  static VirtualLabSession presetDualSubnet() {
    final router = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.router),
      kind: VirtualLabDeviceKind.router,
      position: const Offset(160, 110),
      name: 'Router1',
      ipAddress: '192.168.1.1',
      subnetMask: '255.255.255.0',
      ipAddress2: '192.168.2.1',
      subnetMask2: '255.255.255.0',
    );
    final sw1 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.switch_),
      kind: VirtualLabDeviceKind.switch_,
      position: const Offset(70, 110),
      name: 'Switch1',
    );
    final pc1 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(30, 45),
      name: 'PC1',
      ipAddress: '192.168.1.10',
      subnetMask: '255.255.255.0',
      defaultGateway: '192.168.1.1',
    );
    final sw2 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.switch_),
      kind: VirtualLabDeviceKind.switch_,
      position: const Offset(250, 110),
      name: 'Switch2',
    );
    final pc2 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(290, 45),
      name: 'PC2',
      ipAddress: '192.168.2.10',
      subnetMask: '255.255.255.0',
      defaultGateway: '192.168.2.1',
    );
    return VirtualLabSession(
      devices: [router, sw1, pc1, sw2, pc2],
      cables: [
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: pc1.id, to: sw1.id),
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: sw1.id, to: router.id),
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: router.id, to: sw2.id),
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: sw2.id, to: pc2.id),
      ],
      selectedDeviceId: router.id,
    );
  }

  /// Template 3: Peer-to-Peer (2 PC terhubung langsung)
  static VirtualLabSession presetPeerToPeer() {
    final pc1 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(80, 110),
      name: 'PC1',
      ipAddress: '10.0.0.1',
      subnetMask: '255.255.255.0',
    );
    final pc2 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(240, 110),
      name: 'PC2',
      ipAddress: '10.0.0.2',
      subnetMask: '255.255.255.0',
    );
    return VirtualLabSession(
      devices: [pc1, pc2],
      cables: [
        VirtualLabCable(
            id: VirtualLabSession.nextCableId(), from: pc1.id, to: pc2.id),
      ],
      selectedDeviceId: pc1.id,
    );
  }

  /// Template 4: Kanvas Kosong (Reset Bersih)
  static VirtualLabSession presetBlank() {
    return const VirtualLabSession(devices: [], cables: []);
  }

  /// Template 5: Jaringan Client-Server DHCP & Web (1 Server + 1 Switch + 2 PC)
  static VirtualLabSession presetDhcpServer() {
    final server = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.server),
      kind: VirtualLabDeviceKind.server,
      position: const Offset(160, 45),
      name: 'Server1',
      ipAddress: '192.168.1.254',
      subnetMask: '255.255.255.0',
      defaultGateway: '192.168.1.1',
      dhcpServerEnabled: true,
      dhcpStartIp: '192.168.1.100',
      dhcpSubnetMask: '255.255.255.0',
      dhcpGateway: '192.168.1.1',
      dhcpDns: '8.8.8.8',
      httpServerEnabled: true,
      httpWebTitle: 'NetLearn Server Portal',
      httpWebContent:
          'Selamat datang di Server Kampus NetLearn! Layanan DHCP & HTTP aktif.',
    );
    final sw = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.switch_),
      kind: VirtualLabDeviceKind.switch_,
      position: const Offset(160, 125),
      name: 'Switch1',
    );
    final pc1 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(65, 195),
      name: 'PC1',
      ipMode: VirtualLabIpMode.dhcp,
      ipAddress: '192.168.1.100',
      subnetMask: '255.255.255.0',
      defaultGateway: '192.168.1.1',
      dnsServer: '8.8.8.8',
    );
    final pc2 = VirtualLabDevice(
      id: VirtualLabSession.nextDeviceId(VirtualLabDeviceKind.pc),
      kind: VirtualLabDeviceKind.pc,
      position: const Offset(255, 195),
      name: 'PC2',
      ipMode: VirtualLabIpMode.dhcp,
      ipAddress: '192.168.1.101',
      subnetMask: '255.255.255.0',
      defaultGateway: '192.168.1.1',
      dnsServer: '8.8.8.8',
    );

    return VirtualLabSession(
      devices: [server, sw, pc1, pc2],
      cables: [
        VirtualLabCable(
          id: VirtualLabSession.nextCableId(),
          from: server.id,
          to: sw.id,
        ),
        VirtualLabCable(
          id: VirtualLabSession.nextCableId(),
          from: pc1.id,
          to: sw.id,
        ),
        VirtualLabCable(
          id: VirtualLabSession.nextCableId(),
          from: pc2.id,
          to: sw.id,
        ),
      ],
      selectedDeviceId: server.id,
    );
  }

  /// Loads this account's saved canvas (once per provider lifetime).
  ///
  /// `resetUserSession` invalidates this provider on sign-in and sign-out, so
  /// each instance belongs to exactly one student: without that invalidation
  /// account B kept seeing account A's devices and IP configuration.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;

    final repository = ref.read(virtualLabRepositoryProvider);
    try {
      // Identitas akun diambil sebelum await dan dibaca ulang sesudahnya:
      // kalau keduanya beda, akun berganti selama baris dimuat — menerapkan
      // hasilnya berarti perangkat akun sebelumnya muncul di kanvas akun
      // baru. Pembacaannya di dalam try karena Supabase bisa belum
      // ter-inisialisasi (pump halaman di test offline) — dulu satu-satunya
      // titik sentuh Supabase ada di load() yang sudah tertutup try ini.
      final accountId = repository.currentUserId;
      final json = await repository.load();
      if (repository.currentUserId != accountId) return;
      if (json == null || _mutated) return;
      state = VirtualLabSession.fromJson(json);
    } catch (_) {
      // Offline or the row is unreadable: keep the default scenario instead of
      // blocking the lab behind a network call.
    }
  }

  /// Every canvas change goes through here so it is also persisted.
  void _commit(VirtualLabSession next) {
    _mutated = true;
    state = next;
    _scheduleSave();
  }

  /// Debounced: dragging a device emits one update per frame, and one upsert
  /// per frame would flood PostgREST. 400 ms still persists a change made just
  /// before leaving the page in practice.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final repository = ref.read(virtualLabRepositoryProvider);

    try {
      // Snapshot + identitas akun diambil bersama di dalam try: keluar akun
      // (accountId null) membatalkan simpan, dan Supabase yang belum
      // ter-inisialisasi (pump halaman di test offline) diperlakukan sama
      // dengan gagal simpan — best-effort, tidak boleh mengganggu lab.
      final accountId = repository.currentUserId;
      if (accountId == null) return; // keluar sebelum debounce selesai

      final snapshot = state.toJson();
      await repository.save(snapshot, forUserId: accountId);
    } catch (_) {
      // Best-effort: a failed save must never interrupt the lab. The next
      // mutation (or the next visit) writes the canvas again.
    }
  }

  void setPlacing(VirtualLabDeviceKind? kind) {
    _commit(VirtualLabSession.setPlacing(state, kind));
  }

  void addDevice(
    VirtualLabDeviceKind kind, {
    Offset? position,
  }) {
    _commit(VirtualLabSession.addDevice(state, kind, position: position));
  }

  void selectDevice(String id) {
    _commit(VirtualLabSession.selectDevice(state, id));
  }

  void selectCable(String id) {
    _commit(VirtualLabSession.selectCable(state, id));
  }

  void moveDevice(String id, Offset delta) {
    _commit(VirtualLabSession.moveDevice(state, id, delta));
  }

  void removeSelected() {
    _commit(VirtualLabSession.removeSelected(state));
  }

  void beginCableFrom(String ownerId) {
    _commit(VirtualLabSession.beginCable(state, ownerId));
  }

  /// Menyelesaikan kabel yang tertunda ke perangkat [to].
  ///
  /// Mengembalikan kode masalah ([VirtualLabSession.cableIssuePcPortFull],
  /// [VirtualLabSession.cableIssueDuplicate]) untuk dilokalkan di UI, atau
  /// null kalau kabel berhasil dibuat / aksi hanya membatalkan pilihan.
  /// Perangkat tujuan tetap dipilih supaya panel konfigurasinya terbuka
  /// walaupun kabelnya gagal.
  String? completeCable(String to) {
    final pending = state.pendingCableFrom;
    if (pending == null) return null;
    if (pending == to) {
      // Ketuk perangkat yang sama = batalkan pembuatan kabel.
      _commit(VirtualLabSession.selectDevice(state, to));
      return null;
    }
    final issue = VirtualLabSession.cableIssue(state, pending, to);
    if (issue != null) {
      _commit(VirtualLabSession.selectDevice(state, to));
      return issue;
    }
    _commit(VirtualLabSession.endCableIfPending(state, to));
    return null;
  }

  /// Membatalkan mode penempatan/pending kabel tanpa menghapus pilihan
  /// perangkat — dipakai tombol "Select" (mode default).
  void cancelModes() {
    _commit(state.copyWith(clearPending: true, clearPlacing: true));
  }

  void toggleCableMode(String ownerId) {
    if (state.pendingCableFrom == null) {
      _commit(VirtualLabSession.beginCable(state, ownerId));
    } else {
      _commit(VirtualLabSession.endCableIfPending(state, ownerId));
    }
  }

  void clearSelection() {
    _commit(VirtualLabSession.clearSelection(state));
  }

  void configureDevice(
    String id, {
    String? name,
    String? ip,
    String? mask,
    String? gateway,
    String? ip2,
    String? mask2,
    VirtualLabIpMode? ipMode,
    String? dns,
    bool? dhcpServerEnabled,
    String? dhcpStartIp,
    String? dhcpSubnetMask,
    String? dhcpGateway,
    String? dhcpDns,
    bool? httpServerEnabled,
    String? httpWebTitle,
    String? httpWebContent,
  }) {
    final idx = state.devices.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final updated = [...state.devices];
    final currentDev = updated[idx];

    final effectiveMask = mask ?? currentDev.subnetMask ?? '255.255.255.0';

    // Selaraskan pool IP jika IP server berubah ke subnet lain
    String? effectiveDhcpStart = dhcpStartIp ?? currentDev.dhcpStartIp;
    if (ip != null &&
        ip.trim().isNotEmpty &&
        effectiveDhcpStart != null &&
        effectiveDhcpStart.trim().isNotEmpty) {
      if (!VirtualLabEngine.sameSubnet(
          ip.trim(), effectiveMask, effectiveDhcpStart.trim(), effectiveMask)) {
        final srvIpv4 = VirtualLabIpv4.parse(ip.trim());
        final oldStartIpv4 = VirtualLabIpv4.parse(effectiveDhcpStart.trim());
        if (srvIpv4 != null) {
          final lastOctet = oldStartIpv4 != null &&
                  oldStartIpv4.octets[3] > 0 &&
                  oldStartIpv4.octets[3] < 254
              ? oldStartIpv4.octets[3]
              : 100;
          effectiveDhcpStart =
              '${srvIpv4.octets[0]}.${srvIpv4.octets[1]}.${srvIpv4.octets[2]}.$lastOctet';
        }
      }
    }

    final String? effectiveDhcpGw;
    final cleanGw = gateway?.trim();
    final cleanDhcpGw = dhcpGateway?.trim();
    if (cleanDhcpGw != null && cleanDhcpGw.isNotEmpty) {
      if (cleanGw != null &&
          cleanGw.isNotEmpty &&
          (cleanDhcpGw == currentDev.defaultGateway ||
              cleanDhcpGw == '192.168.1.1') &&
          cleanGw != cleanDhcpGw) {
        effectiveDhcpGw = cleanGw;
      } else {
        effectiveDhcpGw = cleanDhcpGw;
      }
    } else if (cleanGw != null && cleanGw.isNotEmpty) {
      effectiveDhcpGw = cleanGw;
    } else {
      effectiveDhcpGw = currentDev.dhcpGateway;
    }

    updated[idx] = updated[idx].copyWith(
      name: name,
      ipAddress: ip,
      subnetMask: mask,
      defaultGateway: gateway,
      ipAddress2: ip2,
      subnetMask2: mask2,
      ipMode: ipMode,
      dnsServer: dns,
      dhcpServerEnabled: dhcpServerEnabled,
      dhcpStartIp: effectiveDhcpStart,
      dhcpSubnetMask: dhcpSubnetMask,
      dhcpGateway: effectiveDhcpGw,
      dhcpDns: dhcpDns,
      httpServerEnabled: httpServerEnabled,
      httpWebTitle: httpWebTitle,
      httpWebContent: httpWebContent,
    );
    _commit(state.copyWith(devices: updated));
  }

  VirtualLabDhcpResult requestDhcpLease(String deviceId) {
    final result = VirtualLabDhcpEngine.requestLease(state, deviceId);
    if (result.success && result.ipAddress != null) {
      final idx = state.devices.indexWhere((d) => d.id == deviceId);
      if (idx >= 0) {
        final updated = [...state.devices];
        updated[idx] = updated[idx].copyWith(
          ipMode: VirtualLabIpMode.dhcp,
          ipAddress: result.ipAddress,
          subnetMask: result.subnetMask,
          defaultGateway: result.defaultGateway,
          dnsServer: result.dnsServer,
        );
        _commit(state.copyWith(devices: updated));
      }
    }
    return result;
  }

  void releaseDhcp(String deviceId) {
    final idx = state.devices.indexWhere((d) => d.id == deviceId);
    if (idx < 0) return;
    final updated = [...state.devices];
    updated[idx] = updated[idx].copyWith(
      ipAddress: '0.0.0.0',
      subnetMask: '0.0.0.0',
      defaultGateway: '',
      dnsServer: '',
    );
    _commit(state.copyWith(devices: updated));
  }

  void clearDeviceNetwork(String id) {
    final idx = state.devices.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final updated = [...state.devices];
    updated[idx] = updated[idx].copyWith(clearNetwork: true);
    _commit(state.copyWith(devices: updated));
  }

  void loadPreset(VirtualLabSession preset) {
    _commit(preset);
  }

  /// Memuat sesi topologi kustom dari berkas atau slot penyimpanan lokal.
  void loadSession(VirtualLabSession session) {
    _commit(session);
  }

  /// v1.2: "Reset" di toolbar mengembalikan kanvas ke kondisi awal Skenario 1
  /// (bukan kanvas kosong) supaya mahasiswa dapat mengulang latihan yang
  /// sama dari awal. Kanvas kosong tetap bisa dicapai dengan menghapus
  /// perangkat satu per satu lewat tool Delete.
  void reset() {
    _commit(VirtualLabController.scenarioOne());
  }

  /// Alias lama untuk [reset]; dipertahankan agar pemanggil lama tetap aman.
  void applySampleScenario() {
    _commit(VirtualLabController.scenarioOne());
  }
}

final virtualLabControllerProvider =
    NotifierProvider<VirtualLabController, VirtualLabSession>(
  VirtualLabController.new,
);
