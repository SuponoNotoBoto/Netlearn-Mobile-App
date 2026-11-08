import 'dart:async';

import 'package:flutter/material.dart' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'virtual_lab_model.dart';
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
  }) {
    final idx = state.devices.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final updated = [...state.devices];
    updated[idx] = updated[idx].copyWith(
      name: name,
      ipAddress: ip,
      subnetMask: mask,
      defaultGateway: gateway,
      ipAddress2: ip2,
      subnetMask2: mask2,
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
