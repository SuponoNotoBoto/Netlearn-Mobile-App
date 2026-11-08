import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'virtual_lab_controller.dart';
import 'virtual_lab_model.dart';
import 'virtual_lab_network.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/nl_snack_bar.dart';

// Redesign v1.2 mengikuti desain Figma "Virtual Lab" (file JR7kY4bvGkLTTod6qNblsx,
// node 1-89). Palet diambil dari desain; dua penyimpangan sengaja dari desain:
// tidak ada ikon notifikasi di header, dan halaman tidak memakai strip bottom
// navigation (halaman pushed murni).

const Color _labPageBg = Color(0xFFF4F5FA);
const Color _labCardBorder = Color(0xFFECEEF2);
const Color _labInputBorder = Color(0xFFE3E4EC);
const Color _labText = Color(0xFF1A1D26);
const Color _labMuted = Color(0xFF8A8FA3);
const Color _labDot = Color(0xFFE1E4EC);
const Color _labStatusGray = Color(0xFFB4B7C3);
const Color _labStatusOrange = Color(0xFFF2994A);
const Color _labStatusGreen = Color(0xFF27AE60);
const Color _labWarnBg = Color(0xFFFFF2DF);
const Color _labWarnText = Color(0xFFB26A00);
const Color _labSuccessBg = Color(0xFFE8F8EE);
const Color _labSuccessText = Color(0xFF1E7A46);
const Color _labFailBg = Color(0xFFFDECEC);
const Color _labFailText = Color(0xFFD64545);
const Color _labPanelTrack = Color(0xFFF0F1F6);
const Color _labFieldFill = Color(0xFFF9FAFC);

class VirtualLabPage extends ConsumerStatefulWidget {
  const VirtualLabPage({super.key});

  @override
  ConsumerState<VirtualLabPage> createState() => _VirtualLabPageState();
}

class _VirtualLabPageState extends ConsumerState<VirtualLabPage>
    with SingleTickerProviderStateMixin {
  bool _justTappedDevice = false;
  VirtualLabConnectivityResult? _lastTest;
  late final AnimationController _packetController;
  int _packetLoopsRemaining = 0;
  void Function(AnimationStatus)? _packetStatusListener;

  /// 0 = Configuration, 1 = Ping Test.
  int _panelTab = 0;
  String? _pingSourceId;
  String? _pingTargetId;

  // Form konfigurasi perangkat aktif. Controller teks di-reset ketika pilihan
  // berpindah perangkat supaya isi kolom selalu milik perangkat yang tampil.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _maskController = TextEditingController();
  final TextEditingController _gatewayController = TextEditingController();
  final TextEditingController _ip2Controller = TextEditingController();
  final TextEditingController _mask2Controller = TextEditingController();
  String? _formDeviceId;

  @override
  void initState() {
    super.initState();
    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Load this student's saved canvas. The provider starts from the default
    // scenario, so the canvas is usable immediately and is replaced by the
    // stored one as soon as it arrives (or stays as-is when there is none).
    ref.read(virtualLabControllerProvider.notifier).restore();
  }

  @override
  void dispose() {
    _stopPacketAnimation();
    _packetController.dispose();
    _nameController.dispose();
    _ipController.dispose();
    _maskController.dispose();
    _gatewayController.dispose();
    _ip2Controller.dispose();
    _mask2Controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------------

  void _invalidateTest() {
    if (_lastTest != null) {
      setState(() => _lastTest = null);
    }
    _stopPacketAnimation();
  }

  void _handleToolSelect(VirtualLabController controller) {
    // Mode default: batalkan mode penempatan/pending kabel, tetapi pilihan
    // perangkat dibiarkan supaya panel konfigurasi tidak ikut kosong.
    controller.setPlacing(null);
    controller.cancelModes();
  }

  void _handleToolCable(
    VirtualLabSession session,
    VirtualLabController controller,
    AppLocalizations l10n,
  ) {
    if (session.pendingCableFrom != null) {
      controller.cancelModes();
      return;
    }
    final owner =
        session.selectedDeviceId ?? _cableOwnerForSelectedCable(session);
    if (owner == null) {
      _showSnack(l10n.virtualLabConnectNeedSelection);
      return;
    }
    controller.beginCableFrom(owner);
  }

  String? _cableOwnerForSelectedCable(VirtualLabSession session) {
    final cableId = session.selectedCableId;
    if (cableId == null) return null;
    for (final cable in session.cables) {
      if (cable.id == cableId) return cable.from;
    }
    return null;
  }

  void _handleDeviceTap(VirtualLabDevice device, AppLocalizations l10n) {
    _justTappedDevice = true;
    final controller = ref.read(virtualLabControllerProvider.notifier);
    final session = ref.read(virtualLabControllerProvider);
    final pending = session.pendingCableFrom;
    if (pending != null) {
      final issue = controller.completeCable(device.id);
      if (issue != null) {
        HapticFeedback.vibrate();
        SfxService.instance.playError();
        _showSnack(_localizeCableIssue(l10n, issue));
      } else if (pending != device.id) {
        HapticFeedback.mediumImpact();
        SfxService.instance.playConnect();
        // Kabel baru terbentuk → hasil ping lama tidak lagi relevan.
        _invalidateTest();
      }
      return;
    }
    controller.selectDevice(device.id);
  }

  void _handleCanvasTap(Offset pos, VirtualLabSession session) {
    if (_justTappedDevice) {
      _justTappedDevice = false;
      return;
    }
    final controller = ref.read(virtualLabControllerProvider.notifier);
    final cableId = _hitCable(session, pos);
    if (cableId != null) {
      controller.selectCable(cableId);
      return;
    }
    final placing = session.placingKind;
    if (placing != null) {
      controller.addDevice(placing, position: pos);
      _invalidateTest();
      return;
    }
    controller.clearSelection();
  }

  String? _hitCable(VirtualLabSession session, Offset pos) {
    const double hitThreshold = 12;
    for (final c in session.cables) {
      final from = session.deviceById(c.from);
      final to = session.deviceById(c.to);
      if (from == null || to == null) continue;
      if (_distanceToSegment(pos, from.position, to.position) <= hitThreshold) {
        return c.id;
      }
    }
    return null;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final d = b - a;
    if (d.dx == 0 && d.dy == 0) return (p - a).distance;
    final t = ((p - a).dx * d.dx + (p - a).dy * d.dy) / d.distanceSquared;
    final clamped = t.clamp(0.0, 1.0);
    final closest = Offset(
      a.dx + clamped * d.dx,
      a.dy + clamped * d.dy,
    );
    return (p - closest).distance;
  }

  void _applyConfiguration(
    VirtualLabSession session,
    VirtualLabController controller,
  ) {
    final id = session.selectedDeviceId;
    if (id == null) return;
    final device = session.deviceById(id);
    if (device == null) return;
    final name = _nameController.text.trim();
    final ip = _ipController.text.trim();
    final mask = _maskController.text.trim();
    final gw = _gatewayController.text.trim();
    final ip2 = _ip2Controller.text.trim();
    final mask2 = _mask2Controller.text.trim();

    controller.configureDevice(
      id,
      name: name.isEmpty ? null : name,
      ip: ip.isEmpty ? null : ip,
      mask: mask.isEmpty ? null : mask,
      gateway: gw.isEmpty ? null : gw,
      ip2: ip2.isEmpty ? null : ip2,
      mask2: mask2.isEmpty ? null : mask2,
    );
    // Konfigurasi berubah → hasil ping lama tidak lagi relevan.
    _invalidateTest();
    FocusScope.of(context).unfocus();
  }

  void _runPing(
    VirtualLabSession session,
    String sourceId,
    String targetId,
    AppLocalizations l10n,
  ) {
    if (sourceId == targetId) {
      _showSnack(l10n.virtualLabPingSameDevice);
      return;
    }
    final result = VirtualLabConnectivityEngine.ping(
      session,
      sourceId: sourceId,
      targetId: targetId,
    );
    setState(() {
      _lastTest = result;
      _pingSourceId = sourceId;
      _pingTargetId = targetId;
    });
    if (result.success) {
      HapticFeedback.heavyImpact();
      SfxService.instance.playSuccess();
      _startPacketAnimation();
    } else {
      HapticFeedback.vibrate();
      SfxService.instance.playError();
      _stopPacketAnimation();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _localizeCableIssue(AppLocalizations l10n, String code) {
    switch (code) {
      case VirtualLabSession.cableIssuePcPortFull:
        return l10n.virtualLabCableIssuePcPortFull;
      case VirtualLabSession.cableIssueRouterPortFull:
        return 'Router ini sudah memakai kedua port-nya (eth0 & eth1). Hapus kabel yang ada terlebih dahulu.';
      case VirtualLabSession.cableIssueDuplicate:
        return l10n.virtualLabCableIssueDuplicate;
      case VirtualLabSession.cableIssueSameDevice:
        return l10n.virtualLabCableIssueSameDevice;
      default:
        return l10n.virtualLabTestFailed;
    }
  }

  String _localizeReason(AppLocalizations l10n, String reason) {
    switch (reason) {
      case 'need_two_ip_devices':
        return l10n.virtualLabTestNeedDevices;
      case 'connected':
        return l10n.virtualLabTestSuccess;
      case 'routed_success':
        return 'Ping berhasil dirutekan melalui Router!';
      case 'invalid_ip':
        return l10n.virtualLabReasonInvalidIp;
      case 'invalid_mask':
        return l10n.virtualLabReasonInvalidMask;
      case 'host_address':
        return l10n.virtualLabReasonHostAddress;
      case 'duplicate':
        return l10n.virtualLabReasonDuplicate;
      case 'no_path':
        return l10n.virtualLabReasonNoPath;
      case 'different_subnet':
        return l10n.virtualLabReasonDifferentSubnet;
      case 'not_configured':
        return l10n.virtualLabReasonNotConfigured;
      case 'source_missing_gateway':
        return 'PC sumber belum memiliki Default Gateway untuk menjangkau subnet lain.';
      case 'target_missing_gateway':
        return 'PC tujuan belum memiliki Default Gateway untuk membalas ping.';
      case 'source_invalid_gateway':
        return 'Format IP Default Gateway PC sumber tidak valid.';
      case 'target_invalid_gateway':
        return 'Format IP Default Gateway PC tujuan tidak valid.';
      case 'gateway_subnet_mismatch':
        return 'Default Gateway PC sumber harus satu subnet dengan IP-nya.';
      case 'target_gateway_subnet_mismatch':
        return 'Default Gateway PC tujuan harus satu subnet dengan IP-nya.';
      case 'different_subnet_no_router':
        return 'Kedua PC beda subnet dan tidak ada Router di kanvas untuk menghubungkannya.';
      case 'gateway_unreachable':
        return 'Gateway tidak cocok dengan IP interface Router mana pun yang terhubung.';
      default:
        return reason;
    }
  }

  // ---------------------------------------------------------------------------
  // Animasi paket (MVP yang sudah disepakati: 3 loop, stop saat reset/perubahan)
  // ---------------------------------------------------------------------------

  void _startPacketAnimation() {
    _stopPacketAnimation();
    _packetLoopsRemaining = 3;
    _packetStatusListener = (status) {
      if (status == AnimationStatus.completed) {
        _packetLoopsRemaining--;
        if (_packetLoopsRemaining > 0) {
          _packetController
            ..reset()
            ..forward();
        } else {
          if (_packetStatusListener != null) {
            _packetController.removeStatusListener(_packetStatusListener!);
            _packetStatusListener = null;
          }
          _packetController.stop();
          _packetLoopsRemaining = 0;
        }
      }
    };
    _packetController.addStatusListener(_packetStatusListener!);
    _packetController
      ..reset()
      ..forward();
  }

  void _stopPacketAnimation() {
    if (_packetStatusListener != null) {
      _packetController.removeStatusListener(_packetStatusListener!);
      _packetStatusListener = null;
    }
    _packetController.stop();
    _packetLoopsRemaining = 0;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(virtualLabControllerProvider);
    final session = ref.read(virtualLabControllerProvider);
    final controller = ref.read(virtualLabControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final accent = context.accent;

    _syncConfigForm(session);

    return Scaffold(
      backgroundColor: _labPageBg,
      appBar: AppBar(
        backgroundColor: _labPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          // No explicit fallback: the same page is mounted under /student and
          // /lecturer, and goBack() already reads the current location to pick
          // the right dashboard. Pinning it to '/student' sent a lecturer who
          // deep-linked here through the auth guard's bounce back to /lecturer.
          onPressed: () => goBack(context),
        ),
        title: Text(
          l10n.virtualLab,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _labText,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tanya NetBot',
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
            onPressed: () => _askNetBotAboutTopology(session),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildToolbar(l10n, accent, session, controller),
            const SizedBox(height: 10),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCanvas(session, controller, accent, l10n),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: Text(
                l10n.virtualLabCanvasHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: _labMuted),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border(top: BorderSide(color: _labCardBorder)),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPanelTabs(l10n, accent),
                      const SizedBox(height: 14),
                      if (_panelTab == 0)
                        _buildConfigurationTab(session, controller, l10n, accent)
                      else
                        _buildPingTab(session, l10n, accent),
                      const SizedBox(height: 18),
                      _buildFooter(l10n, accent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncConfigForm(VirtualLabSession session) {
    final id = session.selectedDeviceId;
    final device = id == null ? null : session.deviceById(id);
    if (device == null) {
      _formDeviceId = null;
      return;
    }
    if (device.id == _formDeviceId) return;
    _formDeviceId = device.id;
    _nameController.text = device.displayName;
    _ipController.text = device.ipAddress ?? '';
    _maskController.text = device.subnetMask ?? '';
    _gatewayController.text = device.defaultGateway ?? '';
    _ip2Controller.text = device.ipAddress2 ?? '';
    _mask2Controller.text = device.subnetMask2 ?? '';
  }

  // ---------------------------------------------------------------------------
  // Toolbar mode-tool + legenda
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(
    AppLocalizations l10n,
    Color accent,
    VirtualLabSession session,
    VirtualLabController controller,
  ) {
    final selectActive =
        session.placingKind == null && session.pendingCableFrom == null;
    final cableActive = session.pendingCableFrom != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _labCardBorder),
              boxShadow: [
                BoxShadow(
                  color: _labText.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildToolButton(
                  label: l10n.virtualLabToolSelect,
                  icon: Icons.near_me_rounded,
                  active: selectActive,
                  accent: accent,
                  onTap: () => _handleToolSelect(controller),
                ),
                _buildToolButton(
                  label: l10n.virtualLabToolCable,
                  icon: Icons.cable_rounded,
                  active: cableActive,
                  accent: accent,
                  onTap: () => _handleToolCable(session, controller, l10n),
                ),
                _buildToolButton(
                  label: l10n.virtualLabToolPc,
                  icon: Icons.desktop_windows_rounded,
                  active: false,
                  accent: accent,
                  plus: true,
                  onTap: () {
                    controller.addDevice(VirtualLabDeviceKind.pc);
                    _invalidateTest();
                  },
                ),
                _buildToolButton(
                  label: l10n.virtualLabToolSwitch,
                  icon: Icons.hub_rounded,
                  active: false,
                  accent: accent,
                  plus: true,
                  onTap: () {
                    controller.addDevice(VirtualLabDeviceKind.switch_);
                    _invalidateTest();
                  },
                ),
                _buildToolButton(
                  label: '+Router',
                  icon: Icons.router_rounded,
                  active: false,
                  accent: accent,
                  plus: true,
                  onTap: () {
                    controller.addDevice(VirtualLabDeviceKind.router);
                    _invalidateTest();
                  },
                ),
                _buildToolButton(
                  label: l10n.virtualLabToolDelete,
                  icon: Icons.delete_outline_rounded,
                  active: false,
                  accent: accent,
                  onTap: () {
                    controller.removeSelected();
                    _invalidateTest();
                  },
                ),
                _buildToolButton(
                  label: l10n.virtualLabToolReset,
                  icon: Icons.restart_alt_rounded,
                  active: false,
                  accent: accent,
                  onTap: () {
                    controller.reset();
                    _invalidateTest();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Wrap, bukan Row: pada text scale besar label legenda bisa melebihi
          // satu baris lebar layar 360dp.
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildLegendItem(_labStatusGreen, l10n.virtualLabLegendConnected),
              _buildLegendItem(
                  _labStatusOrange, l10n.virtualLabLegendNeedsConfig),
              _buildLegendItem(_labStatusGray, l10n.virtualLabLegendNotCabled),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required String label,
    required IconData icon,
    required bool active,
    required Color accent,
    required VoidCallback onTap,
    bool plus = false,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: active
              ? BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: active ? accent : _labMuted,
                  ),
                  if (plus)
                    Positioned(
                      right: -7,
                      top: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: active ? accent : _labMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: _labMuted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Kanvas
  // ---------------------------------------------------------------------------

  Widget _buildCanvas(
    VirtualLabSession session,
    VirtualLabController controller,
    Color accent,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _labCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) =>
                  _handleCanvasTap(details.localPosition, session),
              child: AnimatedBuilder(
                animation: _packetController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _VirtualLabPainter(
                      session,
                      _lastTest,
                      _packetController.value,
                      accent,
                    ),
                  );
                },
              ),
            ),
          ),
          ...session.devices.map(
            (device) => _buildDeviceNode(device, session, controller, accent, l10n),
          ),
          if (session.devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.virtualLabEmptyHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _labMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceNode(
    VirtualLabDevice device,
    VirtualLabSession session,
    VirtualLabController controller,
    Color accent,
    AppLocalizations l10n,
  ) {
    final selected = device.id == session.selectedDeviceId;
    final pending = device.id == session.pendingCableFrom;
    final status = VirtualLabConnectivityEngine.deviceStatus(session, device);
    final statusColor = switch (status) {
      VirtualLabDeviceStatus.connected => _labStatusGreen,
      VirtualLabDeviceStatus.needsConfig => _labStatusOrange,
      VirtualLabDeviceStatus.notCabled => _labStatusGray,
    };
    final ip = device.ipAddress?.trim() ?? '';
    final String labelIp;
    if (device.kind == VirtualLabDeviceKind.router) {
      final ip1 = device.ipAddress?.trim() ?? '';
      final ip2 = device.ipAddress2?.trim() ?? '';
      if (ip1.isNotEmpty && ip2.isNotEmpty) {
        labelIp = '$ip1\n$ip2';
      } else if (ip1.isNotEmpty) {
        labelIp = ip1;
      } else if (ip2.isNotEmpty) {
        labelIp = ip2;
      } else {
        labelIp = l10n.virtualLabNoIp;
      }
    } else {
      labelIp = ip.isNotEmpty ? ip : l10n.virtualLabNoIp;
    }
    return Positioned(
      left: device.position.dx - 48,
      top: device.position.dy - 30,
      width: 96,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleDeviceTap(device, l10n),
        onPanUpdate: (details) =>
            controller.moveDevice(device.id, details.delta),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              foregroundPainter: (selected || pending)
                  ? _DashedRoundedBorderPainter(
                      color: pending ? _labStatusOrange : accent,
                    )
                  : null,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: (selected || pending)
                      ? null
                      : Border.all(color: _labCardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _labText.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _deviceIcon(device.kind),
                        size: 24,
                        color: selected ? accent : const Color(0xFF5B6070),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              device.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _labText,
              ),
            ),
            Text(
              labelIp,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, height: 1.15, color: _labMuted),
            ),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(VirtualLabDeviceKind kind) {
    switch (kind) {
      case VirtualLabDeviceKind.pc:
        return Icons.desktop_windows_rounded;
      case VirtualLabDeviceKind.switch_:
        return Icons.hub_rounded;
      case VirtualLabDeviceKind.router:
        return Icons.router_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // Panel bawah: tab Configuration / Ping Test
  // ---------------------------------------------------------------------------

  Widget _buildPanelTabs(AppLocalizations l10n, Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _labPanelTrack,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildPanelTabButton(
            0,
            Icons.tune_rounded,
            l10n.virtualLabPanelConfiguration,
            accent,
          ),
          _buildPanelTabButton(
            1,
            Icons.wifi_tethering_rounded,
            l10n.virtualLabPanelPingTest,
            accent,
          ),
        ],
      ),
    );
  }

  Widget _buildPanelTabButton(
    int index,
    IconData icon,
    String label,
    Color accent,
  ) {
    final active = _panelTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() => _panelTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _labText.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? accent : _labMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? _labText : _labMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationTab(
    VirtualLabSession session,
    VirtualLabController controller,
    AppLocalizations l10n,
    Color accent,
  ) {
    final id = session.selectedDeviceId;
    final device = id == null ? null : session.deviceById(id);
    if (device == null) {
      return _buildPanelHint(l10n.virtualLabNoDeviceSelected);
    }
    final cabled = session.cables.any((c) => c.involves(device.id));
    final invalid = _isInvalidConfig(device);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_deviceIcon(device.kind), size: 20, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _labText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.kind == VirtualLabDeviceKind.pc
                        ? l10n.virtualLabDevicePcPorts
                        : (device.kind == VirtualLabDeviceKind.router
                            ? 'Router · 2 port (eth0 & eth1)'
                            : l10n.virtualLabDeviceSwitchPorts),
                    style: const TextStyle(fontSize: 11, color: _labMuted),
                  ),
                ],
              ),
            ),
            if (invalid) _buildStatusChip(l10n.virtualLabStatusInvalid),
          ],
        ),
        const SizedBox(height: 14),
        _buildFieldLabel(l10n.virtualLabDeviceNameLabel),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(hint: device.displayName),
        ),
        const SizedBox(height: 10),
        if (device.kind == VirtualLabDeviceKind.pc) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFieldLabel(l10n.virtualLabIpLabel),
                    TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(hint: '192.168.1.10'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFieldLabel(l10n.virtualLabMaskLabel),
                    TextField(
                      controller: _maskController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(hint: '255.255.255.0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFieldLabel('Default Gateway (IP Router)'),
          TextField(
            controller: _gatewayController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(hint: '192.168.1.1 (opsional jika 1 subnet)'),
          ),
        ] else if (device.kind == VirtualLabDeviceKind.router) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _labPageBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _labInputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interface 1 (eth0) · Subnet A',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _labText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel('IP Address'),
                          TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(hint: '192.168.1.1'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel('Subnet Mask'),
                          TextField(
                            controller: _maskController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(hint: '255.255.255.0'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _labPageBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _labInputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interface 2 (eth1) · Subnet B',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _labText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel('IP Address'),
                          TextField(
                            controller: _ip2Controller,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(hint: '192.168.2.1'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel('Subnet Mask'),
                          TextField(
                            controller: _mask2Controller,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: _fieldDecoration(hint: '255.255.255.0'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _labPageBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _labInputBorder),
            ),
            child: const Text(
              'Switch beroperasi pada Layer 2 (Data Link) dan meneruskan frame berdasarkan MAC address. Tidak memerlukan konfigurasi alamat IP.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: _labMuted),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.cable_rounded, size: 14, color: _labMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                device.kind == VirtualLabDeviceKind.router
                    ? '${session.cables.where((c) => c.involves(device.id)).length}/2 port kabel terhubung'
                    : (cabled
                        ? l10n.virtualLabCableConnected
                        : l10n.virtualLabCableNotConnected),
                style: const TextStyle(fontSize: 11.5, color: _labMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () => _applyConfiguration(session, controller),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l10n.virtualLabApply,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPingTab(
    VirtualLabSession session,
    AppLocalizations l10n,
    Color accent,
  ) {
    final devices = session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.pc)
        .toList();
    if (devices.length < 2) {
      return _buildPanelHint(
        Localizations.localeOf(context).languageCode == 'id'
            ? 'Tambahkan minimal dua PC untuk melakukan uji ping.'
            : 'Add at least two PCs to test ping connectivity.',
      );
    }
    final ids = devices.map((d) => d.id).toSet();
    final sourceId = (_pingSourceId != null && ids.contains(_pingSourceId))
        ? _pingSourceId!
        : devices.first.id;
    final targetId = (_pingTargetId != null &&
            ids.contains(_pingTargetId) &&
            _pingTargetId != sourceId)
        ? _pingTargetId!
        : devices.firstWhere((d) => d.id != sourceId).id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDeviceDropdown(
                label: l10n.virtualLabPingSource,
                value: sourceId,
                devices: devices,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _pingSourceId = value;
                    _lastTest = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDeviceDropdown(
                label: l10n.virtualLabPingTarget,
                value: targetId,
                devices: devices,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _pingTargetId = value;
                    _lastTest = null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _runPing(session, sourceId, targetId, l10n),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(
            l10n.virtualLabPingRun,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_lastTest != null) ...[
          const SizedBox(height: 12),
          _buildPingResultCard(session, _lastTest!, l10n),
        ],
      ],
    );
  }

  Widget _buildPingResultCard(
    VirtualLabSession session,
    VirtualLabConnectivityResult result,
    AppLocalizations l10n,
  ) {
    final success = result.success;
    final pathNames = result.details
        .map((id) => session.deviceById(id)?.displayName)
        .whereType<String>()
        .toList();
    final detailText = success
        ? (pathNames.isNotEmpty ? 'Jalur paket: ${pathNames.join(' → ')}' : '')
        : _localizeReason(l10n, result.reason);
    final title = success
        ? (result.reason == 'routed_success'
            ? 'Ping Berhasil (Dirutekan via Router)'
            : l10n.virtualLabPingSuccess)
        : l10n.virtualLabPingFailed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? _labSuccessBg : _labFailBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: success
              ? _labStatusGreen.withValues(alpha: 0.25)
              : _labFailText.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 18,
            color: success ? _labStatusGreen : _labFailText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: success ? _labSuccessText : _labFailText,
                  ),
                ),
                if (detailText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detailText,
                    style: const TextStyle(fontSize: 11.5, color: _labMuted),
                  ),
                ],
                if (!success) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _diagnoseWithNetBot(session, result),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Bantu Analisis Masalah dengan NetBot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _askNetBotAboutTopology(VirtualLabSession session) {
    HapticFeedback.lightImpact();
    NlSnackBar.show(
      context,
      'Fitur NetBot AI masih dalam tahap pengembangan.',
    );
  }

  void _diagnoseWithNetBot(
    VirtualLabSession session,
    VirtualLabConnectivityResult result,
  ) {
    HapticFeedback.mediumImpact();
    NlSnackBar.show(
      context,
      'Fitur NetBot AI masih dalam tahap pengembangan.',
    );
  }

  Widget _buildDeviceDropdown({
    required String label,
    required String value,
    required List<VirtualLabDevice> devices,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel(label),
        DropdownButtonFormField<String>(
          // initialValue hanya berlaku saat field dibuat, jadi key mengikuti
          // nilai efektif — reset/skenario yang mengganti perangkat akan
          // membangun ulang field dengan pilihan yang benar.
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          items: [
            for (final device in devices)
              DropdownMenuItem(
                value: device.id,
                child: Text(
                  _deviceDropdownLabel(device),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
          onChanged: onChanged,
          decoration: _fieldDecoration(hint: ''),
        ),
      ],
    );
  }

  String _deviceDropdownLabel(VirtualLabDevice device) {
    final ip = device.ipAddress?.trim() ?? '';
    if (ip.isEmpty) return device.displayName;
    return '${device.displayName} · $ip';
  }

  Widget _buildPanelHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, height: 1.4, color: _labMuted),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _labMuted,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      isDense: true,
      hintText: hint.isEmpty ? null : hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: _labStatusGray),
      filled: true,
      fillColor: _labFieldFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _labInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.accent, width: 1.4),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _labWarnBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _labWarnText,
        ),
      ),
    );
  }

  bool _isInvalidConfig(VirtualLabDevice device) {
    if (device.kind == VirtualLabDeviceKind.switch_) return false;
    if (device.kind == VirtualLabDeviceKind.router) {
      final ip1 = (device.ipAddress ?? '').trim();
      final mask1 = (device.subnetMask ?? '').trim();
      if (ip1.isNotEmpty || mask1.isNotEmpty) {
        if (VirtualLabIpv4.parse(ip1) == null) return true;
        if (VirtualLabSubnetMask.parse(mask1) == null) return true;
        if (!VirtualLabEngine.isHostAddress(ip1, mask1)) return true;
      }
      final ip2 = (device.ipAddress2 ?? '').trim();
      final mask2 = (device.subnetMask2 ?? '').trim();
      if (ip2.isNotEmpty || mask2.isNotEmpty) {
        if (VirtualLabIpv4.parse(ip2) == null) return true;
        if (VirtualLabSubnetMask.parse(mask2) == null) return true;
        if (!VirtualLabEngine.isHostAddress(ip2, mask2)) return true;
      }
      return false;
    }
    // PC
    final ip = (device.ipAddress ?? '').trim();
    final mask = (device.subnetMask ?? '').trim();
    if (ip.isEmpty && mask.isEmpty) return false;
    if (VirtualLabIpv4.parse(ip) == null) return true;
    if (VirtualLabSubnetMask.parse(mask) == null) return true;
    return !VirtualLabEngine.isHostAddress(ip, mask);
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter(AppLocalizations l10n, Color accent) {
    return Column(
      children: [
        Text(
          l10n.virtualLabFooterNote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1.4,
            color: _labMuted,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => goBack(context, fallback: '/student'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              backgroundColor: accent.withValues(alpha: 0.08),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.virtualLabBackToDashboard,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Painter kanvas
// -----------------------------------------------------------------------------

class _VirtualLabPainter extends CustomPainter {
  const _VirtualLabPainter(
    this.session,
    this.lastTest,
    this.packetProgress,
    this.accent,
  );

  final VirtualLabSession session;
  final VirtualLabConnectivityResult? lastTest;
  final double packetProgress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Dot grid halus (desain memakai titik, bukan garis).
    final dotPaint = Paint()..color = _labDot;
    const spacing = 24.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    // Kabel + lingkaran kecil di ujungnya (node port pada desain).
    for (final cable in session.cables) {
      final a = session.deviceById(cable.from);
      final b = session.deviceById(cable.to);
      if (a == null || b == null) continue;
      final selected = cable.id == session.selectedCableId;
      final solved = lastTest?.success == true;
      final color = solved
          ? _labStatusGreen
          : (selected ? accent : accent.withValues(alpha: 0.45));
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = selected ? 3.2 : 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a.position, b.position, linePaint);
      final portFill = Paint()..color = Colors.white;
      final portStroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (final point in [
        _portPoint(a.position, b.position),
        _portPoint(b.position, a.position),
      ]) {
        canvas.drawCircle(point, 4, portFill);
        canvas.drawCircle(point, 4, portStroke);
      }
    }

    // Paket animasi: ikuti jalur hasil ping (details = urutan id perangkat);
    // kalau tidak ada, jatuh ke urutan kabel seperti implementasi sebelumnya.
    if (lastTest?.success == true) {
      final points = _packetPath();
      if (points.length >= 2) {
        final segments = points.length - 1;
        final segmentSpan = 1.0 / segments;
        final packetPaint = Paint()..color = Colors.amber.shade700;
        final outlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var i = 0; i < segments; i++) {
          final start = points[i];
          final end = points[i + 1];
          final localStart = i * segmentSpan;
          if (packetProgress < localStart) continue;
          final local =
              ((packetProgress - localStart) / segmentSpan).clamp(0.0, 1.0);
          final pos = Offset(
            start.dx + (end.dx - start.dx) * local,
            start.dy + (end.dy - start.dy) * local,
          );
          canvas.drawCircle(pos, 4.5, packetPaint);
          canvas.drawCircle(pos, 4.5, outlinePaint);
        }
      }
    }
  }

  /// Titik 30px dari pusat perangkat menuju perangkat lain — supaya
  /// lingkaran port tidak tertutup kartu perangkat.
  static Offset _portPoint(Offset from, Offset toward) {
    final delta = toward - from;
    if (delta.distance == 0) return from;
    return from + delta / delta.distance * 30;
  }

  List<Offset> _packetPath() {
    final details = lastTest?.details ?? const <String>[];
    if (details.length >= 2) {
      final points = <Offset>[];
      for (final id in details) {
        final device = session.deviceById(id);
        if (device != null) points.add(device.position);
      }
      if (points.length >= 2) return points;
    }
    final points = <Offset>[];
    for (final cable in session.cables) {
      final a = session.deviceById(cable.from);
      final b = session.deviceById(cable.to);
      if (a == null || b == null) continue;
      if (points.isEmpty) points.add(a.position);
      points.add(b.position);
    }
    return points;
  }

  @override
  bool shouldRepaint(covariant _VirtualLabPainter oldDelegate) {
    // packetProgress harus ikut dibandingkan agar tiap frame animasi paket
    // benar-benar direpaint, bukan hanya saat session/lastTest berubah.
    return oldDelegate.session != session ||
        oldDelegate.lastTest != lastTest ||
        oldDelegate.packetProgress != packetProgress ||
        oldDelegate.accent != accent;
  }
}

/// Border dashed membulat untuk perangkat terpilih — dasbor desain memakai
/// garis putus-putus, dan `Border` bawaan Flutter tidak bisa dashed.
class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});

  final Color color;
  static const double _radius = 16;
  static const double _strokeWidth = 2;
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(_radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
