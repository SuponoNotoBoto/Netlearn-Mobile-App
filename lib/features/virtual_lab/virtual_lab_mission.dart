// ============================================================================
// MODULE: Virtual Lab Automated Mission Evaluator & Checker Engine
// DESCRIPTION: Mesin auto-grader praktikum jaringan yang mengevaluasi secara
//              otomatis kelengkapan perkabelan, keabsahan IP/Subnet, routing,
//              serta uji konektivitas paket ICMP ping untuk Modul 1 sampai 4.
// ============================================================================

import 'package:flutter/foundation.dart';

import '../materials/material_lab_binding.dart';
import 'virtual_lab_model.dart';
import 'virtual_lab_network.dart';

// ---------------------------------------------------------------------------
// SECTION: Mission Objective Models & Submission Reports
// ---------------------------------------------------------------------------

/// [VirtualLabMissionTask]
///
/// Merepresentasikan satu butir target capaian dalam skenario praktikum lab
/// (misal: "Hubungkan PC1 ke Switch menggunakan kabel Straight").
@immutable
class VirtualLabMissionTask {
  final String id;
  final String title;
  final String description;
  final String? hint;
  final bool isCompleted;
  final String? failureReason;

  const VirtualLabMissionTask({
    required this.id,
    required this.title,
    required this.description,
    this.hint,
    this.isCompleted = false,
    this.failureReason,
  });

  VirtualLabMissionTask copyWith({
    String? id,
    String? title,
    String? description,
    String? hint,
    bool? isCompleted,
    String? failureReason,
  }) {
    return VirtualLabMissionTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hint: hint ?? this.hint,
      isCompleted: isCompleted ?? this.isCompleted,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        if (hint != null) 'hint': hint,
        'is_completed': isCompleted,
        if (failureReason != null) 'failure_reason': failureReason,
      };

  factory VirtualLabMissionTask.fromJson(Map<String, dynamic> json) {
    return VirtualLabMissionTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      hint: json['hint']?.toString(),
      isCompleted: json['is_completed'] == true,
      failureReason: json['failure_reason']?.toString(),
    );
  }
}

/// Laporan hasil evaluasi seluruh target misi praktikum saat ini.
@immutable
class VirtualLabMissionReport {
  final String materialId;
  final String materialTitle;
  final String preset;
  final List<VirtualLabMissionTask> tasks;
  final DateTime evaluatedAt;
  final String languageCode;

  const VirtualLabMissionReport({
    required this.materialId,
    required this.materialTitle,
    required this.preset,
    required this.tasks,
    required this.evaluatedAt,
    this.languageCode = 'id',
  });

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.isCompleted).length;
  bool get isPassed => totalTasks > 0 && completedTasks == totalTasks;

  /// Skor nilai 0 sampai 100 berdasarkan proporsi tugas yang telah terselesaikan.
  int get score =>
      totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

  String summary([String? lang]) {
    final isEn = (lang ?? languageCode) == 'en';
    if (isPassed) {
      return isEn
          ? 'Great job! All $totalTasks practical objectives completed.'
          : 'Luar biasa! Seluruh $totalTasks target praktikum berhasil diselesaikan.';
    }
    return isEn
        ? '$completedTasks of $totalTasks practical objectives completed ($score%).'
        : '$completedTasks dari $totalTasks target praktikum selesai ($score%).';
  }

  String get summaryText => summary();
}

/// Rekam jejak pengumpulan evaluasi praktikum oleh mahasiswa
/// yang disimpan permanen ke database Cloud & Cache lokal.
@immutable
class VirtualLabMissionSubmission {
  final String id;
  final String userId;
  final String materialId;
  final String materialTitle;
  final String preset;
  final int score;
  final bool isPassed;
  final DateTime submittedAt;
  final List<String> completedTaskIds;
  final int totalTasks;
  final Map<String, dynamic>? topologySnapshot;

  const VirtualLabMissionSubmission({
    required this.id,
    required this.userId,
    required this.materialId,
    required this.materialTitle,
    required this.preset,
    required this.score,
    required this.isPassed,
    required this.submittedAt,
    required this.completedTaskIds,
    required this.totalTasks,
    this.topologySnapshot,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'material_id': materialId,
        'material_title': materialTitle,
        'preset': preset,
        'score': score,
        'is_passed': isPassed,
        'submitted_at': submittedAt.toUtc().toIso8601String(),
        'completed_task_ids': completedTaskIds,
        'total_tasks': totalTasks,
        if (topologySnapshot != null) 'topology_snapshot': topologySnapshot,
      };

  factory VirtualLabMissionSubmission.fromJson(Map<String, dynamic> json) {
    return VirtualLabMissionSubmission(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      materialId: json['material_id']?.toString() ?? '',
      materialTitle: json['material_title']?.toString() ?? '',
      preset: json['preset']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      isPassed: json['is_passed'] == true,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedTaskIds: (json['completed_task_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      topologySnapshot: json['topology_snapshot'] is Map
          ? Map<String, dynamic>.from(json['topology_snapshot'] as Map)
          : null,
    );
  }
}

/// Mesin otomatis pengecek dan penilai kelayakan topologi jaringan (Mission Checker).
class VirtualLabMissionEvaluator {
  /// Mengevaluasi kondisi sesi [session] saat ini terhadap target praktikum [binding].
  static VirtualLabMissionReport evaluate({
    required VirtualLabSession session,
    required MaterialLabBinding binding,
    VirtualLabConnectivityResult? lastTest,
    String? pingSourceId,
    String? pingTargetId,
    String languageCode = 'id',
  }) {
    final isEn = languageCode == 'en';
    final effectivePreset = _resolvePresetType(binding);
    final materialId = binding.materialId ?? effectivePreset;
    final localizedBinding = binding.localized(languageCode);
    final materialTitle = localizedBinding.title;

    List<VirtualLabMissionTask> tasks;

    switch (effectivePreset) {
      case 'p2p':
        tasks = _evaluateP2P(session, lastTest, isEn);
        break;
      case 'star':
        tasks = _evaluateStar(session, lastTest, isEn);
        break;
      case 'dual_subnet':
        tasks = _evaluateDualSubnet(session, lastTest, isEn);
        break;
      case 'dhcp_server':
        tasks = _evaluateDhcpServer(session, lastTest, isEn);
        break;
      default:
        tasks = _evaluateCustomOrGeneral(session, lastTest, isEn);
        break;
    }

    return VirtualLabMissionReport(
      materialId: materialId,
      materialTitle: materialTitle,
      preset: effectivePreset,
      tasks: tasks,
      evaluatedAt: DateTime.now(),
      languageCode: languageCode,
    );
  }

  static String _resolvePresetType(MaterialLabBinding binding) {
    if (binding.referencePreset != null &&
        binding.referencePreset!.isNotEmpty &&
        binding.referencePreset != 'blank') {
      return binding.referencePreset!;
    }
    if (binding.preset != 'blank' && binding.preset != 'custom') {
      return binding.preset;
    }
    final titleLower = binding.title.toLowerCase();
    if (titleLower.contains('peer') || titleLower.contains('p2p')) {
      return 'p2p';
    }
    if (titleLower.contains('star') || titleLower.contains('switch')) {
      return 'star';
    }
    if (titleLower.contains('routing') ||
        titleLower.contains('router') ||
        titleLower.contains('subnet')) {
      return 'dual_subnet';
    }
    if (titleLower.contains('dhcp') ||
        titleLower.contains('web') ||
        titleLower.contains('server')) {
      return 'dhcp_server';
    }
    return binding.preset;
  }

  // ===========================================================================
  // Modul 1: Jaringan Dasar & Peer-to-Peer (P2P)
  // ===========================================================================
  static List<VirtualLabMissionTask> _evaluateP2P(
    VirtualLabSession session,
    VirtualLabConnectivityResult? lastTest,
    bool isEn,
  ) {
    final pcs = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.pc)
        .toList();

    // 1. Minimal 2 PC
    final hasTwoPcs = pcs.length >= 2;

    // 2. Terhubung kabel langsung antar 2 PC
    bool hasP2pCable = false;
    VirtualLabDevice? pcA;
    VirtualLabDevice? pcB;
    if (hasTwoPcs) {
      for (final cable in session.cables) {
        final devFrom = session.deviceById(cable.from);
        final devTo = session.deviceById(cable.to);
        if (devFrom?.kind == VirtualLabDeviceKind.pc &&
            devTo?.kind == VirtualLabDeviceKind.pc) {
          hasP2pCable = true;
          pcA = devFrom;
          pcB = devTo;
          break;
        }
      }
    }

    // 3. Konfigurasi IP Statis valid dalam satu subnet
    bool hasValidIpConfig = false;
    String? ipError;
    if (hasTwoPcs) {
      final configuredPcs = pcs.where((p) {
        final ip = VirtualLabIpv4.parse(p.ipAddress ?? '');
        final mask = VirtualLabSubnetMask.parse(p.subnetMask ?? '');
        return ip != null && mask != null;
      }).toList();

      if (configuredPcs.length < 2) {
        ipError = isEn
            ? 'At least 2 PCs must have an IP Address & Subnet Mask.'
            : 'Minimal 2 PC harus memiliki alamat IP & Subnet Mask.';
      } else {
        final d1 = configuredPcs[0];
        final d2 = configuredPcs[1];
        if (d1.ipAddress == d2.ipAddress) {
          ipError = isEn
              ? 'IP Conflict: Both PCs have the same IP address.'
              : 'Konflik IP: Kedua PC memiliki alamat IP yang sama.';
        } else if (!VirtualLabEngine.sameSubnet(
          d1.ipAddress!,
          d1.subnetMask!,
          d2.ipAddress!,
          d2.subnetMask!,
        )) {
          ipError = isEn
              ? 'Both PCs are on different subnets.'
              : 'Kedua PC berada pada subnet yang berbeda.';
        } else {
          hasValidIpConfig = true;
        }
      }
    }

    // 4. Tes konektivitas Ping berhasil
    bool hasSuccessfulPing = false;
    if (hasP2pCable && hasValidIpConfig && pcA != null && pcB != null) {
      if (lastTest != null && lastTest.success) {
        hasSuccessfulPing = true;
      } else {
        final test = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: pcA.id,
          targetId: pcB.id,
        );
        if (test.success) {
          hasSuccessfulPing = true;
        }
      }
    }

    return [
      VirtualLabMissionTask(
        id: 'p2p_t1_nodes',
        title: isEn
            ? 'Add at Least 2 PCs to Canvas'
            : 'Tambahkan Minimal 2 PC ke Kanvas',
        description: isEn
            ? 'Place at least two PC devices on the workspace canvas.'
            : 'Tempatkan minimal dua perangkat PC pada area kanvas kerja.',
        hint: isEn
            ? 'Use the Add Device panel below and select the PC icon.'
            : 'Gunakan panel Tambah Perangkat di bawah lalu pilih ikon PC.',
        isCompleted: hasTwoPcs,
        failureReason: hasTwoPcs
            ? null
            : (isEn
                ? 'Currently ${pcs.length} PCs on canvas (at least 2 required).'
                : 'Saat ini terdapat ${pcs.length} PC di kanvas (dibutuhkan minimal 2).'),
      ),
      VirtualLabMissionTask(
        id: 'p2p_t2_cable',
        title: isEn
            ? 'Connect Both PCs with Network Cable'
            : 'Hubungkan Kedua PC dengan Kabel Jaringan',
        description: isEn
            ? 'Connect a direct network cable between NIC ports of PC 1 and PC 2.'
            : 'Tarik kabel jaringan langsung yang menghubungkan port NIC PC 1 ke PC 2.',
        hint: isEn
            ? 'Tap the first PC, press "Start Cabling", then tap the second PC.'
            : 'Ketuk PC pertama, tekan "Mulai Pasang Kabel", lalu ketuk PC kedua.',
        isCompleted: hasP2pCable,
        failureReason: hasP2pCable
            ? null
            : (isEn
                ? 'No cable directly connecting both PCs yet.'
                : 'Belum ada kabel yang menghubungkan kedua PC secara langsung.'),
      ),
      VirtualLabMissionTask(
        id: 'p2p_t3_ip',
        title: isEn
            ? 'Configure Static IP in Same Subnet'
            : 'Atur Alamat IP Statis Satu Subnet',
        description: isEn
            ? 'Configure IPs for both PCs (e.g. 192.168.1.1 & 192.168.1.2 with mask 255.255.255.0).'
            : 'Konfigurasi IP kedua PC (misal: 192.168.1.1 & 192.168.1.2 dengan mask 255.255.255.0).',
        hint: isEn
            ? 'Select PC, open IP Configuration tab, and save IP parameters.'
            : 'Pilih PC, buka tab Konfigurasi IP, lalu simpan parameter IP.',
        isCompleted: hasValidIpConfig,
        failureReason: ipError,
      ),
      VirtualLabMissionTask(
        id: 'p2p_t4_ping',
        title: isEn
            ? 'Test Ping Connectivity Successfully (100%)'
            : 'Uji Konektivitas Ping Berhasil (100%)',
        description: isEn
            ? 'Perform a Ping test between both PCs and ensure packets arrive successfully.'
            : 'Lakukan pengujian Ping antara kedua PC dan pastikan paket berhasil sampai.',
        hint: isEn
            ? 'Select source PC, tap Test Ping to target PC, or use terminal: ping <target_ip>.'
            : 'Pilih PC sumber, tekan tombol Uji Ping ke PC tujuan, atau gunakan terminal: ping <ip_tujuan>.',
        isCompleted: hasSuccessfulPing,
        failureReason: hasSuccessfulPing
            ? null
            : (isEn
                ? 'No successful Ping test between both PCs yet.'
                : 'Belum ada pengujian Ping yang berhasil antara kedua PC.'),
      ),
    ];
  }

  // ===========================================================================
  // Modul 2: Topologi Star & Switch LAN
  // ===========================================================================
  static List<VirtualLabMissionTask> _evaluateStar(
    VirtualLabSession session,
    VirtualLabConnectivityResult? lastTest,
    bool isEn,
  ) {
    final switches = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.switch_)
        .toList();
    final pcs = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.pc)
        .toList();

    // 1. Min 1 Switch dan 3 PC
    final hasNodes = switches.isNotEmpty && pcs.length >= 3;

    // 2. Minimal 3 PC terkoneksi ke Switch
    bool hasThreeCabledToSwitch = false;
    VirtualLabDevice? primarySwitch;
    final cabledPcs = <VirtualLabDevice>[];

    if (switches.isNotEmpty) {
      primarySwitch = switches.first;
      for (final pc in pcs) {
        final isConnected = session.cables.any((c) =>
            (c.from == pc.id && c.to == primarySwitch!.id) ||
            (c.to == pc.id && c.from == primarySwitch!.id));
        if (isConnected) {
          cabledPcs.add(pc);
        }
      }
      hasThreeCabledToSwitch = cabledPcs.length >= 3;
    }

    // 3. Konfigurasi IP Unik Satu Subnet pada 3 PC
    bool hasValidSubnet = false;
    String? ipError;
    if (cabledPcs.length >= 3) {
      final validPcs = cabledPcs.where((p) {
        final ip = VirtualLabIpv4.parse(p.ipAddress ?? '');
        final mask = VirtualLabSubnetMask.parse(p.subnetMask ?? '');
        return ip != null && mask != null;
      }).toList();

      if (validPcs.length < 3) {
        ipError = isEn
            ? 'At least 3 PCs must have valid IP & Subnet Mask.'
            : 'Minimal 3 PC harus memiliki IP & Subnet Mask valid.';
      } else {
        final ipSet = <String>{};
        bool collision = false;
        for (final p in validPcs) {
          if (!ipSet.add(p.ipAddress!)) {
            collision = true;
            break;
          }
        }
        if (collision) {
          ipError = isEn
              ? 'IP Conflict: There are PCs with the same IP address.'
              : 'Terdapat konflik IP: Ada PC dengan IP yang sama.';
        } else {
          final basePc = validPcs.first;
          final allSameSubnet = validPcs.skip(1).every((p) =>
              VirtualLabEngine.sameSubnet(basePc.ipAddress!,
                  basePc.subnetMask!, p.ipAddress!, p.subnetMask!));
          if (!allSameSubnet) {
            ipError = isEn
                ? 'All PCs must be within the same subnet.'
                : 'Semua PC harus berada dalam satu subnet yang sama.';
          } else {
            hasValidSubnet = true;
          }
        }
      }
    }

    // 4. Ping sukses antar PC via Switch
    bool hasSuccessfulPing = false;
    if (hasThreeCabledToSwitch && hasValidSubnet && cabledPcs.length >= 2) {
      if (lastTest != null && lastTest.success) {
        hasSuccessfulPing = true;
      } else {
        final test = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: cabledPcs[0].id,
          targetId: cabledPcs[1].id,
        );
        if (test.success) {
          hasSuccessfulPing = true;
        }
      }
    }

    return [
      VirtualLabMissionTask(
        id: 'star_t1_nodes',
        title: isEn
            ? 'Add 1 Switch & at Least 3 PCs'
            : 'Tambahkan 1 Switch & Minimal 3 PC',
        description: isEn
            ? 'Place 1 Switch device as concentrator and at least 3 workstation PCs.'
            : 'Tempatkan 1 perangkat Switch sebagai konsentrator dan minimal 3 PC workstation.',
        hint: isEn
            ? 'Use the Add Device menu to add 1 Switch and 3 PCs.'
            : 'Gunakan menu Tambah Perangkat untuk menambahkan Switch dan 3 PC.',
        isCompleted: hasNodes,
        failureReason: hasNodes
            ? null
            : (isEn
                ? 'Currently ${switches.length} Switch and ${pcs.length} PCs.'
                : 'Saat ini terdapat ${switches.length} Switch dan ${pcs.length} PC.'),
      ),
      VirtualLabMissionTask(
        id: 'star_t2_cables',
        title: isEn
            ? 'Connect All PCs to Switch Ports'
            : 'Hubungkan Seluruh PC ke Port Switch',
        description: isEn
            ? 'Connect straight-through cables from each PC to the Switch forming a Star.'
            : 'Pasang kabel straight-through dari masing-masing PC ke Switch membentuk bintang (Star).',
        hint: isEn
            ? 'Run cables from each PC directly to the Switch.'
            : 'Tarik kabel dari setiap PC langsung menuju Switch.',
        isCompleted: hasThreeCabledToSwitch,
        failureReason: hasThreeCabledToSwitch
            ? null
            : (isEn
                ? 'Only ${cabledPcs.length} PCs connected to Switch (min. 3 required).'
                : 'Baru ${cabledPcs.length} PC yang terhubung ke Switch (dibutuhkan min. 3).'),
      ),
      VirtualLabMissionTask(
        id: 'star_t3_subnet',
        title: isEn
            ? 'Configure Unique IPs in Same Subnet (e.g. 192.168.1.0/24)'
            : 'Konfigurasi IP Unik Satu Subnet (Contoh: 192.168.1.0/24)',
        description: isEn
            ? 'Give each PC a different IP address in the same subnet segment.'
            : 'Beri tiap PC alamat IP yang berbeda dalam satu segmen subnet yang sama.',
        hint: isEn
            ? 'Example: PC1=192.168.1.10, PC2=192.168.1.20, PC3=192.168.1.30.'
            : 'Contoh: PC1=192.168.1.10, PC2=192.168.1.20, PC3=192.168.1.30.',
        isCompleted: hasValidSubnet,
        failureReason: ipError,
      ),
      VirtualLabMissionTask(
        id: 'star_t4_ping',
        title: isEn
            ? 'Test Ping Between PCs via Switch Successfully'
            : 'Uji Ping Antar-PC Melalui Switch Berhasil',
        description: isEn
            ? 'Perform Ping test between workstations through the Switch and ensure success.'
            : 'Lakukan pengujian Ping antar workstation melalui Switch dan pastikan terkirim sukses.',
        hint: isEn
            ? 'Send Ping from PC1 to PC2 or PC3 via test dialog or terminal.'
            : 'Kirim Ping dari PC1 ke PC2 atau PC3 melalui dialog uji koneksi atau terminal.',
        isCompleted: hasSuccessfulPing,
        failureReason: hasSuccessfulPing
            ? null
            : (isEn
                ? 'No successful Ping test between PCs on the Switch network yet.'
                : 'Belum ada pengujian Ping yang berhasil antar-PC di jaringan Switch.'),
      ),
    ];
  }

  // ===========================================================================
  // Modul 3: Routing Statis & Multi-Subnet (Router)
  // ===========================================================================
  static List<VirtualLabMissionTask> _evaluateDualSubnet(
    VirtualLabSession session,
    VirtualLabConnectivityResult? lastTest,
    bool isEn,
  ) {
    final routers = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.router)
        .toList();
    final pcs = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.pc)
        .toList();

    // 1. Min 1 Router dan 2 PC
    final hasNodes = routers.isNotEmpty && pcs.length >= 2;

    // 2. Router memiliki 2 port terkonfigurasi dengan subnet berbeda & terhubung
    bool hasRouterTwoSubnets = false;
    VirtualLabDevice? activeRouter;
    String? routerError;

    if (routers.isNotEmpty) {
      activeRouter = routers.first;
      final ip1 = VirtualLabIpv4.parse(activeRouter.ipAddress ?? '');
      final mask1 = VirtualLabSubnetMask.parse(activeRouter.subnetMask ?? '');
      final ip2 = VirtualLabIpv4.parse(activeRouter.ipAddress2 ?? '');
      final mask2 = VirtualLabSubnetMask.parse(activeRouter.subnetMask2 ?? '');

      if (ip1 == null || mask1 == null || ip2 == null || mask2 == null) {
        routerError = isEn
            ? 'Router must have IP & Subnet Mask configured on Port 1 and Port 2.'
            : 'Router harus memiliki IP & Subnet Mask pada Port 1 dan Port 2.';
      } else if (VirtualLabEngine.sameSubnet(
        activeRouter.ipAddress!,
        activeRouter.subnetMask!,
        activeRouter.ipAddress2!,
        activeRouter.subnetMask2!,
      )) {
        routerError = isEn
            ? 'Router Port 1 and Port 2 cannot be in the same subnet.'
            : 'Port 1 dan Port 2 Router tidak boleh berada pada subnet yang sama.';
      } else {
        final routerCables =
            session.cables.where((c) => c.involves(activeRouter!.id)).length;
        if (routerCables < 2) {
          routerError = isEn
              ? 'Both Router ports must be connected with cables to different network segments.'
              : 'Kedua port Router harus terhubung kabel ke segmen jaringan yang berbeda.';
        } else {
          hasRouterTwoSubnets = true;
        }
      }
    }

    // 3. Konfigurasi Default Gateway pada PC
    bool hasGatewaysConfigured = false;
    String? gwError;
    if (hasNodes && activeRouter != null) {
      final pcsWithGw = pcs.where((p) {
        final gw = p.defaultGateway?.trim();
        return gw != null && gw.isNotEmpty && VirtualLabIpv4.parse(gw) != null;
      }).toList();

      if (pcsWithGw.length < 2) {
        gwError = isEn
            ? 'At least 2 PCs must have a Default Gateway configured.'
            : 'Minimal 2 PC harus memiliki alamat Default Gateway.';
      } else {
        final rIp1 = activeRouter.ipAddress;
        final rIp2 = activeRouter.ipAddress2;
        final matchesRouter = pcsWithGw.every(
            (p) => p.defaultGateway == rIp1 || p.defaultGateway == rIp2);
        if (!matchesRouter) {
          gwError = isEn
              ? 'PC Default Gateway must point to a Router interface IP.'
              : 'Default Gateway PC harus mengarah ke IP interface Router.';
        } else {
          hasGatewaysConfigured = true;
        }
      }
    }

    // 4. Uji Ping melintasi Router (antar-subnet)
    bool hasCrossSubnetPingSuccess = false;
    if (hasRouterTwoSubnets && hasGatewaysConfigured && pcs.length >= 2) {
      if (lastTest != null && lastTest.success) {
        hasCrossSubnetPingSuccess = true;
      } else {
        final test = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: pcs[0].id,
          targetId: pcs[1].id,
        );
        if (test.success) {
          hasCrossSubnetPingSuccess = true;
        }
      }
    }

    return [
      VirtualLabMissionTask(
        id: 'route_t1_nodes',
        title: isEn
            ? 'Add 1 Router & at Least 2 PCs'
            : 'Tambahkan 1 Router & Minimal 2 PC',
        description: isEn
            ? 'Place a 2-port Router and workstation PCs on both subnet sides.'
            : 'Tempatkan Router 2-port dan workstation PC di kedua sisi subnet.',
        hint: isEn
            ? 'Add 1 Router and at least 2 PCs (or switches for each subnet).'
            : 'Tambahkan 1 Router dan minimal 2 PC (atau switch untuk masing-masing subnet).',
        isCompleted: hasNodes,
        failureReason: hasNodes
            ? null
            : (isEn
                ? 'Currently ${routers.length} Router and ${pcs.length} PCs.'
                : 'Saat ini terdapat ${routers.length} Router dan ${pcs.length} PC.'),
      ),
      VirtualLabMissionTask(
        id: 'route_t2_router_ports',
        title: isEn
            ? 'Configure 2 Router Ports on Different Subnets'
            : 'Konfigurasi 2 Port Router di Subnet Berbeda',
        description: isEn
            ? 'Set Port 1 (e.g. 192.168.1.1/24) and Port 2 (e.g. 192.168.2.1/24) and connect cables.'
            : 'Atur Port 1 (contoh: 192.168.1.1/24) dan Port 2 (contoh: 192.168.2.1/24) serta hubungkan kabel.',
        hint: isEn
            ? 'Select Router, open IP config for Port 1 & 2, then connect cables to each subnet.'
            : 'Pilih Router, buka konfigurasi IP Port 1 & Port 2, lalu hubungkan kabel ke masing-masing subnet.',
        isCompleted: hasRouterTwoSubnets,
        failureReason: routerError,
      ),
      VirtualLabMissionTask(
        id: 'route_t3_gateway',
        title: isEn
            ? 'Configure Default Gateway on Workstation PCs'
            : 'Atur Default Gateway pada Workstation PC',
        description: isEn
            ? 'Point each PC Default Gateway to the Router IP in the same subnet segment.'
            : 'Arahkan Default Gateway tiap PC ke IP port Router pada segmen subnet yang sama.',
        hint: isEn
            ? 'PCs in Subnet 1 use Port 1 Gateway, PCs in Subnet 2 use Port 2 Gateway.'
            : 'PC di Subnet 1 memakai Gateway Port 1, PC di Subnet 2 memakai Gateway Port 2.',
        isCompleted: hasGatewaysConfigured,
        failureReason: gwError,
      ),
      VirtualLabMissionTask(
        id: 'route_t4_cross_ping',
        title: isEn
            ? 'Test Cross-Subnet Ping Across Router Successfully'
            : 'Uji Ping Lintas Subnet Melalui Router Berhasil',
        description: isEn
            ? 'Perform Ping or Tracert test between PCs in different subnets.'
            : 'Lakukan pengujian Ping atau Tracert antar PC yang berada di subnet berbeda.',
        hint: isEn
            ? 'Use terminal: tracert <target_ip> or Ping from PC in Subnet 1 to PC in Subnet 2.'
            : 'Gunakan terminal tracert <ip_tujuan> atau uji Ping dari PC Subnet 1 ke PC Subnet 2.',
        isCompleted: hasCrossSubnetPingSuccess,
        failureReason: hasCrossSubnetPingSuccess
            ? null
            : (isEn
                ? 'No cross-subnet Ping test across Router successful yet.'
                : 'Belum ada pengujian Ping melintasi Router yang berhasil.'),
      ),
    ];
  }

  // ===========================================================================
  // Modul 4: Server Layanan Jaringan (DHCP & Web HTTP)
  // ===========================================================================
  static List<VirtualLabMissionTask> _evaluateDhcpServer(
    VirtualLabSession session,
    VirtualLabConnectivityResult? lastTest,
    bool isEn,
  ) {
    final servers = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.server)
        .toList();
    final pcs = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.pc)
        .toList();

    // 1. Min 1 Server dan 1 PC
    final hasNodes = servers.isNotEmpty && pcs.isNotEmpty;

    // 2. Server dan PC terhubung kabel (langsung atau via switch)
    bool hasConnectedPath = false;
    VirtualLabDevice? server;
    if (hasNodes) {
      final srv = servers.first;
      server = srv;
      for (final pc in pcs) {
        // Cek koneksi langsung
        final direct = session.cables.any((c) =>
            (c.from == srv.id && c.to == pc.id) ||
            (c.to == srv.id && c.from == pc.id));
        if (direct) {
          hasConnectedPath = true;
          break;
        }
        // Cek via switch
        for (final sw in session.devices
            .where((d) => d.kind == VirtualLabDeviceKind.switch_)) {
          final swToServer = session.cables.any((c) =>
              (c.from == srv.id && c.to == sw.id) ||
              (c.to == srv.id && c.from == sw.id));
          final swToPc = session.cables.any((c) =>
              (c.from == pc.id && c.to == sw.id) ||
              (c.to == pc.id && c.from == sw.id));
          if (swToServer && swToPc) {
            hasConnectedPath = true;
            break;
          }
        }
        if (hasConnectedPath) break;
      }
    }

    // 3. Layanan DHCP atau HTTP Server aktif pada Server
    bool hasServiceActive = false;
    String? serviceError;
    if (servers.isNotEmpty) {
      final s = servers.first;
      if (s.dhcpServerEnabled || s.httpServerEnabled) {
        hasServiceActive = true;
      } else {
        serviceError = isEn
            ? 'Enable DHCP Server or HTTP Web Server service on the Server.'
            : 'Aktifkan layanan DHCP Server atau HTTP Web Server pada Server.';
      }
    }

    // 4. PC client berhasil memperoleh IP DHCP atau ping/curl sukses
    bool hasClientSuccess = false;
    if (hasConnectedPath && hasServiceActive) {
      final hasDhcpClient = pcs.any((p) =>
          p.ipMode == VirtualLabIpMode.dhcp &&
          p.ipAddress != null &&
          p.ipAddress!.isNotEmpty);
      if (hasDhcpClient) {
        hasClientSuccess = true;
      } else if (lastTest != null && lastTest.success) {
        hasClientSuccess = true;
      } else if (server != null && pcs.isNotEmpty) {
        final test = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: pcs.first.id,
          targetId: server.id,
        );
        if (test.success) {
          hasClientSuccess = true;
        }
      }
    }

    return [
      VirtualLabMissionTask(
        id: 'dhcp_t1_nodes',
        title: isEn
            ? 'Add 1 Server & at Least 1 PC Client'
            : 'Tambahkan 1 Server & Minimal 1 PC Client',
        description: isEn
            ? 'Place a Campus Server and PC client that will utilize network services.'
            : 'Tempatkan unit Server Kampus dan PC client yang akan memanfaatkan layanan jaringan.',
        hint: isEn
            ? 'Use the Add Device panel and select Server and PC.'
            : 'Gunakan panel Tambah Perangkat dan pilih Server dan PC.',
        isCompleted: hasNodes,
        failureReason: hasNodes
            ? null
            : (isEn
                ? 'Currently ${servers.length} Server and ${pcs.length} PCs.'
                : 'Saat ini terdapat ${servers.length} Server dan ${pcs.length} PC.'),
      ),
      VirtualLabMissionTask(
        id: 'dhcp_t2_cables',
        title: isEn
            ? 'Connect Server and PC with Network Cable'
            : 'Hubungkan Server dan PC dengan Kabel Jaringan',
        description: isEn
            ? 'Connect a network cable directly or through a Switch between Server and PC.'
            : 'Tarik kabel jaringan langsung atau melalui Switch antara Server dan PC.',
        hint: isEn
            ? 'Connect cables so that physical network path is established.'
            : 'Hubungkan kabel dari port Server ke Switch/PC agar sinyal jaringan tersambung.',
        isCompleted: hasConnectedPath,
        failureReason: hasConnectedPath
            ? null
            : (isEn
                ? 'No physical cable path connecting Server and PC yet.'
                : 'Belum ada jalur kabel fisik yang menghubungkan Server dengan PC.'),
      ),
      VirtualLabMissionTask(
        id: 'dhcp_t3_service',
        title: isEn
            ? 'Enable DHCP or Web Server Service'
            : 'Aktifkan Layanan DHCP atau Web Server',
        description: isEn
            ? 'On the Server device, ensure DHCP Server or HTTP Server service switch is Active.'
            : 'Pada perangkat Server, pastikan switch layanan DHCP Server atau HTTP Server dalam posisi Aktif.',
        hint: isEn
            ? 'Select Server, open Server Services tab, enable DHCP Server, and set IP range.'
            : 'Pilih Server, buka tab Layanan Server, aktifkan DHCP Server dan atur rentang IP.',
        isCompleted: hasServiceActive,
        failureReason: serviceError,
      ),
      VirtualLabMissionTask(
        id: 'dhcp_t4_client',
        title: isEn
            ? 'Verify Dynamic IP (DHCP) or Access Web Service'
            : 'Verifikasi IP Dinamis (DHCP) atau Akses Layanan Web',
        description: isEn
            ? 'Set PC to DHCP mode to obtain dynamic IP or test Ping / curl to the Server.'
            : 'Gunakan opsi DHCP pada PC untuk meminta IP dinamis atau jalankan uji ping/curl ke Server.',
        hint: isEn
            ? 'On PC, change mode to DHCP or use terminal: ipconfig /renew or ping <server_ip>.'
            : 'Pada PC, ubah mode IP ke DHCP atau gunakan terminal: ipconfig /renew atau ping <ip_server>.',
        isCompleted: hasClientSuccess,
        failureReason: hasClientSuccess
            ? null
            : (isEn
                ? 'PC client has not received dynamic IP or connection to Server has not succeeded.'
                : 'PC client belum menerima IP dinamis atau pengujian koneksi ke Server belum berhasil.'),
      ),
    ];
  }

  // ===========================================================================
  // Modul Kustom / Umum (Dibuat oleh Dosen)
  // ===========================================================================
  static List<VirtualLabMissionTask> _evaluateCustomOrGeneral(
    VirtualLabSession session,
    VirtualLabConnectivityResult? lastTest,
    bool isEn,
  ) {
    final devCount = session.devices.length;
    final cableCount = session.cables.length;

    final hasMinDevices = devCount >= 2;
    final hasCables = cableCount >= 1;

    final configuredDevices = session.devices.where((d) {
      if (d.kind == VirtualLabDeviceKind.switch_) return true;
      final ip = VirtualLabIpv4.parse(d.ipAddress ?? '');
      return ip != null;
    }).length;
    final hasValidConfig = devCount >= 2 && configuredDevices >= 2;

    bool hasSuccessfulTest = false;
    if (lastTest != null && lastTest.success) {
      hasSuccessfulTest = true;
    } else if (session.devices.length >= 2) {
      final hosts = session.devices
          .where((d) => d.kind != VirtualLabDeviceKind.switch_)
          .toList();
      if (hosts.length >= 2) {
        final test = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: hosts[0].id,
          targetId: hosts[1].id,
        );
        if (test.success) {
          hasSuccessfulTest = true;
        }
      }
    }

    return [
      VirtualLabMissionTask(
        id: 'gen_t1_nodes',
        title: isEn
            ? 'Place at Least 2 Devices'
            : 'Tempatkan Minimal 2 Perangkat',
        description: isEn
            ? 'Design topology scenario with at least 2 devices on canvas.'
            : 'Rancang skenario topologi dengan menambahkan minimal 2 perangkat di kanvas.',
        hint: isEn
            ? 'Use the Add Device panel to add network nodes.'
            : 'Gunakan panel Tambah Perangkat untuk menambahkan node.',
        isCompleted: hasMinDevices,
        failureReason: hasMinDevices
            ? null
            : (isEn
                ? 'Currently $devCount devices on canvas (at least 2 required).'
                : 'Saat ini terdapat $devCount perangkat di kanvas (dibutuhkan minimal 2).'),
      ),
      VirtualLabMissionTask(
        id: 'gen_t2_cables',
        title: isEn
            ? 'Connect Devices with Network Cable'
            : 'Hubungkan Perangkat dengan Kabel Jaringan',
        description: isEn
            ? 'Ensure devices are connected with network cables.'
            : 'Pastikan perangkat saling terhubung dengan kabel jaringan.',
        hint: isEn
            ? 'Connect cables between devices you want to link.'
            : 'Tarik kabel antar perangkat yang ingin dihubungkan.',
        isCompleted: hasCables,
        failureReason: hasCables
            ? null
            : (isEn
                ? 'No network cables on canvas yet.'
                : 'Belum ada kabel jaringan di kanvas.'),
      ),
      VirtualLabMissionTask(
        id: 'gen_t3_config',
        title: isEn
            ? 'Configure Device IP Addresses'
            : 'Konfigurasikan Alamat IP Perangkat',
        description: isEn
            ? 'Ensure devices have valid IP configurations without conflicts.'
            : 'Pastikan perangkat memiliki konfigurasi alamat IP yang sesuai dan tanpa konflik.',
        hint: isEn
            ? 'Open device settings to configure IP and Netmask.'
            : 'Buka pengaturan perangkat untuk mengatur IP dan Netmask.',
        isCompleted: hasValidConfig,
        failureReason: hasValidConfig
            ? null
            : (isEn
                ? 'At least 2 devices must have valid IP configurations.'
                : 'Minimal 2 perangkat harus memiliki konfigurasi IP yang valid.'),
      ),
      VirtualLabMissionTask(
        id: 'gen_t4_test',
        title: isEn
            ? 'Perform Successful Connectivity Test'
            : 'Lakukan Uji Konektivitas Berhasil',
        description: isEn
            ? 'Run Ping test between devices and ensure response is received.'
            : 'Jalankan pengujian Ping antar perangkat dan pastikan respon berhasil diterima.',
        hint: isEn
            ? 'Use Connectivity Test menu or terminal command: ping.'
            : 'Gunakan menu Uji Koneksi atau terminal perintah ping.',
        isCompleted: hasSuccessfulTest,
        failureReason: hasSuccessfulTest
            ? null
            : (isEn
                ? 'No successful network connectivity test yet.'
                : 'Belum ada pengujian koneksi jaringan yang berhasil.'),
      ),
    ];
  }
}
