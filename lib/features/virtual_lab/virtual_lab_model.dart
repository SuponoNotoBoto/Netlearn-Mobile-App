import 'package:flutter/material.dart' show Offset;
import 'package:flutter/foundation.dart';

enum VirtualLabDeviceKind { pc, switch_, router }

typedef VirtualLabDeviceId = String;

@immutable
class VirtualLabDevice {
  const VirtualLabDevice({
    required this.id,
    required this.kind,
    required this.position,
    this.name,
    this.ipAddress,
    this.subnetMask,
    this.defaultGateway,
    this.ipAddress2,
    this.subnetMask2,
  });

  final VirtualLabDeviceId id;
  final VirtualLabDeviceKind kind;
  final Offset position;

  /// Nama tampilan perangkat — label di bawah ikon pada kanvas (desain Figma
  /// menampilkan PC1/Switch1/Router1). Perangkat baru diberi nama default, dan
  /// mahasiswa dapat menggantinya lewat "Apply configuration".
  final String? name;
  final String? ipAddress;
  final String? subnetMask;
  final String? defaultGateway;
  final String? ipAddress2;
  final String? subnetMask2;

  String get displayName {
    final trimmed = (name ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    switch (kind) {
      case VirtualLabDeviceKind.pc:
        return 'PC';
      case VirtualLabDeviceKind.switch_:
        return 'Switch';
      case VirtualLabDeviceKind.router:
        return 'Router';
    }
  }

  VirtualLabDevice move(Offset delta) {
    return VirtualLabDevice(
      id: id,
      kind: kind,
      position: position + delta,
      name: name,
      ipAddress: ipAddress,
      subnetMask: subnetMask,
      defaultGateway: defaultGateway,
      ipAddress2: ipAddress2,
      subnetMask2: subnetMask2,
    );
  }

  /// Serialized canvas form — only what has to survive a sign-out: the kind,
  /// the position and the network configuration. Selection/cable-pending are
  /// transient UI state and are deliberately not persisted.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'x': position.dx,
      'y': position.dy,
      if (name != null) 'name': name,
      if (ipAddress != null) 'ip': ipAddress,
      if (subnetMask != null) 'mask': subnetMask,
      if (defaultGateway != null) 'gw': defaultGateway,
      if (ipAddress2 != null) 'ip2': ipAddress2,
      if (subnetMask2 != null) 'mask2': subnetMask2,
    };
  }

  factory VirtualLabDevice.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind']?.toString();

    return VirtualLabDevice(
      id: json['id'].toString(),
      kind: VirtualLabDeviceKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => VirtualLabDeviceKind.pc,
      ),
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      name: json['name'] as String?,
      ipAddress: json['ip'] as String?,
      subnetMask: json['mask'] as String?,
      defaultGateway: json['gw'] as String?,
      ipAddress2: json['ip2'] as String?,
      subnetMask2: json['mask2'] as String?,
    );
  }

  VirtualLabDevice copyWith({
    Offset? position,
    String? name,
    String? ipAddress,
    String? subnetMask,
    String? defaultGateway,
    String? ipAddress2,
    String? subnetMask2,
    bool clearNetwork = false,
  }) {
    return VirtualLabDevice(
      id: id,
      kind: kind,
      position: position ?? this.position,
      name: name ?? this.name,
      ipAddress: clearNetwork ? null : (ipAddress ?? this.ipAddress),
      subnetMask: clearNetwork ? null : (subnetMask ?? this.subnetMask),
      defaultGateway:
          clearNetwork ? null : (defaultGateway ?? this.defaultGateway),
      ipAddress2: clearNetwork ? null : (ipAddress2 ?? this.ipAddress2),
      subnetMask2: clearNetwork ? null : (subnetMask2 ?? this.subnetMask2),
    );
  }
}

@immutable
class VirtualLabCable {
  const VirtualLabCable({
    required this.id,
    required this.from,
    required this.to,
  });

  final String id;
  final VirtualLabDeviceId from;
  final VirtualLabDeviceId to;

  bool involves(VirtualLabDeviceId id) => from == id || to == id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
    };
  }

  factory VirtualLabCable.fromJson(Map<String, dynamic> json) {
    return VirtualLabCable(
      id: json['id'].toString(),
      from: json['from'].toString(),
      to: json['to'].toString(),
    );
  }
}

@immutable
class VirtualLabSession {
  const VirtualLabSession({
    this.devices = const [],
    this.cables = const [],
    this.selectedDeviceId,
    this.selectedCableId,
    this.pendingCableFrom,
    this.placingKind,
  });

  final List<VirtualLabDevice> devices;
  final List<VirtualLabCable> cables;
  final VirtualLabDeviceId? selectedDeviceId;
  final String? selectedCableId;
  final VirtualLabDeviceId? pendingCableFrom;
  final VirtualLabDeviceKind? placingKind;

  VirtualLabSession copyWith({
    List<VirtualLabDevice>? devices,
    List<VirtualLabCable>? cables,
    VirtualLabDeviceId? selectedDeviceId,
    bool clearSelection = false,
    String? selectedCableId,
    bool clearCableSelection = false,
    VirtualLabDeviceId? pendingCableFrom,
    bool clearPending = false,
    VirtualLabDeviceKind? placingKind,
    bool clearPlacing = false,
  }) {
    return VirtualLabSession(
      devices: devices ?? this.devices,
      cables: cables ?? this.cables,
      selectedDeviceId: clearSelection
          ? null
          : (selectedDeviceId ?? this.selectedDeviceId),
      selectedCableId: clearCableSelection
          ? null
          : (selectedCableId ?? this.selectedCableId),
      pendingCableFrom:
          clearPending ? null : (pendingCableFrom ?? this.pendingCableFrom),
      placingKind: clearPlacing ? null : (placingKind ?? this.placingKind),
    );
  }

  VirtualLabDevice? deviceById(VirtualLabDeviceId id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Canonical JSON form stored in `virtual_lab_canvases.state`.
  Map<String, dynamic> toJson() {
    return {
      'devices': [for (final d in devices) d.toJson()],
      'cables': [for (final c in cables) c.toJson()],
    };
  }

  /// Rebuilds a session from stored JSON.
  ///
  /// Unreadable entries are dropped rather than failing the whole canvas: one
  /// corrupted row must not brick the lab for that student, and a cable whose
  /// device is gone would otherwise be undrawable.
  factory VirtualLabSession.fromJson(Map<String, dynamic> json) {
    final devices = <VirtualLabDevice>[];
    for (final raw in (json['devices'] as List? ?? const [])) {
      if (raw is Map) {
        devices.add(VirtualLabDevice.fromJson(Map<String, dynamic>.from(raw)));
      }
    }

    final deviceIds = devices.map((d) => d.id).toSet();
    final cables = <VirtualLabCable>[];
    for (final raw in (json['cables'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final cable = VirtualLabCable.fromJson(Map<String, dynamic>.from(raw));
      if (deviceIds.contains(cable.from) && deviceIds.contains(cable.to)) {
        cables.add(cable);
      }
    }

    // Restored ids (`pc_12`, `cable_7`) must not collide with the ids handed
    // out to devices added after the restore.
    reserveIds([
      ...devices.map((d) => d.id),
      ...cables.map((c) => c.id),
    ]);

    return VirtualLabSession(devices: devices, cables: cables);
  }

  /// Raises the id counter above every id in [ids], so a restored canvas and
  /// the devices added afterwards never share an id.
  static void reserveIds(Iterable<String> ids) {
    for (final id in ids) {
      final separator = id.lastIndexOf('_');
      if (separator < 0 || separator == id.length - 1) continue;
      final parsed = int.tryParse(id.substring(separator + 1));
      if (parsed != null && parsed > _counter) _counter = parsed;
    }
  }

  static int _counter = 0;
  static String nextDeviceId(VirtualLabDeviceKind kind) {
    _counter++;
    return '${kind.name}_$_counter';
  }

  static String nextCableId() {
    _counter++;
    return 'cable_$_counter';
  }

  static VirtualLabSession addDevice(
    VirtualLabSession session,
    VirtualLabDeviceKind kind, {
    Offset? position,
  }) {
    final actual = position ??
        Offset(
          120 + 40.0 * (session.devices.length % 5),
          100 + 40.0 * (session.devices.length ~/ 5),
        );
    // Nama default mengikuti pola desain (PC1, PC2, Switch1, ...) supaya
    // label di kanvas langsung terbaca sebelum mahasiswa menggantinya.
    final baseLabel = switch (kind) {
      VirtualLabDeviceKind.pc => 'PC',
      VirtualLabDeviceKind.switch_ => 'Switch',
      VirtualLabDeviceKind.router => 'Router',
    };
    final ordinal =
        session.devices.where((d) => d.kind == kind).length + 1;
    final device = VirtualLabDevice(
      id: nextDeviceId(kind),
      kind: kind,
      position: actual,
      name: '$baseLabel$ordinal',
    );
    return session.copyWith(
      devices: [...session.devices, device],
      selectedDeviceId: device.id,
      clearCableSelection: true,
      clearPending: true,
      clearPlacing: true,
    );
  }

  static VirtualLabSession removeSelected(VirtualLabSession session) {
    final selectedCable = session.selectedCableId;
    final selectedDevice = session.selectedDeviceId;
    if (selectedDevice != null) {
      return VirtualLabSession(
        devices: session.devices
            .where((d) => d.id != selectedDevice)
            .toList(),
        cables: session.cables
            .where((c) => !c.involves(selectedDevice))
            .toList(),
        selectedDeviceId: null,
        selectedCableId: selectedCable,
        pendingCableFrom: session.pendingCableFrom == selectedDevice
            ? null
            : session.pendingCableFrom,
        placingKind: session.placingKind,
      );
    }
    if (selectedCable != null) {
      return session.copyWith(
        cables: session.cables.where((c) => c.id != selectedCable).toList(),
        clearCableSelection: true,
      );
    }
    return session;
  }

  static VirtualLabSession moveDevice(
    VirtualLabSession session,
    VirtualLabDeviceId id,
    Offset delta,
  ) {
    final idx = session.devices.indexWhere((d) => d.id == id);
    if (idx < 0) return session;
    final updated = [...session.devices];
    updated[idx] = updated[idx].move(delta);
    return session.copyWith(devices: updated, selectedDeviceId: id);
  }

  static VirtualLabSession selectDevice(
    VirtualLabSession session,
    VirtualLabDeviceId id,
  ) {
    return session.copyWith(
      selectedDeviceId: id,
      clearCableSelection: true,
      clearPending: true,
    );
  }

  static VirtualLabSession selectCable(
    VirtualLabSession session,
    String id,
  ) {
    return session.copyWith(
      selectedCableId: id,
      clearSelection: true,
      clearPending: true,
    );
  }

  static VirtualLabSession clearSelection(VirtualLabSession session) {
    return session.copyWith(
      clearSelection: true,
      clearCableSelection: true,
      clearPending: true,
    );
  }

  static VirtualLabSession beginCable(
    VirtualLabSession session,
    VirtualLabDeviceId from,
  ) {
    return session.copyWith(pendingCableFrom: from, clearSelection: false);
  }

  /// Kode masalah pembuatan kabel — string mentah, dilokalkan di UI supaya
  /// model tetap bebas dari AppLocalizations.
  static const String cableIssueSameDevice = 'same_device';
  static const String cableIssueDuplicate = 'duplicate';
  static const String cableIssueMissingDevice = 'missing_device';
  static const String cableIssuePcPortFull = 'pc_port_full';
  static const String cableIssueRouterPortFull = 'router_port_full';

  static int cableCount(VirtualLabSession session, VirtualLabDeviceId id) =>
      session.cables.where((c) => c.involves(id)).length;

  /// Validasi *sebelum* kabel dibuat. Aturan port:
  /// - PC: 1 port NIC (maks 1 kabel).
  /// - Router: 2 port Ethernet (eth0 & eth1, maks 2 kabel).
  /// - Switch: multi-port (tidak dibatasi).
  static String? cableIssue(
    VirtualLabSession session,
    VirtualLabDeviceId a,
    VirtualLabDeviceId b,
  ) {
    if (a == b) return cableIssueSameDevice;
    final deviceA = session.deviceById(a);
    final deviceB = session.deviceById(b);
    if (deviceA == null || deviceB == null) return cableIssueMissingDevice;
    for (final c in session.cables) {
      if (c.from == a && c.to == b || c.from == b && c.to == a) {
        return cableIssueDuplicate;
      }
    }
    if (deviceA.kind == VirtualLabDeviceKind.pc &&
        cableCount(session, a) >= 1) {
      return cableIssuePcPortFull;
    }
    if (deviceB.kind == VirtualLabDeviceKind.pc &&
        cableCount(session, b) >= 1) {
      return cableIssuePcPortFull;
    }
    if (deviceA.kind == VirtualLabDeviceKind.router &&
        cableCount(session, a) >= 2) {
      return cableIssueRouterPortFull;
    }
    if (deviceB.kind == VirtualLabDeviceKind.router &&
        cableCount(session, b) >= 2) {
      return cableIssueRouterPortFull;
    }
    return null;
  }

  static VirtualLabSession? connect(
    VirtualLabSession session,
    VirtualLabDeviceId a,
    VirtualLabDeviceId b,
  ) {
    if (cableIssue(session, a, b) != null) return null;
    final cable = VirtualLabCable(
      id: nextCableId(),
      from: a,
      to: b,
    );
    return session.copyWith(
      cables: [...session.cables, cable],
      selectedCableId: cable.id,
      clearSelection: true,
      clearPending: true,
    );
  }

  static VirtualLabSession endCableIfPending(
    VirtualLabSession session,
    VirtualLabDeviceId to,
  ) {
    final pending = session.pendingCableFrom;
    if (pending == null) return session;
    final result = connect(session, pending, to);
    if (result == null) {
      return session.copyWith(clearPending: true);
    }
    return result;
  }

  static VirtualLabSession reset(VirtualLabSession session) {
    return const VirtualLabSession();
  }

  static VirtualLabSession setPlacing(
    VirtualLabSession session,
    VirtualLabDeviceKind? kind,
  ) {
    return session.copyWith(
      placingKind: kind,
      clearPlacing: kind == null,
    );
  }
}
