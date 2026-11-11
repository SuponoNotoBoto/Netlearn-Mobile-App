import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/localization/language_controller.dart';
import '../../core/router/safe_back.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'virtual_lab_controller.dart';
import 'virtual_lab_model.dart';
import 'virtual_lab_network.dart';
import 'virtual_lab_terminal.dart';
import 'virtual_lab_export.dart';
import 'virtual_lab_saved_topology.dart';
import 'virtual_lab_storage_service.dart';
import 'virtual_lab_mission_service.dart';
import 'widgets/virtual_lab_mission_sheet.dart';
import 'widgets/virtual_lab_leaderboard_sheet.dart';
import '../classes/class_controller.dart';
import '../achievements/achievement_service.dart';
import '../materials/material_lab_binding.dart';
import '../netbot/netbot_chat_sheet.dart';
import '../netbot/netbot_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/nl_skeleton.dart';
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
  final MaterialLabBinding? labBinding;

  const VirtualLabPage({
    super.key,
    this.labBinding,
  });

  @override
  ConsumerState<VirtualLabPage> createState() => _VirtualLabPageState();
}

class _VirtualLabPageState extends ConsumerState<VirtualLabPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  bool _justTappedDevice = false;
  VirtualLabConnectivityResult? _lastTest;
  late final AnimationController _packetController;
  int _packetLoopsRemaining = 0;
  void Function(AnimationStatus)? _packetStatusListener;

  /// Status banner panduan praktikum modul
  bool _showLabGuideBanner = true;
  bool _labGuideCollapsed = false;
  bool _hasCheckedInitialLabLoad = false;

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
  final TextEditingController _dhcpStartIpController = TextEditingController();
  final TextEditingController _dhcpMaskController = TextEditingController();
  final TextEditingController _dhcpGatewayController = TextEditingController();
  final TextEditingController _dhcpDnsController = TextEditingController();
  final TextEditingController _httpTitleController = TextEditingController();
  final TextEditingController _httpContentController = TextEditingController();
  VirtualLabIpMode _pcIpMode = VirtualLabIpMode.static_;
  bool _dhcpServerEnabled = true;
  bool _httpServerEnabled = true;
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

    if (widget.labBinding != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndApplyLabBinding();
      });
    }
  }

  void _checkAndApplyLabBinding() {
    if (!mounted || widget.labBinding == null || _hasCheckedInitialLabLoad) return;
    _hasCheckedInitialLabLoad = true;

    final isEn = ref.read(languageProvider).languageCode == 'en';
    final locBinding = widget.labBinding!.localized(isEn ? 'en' : 'id');

    final session = ref.read(virtualLabControllerProvider);
    // Jika materi memiliki preset eksplisit bukan blank dan kanvas kosong, baru muat
    if (widget.labBinding!.preset != 'blank' && session.devices.isEmpty) {
      ref.read(virtualLabControllerProvider.notifier).loadPreset(
            widget.labBinding!.resolveInitialSession(),
          );
      NlSnackBar.show(
        context,
        isEn
            ? 'Practical scenario "${locBinding.title}" prepared successfully.'
            : 'Skenario praktikum "${locBinding.title}" berhasil disiapkan.',
        tone: NlSnackTone.success,
      );
    }
  }

  void _promptResetForPractice(
    VirtualLabController controller,
    VirtualLabSession session,
  ) {
    final isEn = ref.read(languageProvider).languageCode == 'en';

    if (session.devices.isEmpty) {
      NlSnackBar.show(
        context,
        isEn
            ? 'Canvas is already clean and ready.'
            : 'Kanvas sudah bersih dan siap untuk dirancang.',
        tone: NlSnackTone.info,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEn ? 'Start Clean Canvas?' : 'Mulai Kanvas Bersih?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          isEn
              ? 'Clear current canvas (${session.devices.length} devices) to design this practical from scratch?'
              : 'Kosongkan kanvas saat ini (${session.devices.length} perangkat) untuk memulai rancangan praktikum ini dari nol?',
          style: const TextStyle(fontSize: 13, color: _labText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isEn ? 'Cancel' : 'Batal', style: const TextStyle(color: _labMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              controller.loadPreset(VirtualLabController.presetBlank());
              _invalidateTest();
              NlSnackBar.show(
                context,
                isEn
                    ? 'Canvas cleared. Start designing according to the guide.'
                    : 'Kanvas berhasil dikosongkan. Silakan mulai merancang sesuai panduan.',
                tone: NlSnackTone.success,
              );
            },
            child: Text(isEn ? 'Clear' : 'Kosongkan'),
          ),
        ],
      ),
    );
  }

  void _promptLoadReferenceExample(
    VirtualLabController controller,
    VirtualLabSession session,
  ) {
    final refSession = widget.labBinding?.resolveReferenceSession();
    if (refSession == null) return;
    final isEn = ref.read(languageProvider).languageCode == 'en';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEn ? 'View Example Solution?' : 'Lihat Contoh Solusi?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isEn
              ? 'WARNING: Loading the reference example will replace your canvas with a completed diagram. We recommend trying to build it yourself first. Continue?'
              : 'PERINGATAN: Memuat contoh referensi akan menggantikan kanvas Anda dengan diagram yang sudah jadi. Sebaiknya Anda mencoba merancang sendiri terlebih dahulu. Lanjutkan?',
          style: const TextStyle(fontSize: 13, color: _labText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              isEn ? 'Work on My Own' : 'Tetap Kerjakan Sendiri',
              style: const TextStyle(color: _labMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              controller.loadPreset(refSession);
              _invalidateTest();
              NlSnackBar.show(
                context,
                isEn
                    ? 'Reference topology example loaded onto canvas.'
                    : 'Contoh topologi referensi dimuat ke kanvas.',
                tone: NlSnackTone.success,
              );
            },
            child: Text(isEn ? 'Load Example' : 'Muat Contoh'),
          ),
        ],
      ),
    );
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
    _dhcpStartIpController.dispose();
    _dhcpMaskController.dispose();
    _dhcpGatewayController.dispose();
    _dhcpDnsController.dispose();
    _httpTitleController.dispose();
    _httpContentController.dispose();
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
    final dhcpGw = _dhcpGatewayController.text.trim();
    final effectiveDhcpGw =
        dhcpGw.isNotEmpty ? dhcpGw : (gw.isNotEmpty ? gw : null);

    controller.configureDevice(
      id,
      name: name.isEmpty ? null : name,
      ip: ip.isEmpty ? null : ip,
      mask: mask.isEmpty ? null : mask,
      gateway: gw.isEmpty ? null : gw,
      ip2: ip2.isEmpty ? null : ip2,
      mask2: mask2.isEmpty ? null : mask2,
      ipMode: _pcIpMode,
      dhcpServerEnabled: _dhcpServerEnabled,
      dhcpStartIp: _dhcpStartIpController.text.trim().isEmpty
          ? null
          : _dhcpStartIpController.text.trim(),
      dhcpSubnetMask: _dhcpMaskController.text.trim().isEmpty
          ? null
          : _dhcpMaskController.text.trim(),
      dhcpGateway: effectiveDhcpGw,
      dhcpDns: _dhcpDnsController.text.trim().isEmpty
          ? null
          : _dhcpDnsController.text.trim(),
      httpServerEnabled: _httpServerEnabled,
      httpWebTitle: _httpTitleController.text.trim().isEmpty
          ? null
          : _httpTitleController.text.trim(),
      httpWebContent: _httpContentController.text.trim().isEmpty
          ? null
          : _httpContentController.text.trim(),
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
      AchievementService.unlockBadge(context, 'packet_slinger');
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
      case VirtualLabSession.cableIssueServerPortFull:
        return 'Server ini hanya memiliki 1 port Ethernet dan sudah terhubung kabel. Hapus kabel lama terlebih dahulu.';
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
    final isEn = ref.watch(languageProvider).languageCode == 'en';

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
            tooltip: 'Kelola Topologi (Simpan & Buka)',
            icon: const Icon(Icons.folder_open_rounded, color: _labText),
            onPressed: () =>
                _showSavedTopologiesSheet(context, controller, session),
          ),
          IconButton(
            tooltip: 'Template Topologi',
            icon: const Icon(Icons.account_tree_outlined, color: _labText),
            onPressed: () => _showTopologyTemplatesSheet(context, controller),
          ),
          IconButton(
            tooltip: 'Simpan / Ekspor Gambar',
            icon: const Icon(Icons.photo_camera_outlined, color: _labText),
            onPressed: () => _exportCanvasToImage(session),
          ),
          IconButton(
            tooltip: 'Tanya NetBot',
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
            onPressed: () => _askNetBotAboutTopology(session),
          ),
          IconButton(
            tooltip: isEn ? 'Virtual Lab Leaderboard' : 'Leaderboard Praktikum',
            icon: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFD97706),
            ),
            onPressed: () {
              final classId = ref.read(activeStudentClassProvider).value?.id;
              VirtualLabLeaderboardSheet.show(
                context,
                classId: classId,
                initialMissionId: widget.labBinding?.referencePreset ?? widget.labBinding?.preset,
              );
            },
          ),
          if (widget.labBinding != null) ...[
            IconButton(
              tooltip: isEn ? 'Mission & Evaluation' : 'Target Misi & Evaluasi',
              icon: const Icon(
                Icons.fact_check_rounded,
                color: Color(0xFF10B981),
              ),
              onPressed: () {
                VirtualLabMissionSheet.show(
                  context: context,
                  binding: widget.labBinding!,
                  session: session,
                  lastTest: _lastTest,
                );
              },
            ),
            IconButton(
              tooltip: 'Panduan Praktikum Modul',
              icon: Icon(
                _showLabGuideBanner
                    ? Icons.assignment_rounded
                    : Icons.assignment_outlined,
                color: const Color(0xFF6366F1),
              ),
              onPressed: () {
                setState(() {
                  _showLabGuideBanner = true;
                  _labGuideCollapsed = false;
                });
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildToolbar(l10n, accent, session, controller),
            if (widget.labBinding != null && _showLabGuideBanner)
              _buildLabGuideBanner(session, controller, accent),
            const SizedBox(height: 6),
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
                      else if (_panelTab == 1)
                        _buildPingTab(session, l10n, accent)
                      else
                        _buildTerminalTab(session, l10n, accent),
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
    _pcIpMode = device.ipMode;
    _dhcpServerEnabled = device.dhcpServerEnabled;
    _dhcpStartIpController.text = device.dhcpStartIp ?? '192.168.1.100';
    _dhcpMaskController.text =
        device.dhcpSubnetMask ?? device.subnetMask ?? '255.255.255.0';
    _dhcpGatewayController.text =
        device.dhcpGateway ?? device.defaultGateway ?? '';
    _dhcpDnsController.text = device.dhcpDns ?? '8.8.8.8';
    _httpServerEnabled = device.httpServerEnabled;
    _httpTitleController.text = device.httpWebTitle ?? 'NetLearn Server Portal';
    _httpContentController.text = device.httpWebContent ??
        'Selamat datang di Server Kampus NetLearn! Layanan HTTP Web Server aktif dan berjalan normal.';
  }

  Widget _buildLabGuideBanner(
    VirtualLabSession session,
    VirtualLabController controller,
    Color accent,
  ) {
    final binding = widget.labBinding;
    if (binding == null) return const SizedBox.shrink();

    final isEn = ref.watch(languageProvider).languageCode == 'en';
    final locBinding = binding.localized(isEn ? 'en' : 'id');

    // Cek apakah praktikum modul ini sudah dikumpulkan
    final submissionsMap = ref.watch(labSubmissionsProvider).value;
    final key1 = binding.materialId;
    final key2 = binding.referencePreset ?? binding.preset;
    final existingSubmission = submissionsMap?[key1] ?? submissionsMap?[key2];
    final hasSubmitted = existingSubmission != null;

    if (_labGuideCollapsed) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: InkWell(
          onTap: () => setState(() => _labGuideCollapsed = false),
          child: Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 16, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEn
                      ? 'Lab Guide: ${locBinding.title}'
                      : 'Panduan Praktikum: ${locBinding.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF312E81),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => VirtualLabMissionSheet.show(
                  context: context,
                  binding: binding,
                  session: session,
                  lastTest: _lastTest,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasSubmitted
                        ? const Color(0xFF059669)
                        : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasSubmitted
                            ? Icons.emoji_events_rounded
                            : Icons.flag_circle_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        hasSubmitted
                            ? (isEn
                                ? 'Score: ${existingSubmission.score}'
                                : 'Nilai: ${existingSubmission.score}')
                            : (isEn ? 'Mission' : 'Misi'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Show Guide' : 'Lihat Panduan',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: Color(0xFF4F46E5)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_rounded,
                    size: 16, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    locBinding.title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1B4B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSubmitted) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      isEn
                          ? 'Score: ${existingSubmission.score}/100'
                          : 'Nilai: ${existingSubmission.score}/100',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                  color: const Color(0xFF64748B),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: isEn ? 'Collapse Guide' : 'Kecilkan Panduan',
                  onPressed: () => setState(() => _labGuideCollapsed = true),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: const Color(0xFF94A3B8),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: isEn ? 'Close Guide' : 'Tutup Panduan',
                  onPressed: () => setState(() => _showLabGuideBanner = false),
                ),
              ],
            ),
          ),

          // Body Instruksi
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Action Buttons (Wrap prevents horizontal overflow)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InkWell(
                      onTap: () => VirtualLabMissionSheet.show(
                        context: context,
                        binding: binding,
                        session: session,
                        lastTest: _lastTest,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasSubmitted
                              ? const Color(0xFF059669)
                              : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasSubmitted
                                  ? Icons.emoji_events_rounded
                                  : Icons.flag_circle_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasSubmitted
                                  ? (isEn
                                      ? 'Score (${existingSubmission.score}/100)'
                                      : 'Nilai (${existingSubmission.score}/100)')
                                  : (isEn ? 'Mission Checklist' : 'Target Misi'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _promptResetForPractice(controller, session),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers_clear_outlined,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              isEn ? 'Start Clean' : 'Mulai Bersih',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (binding.resolveReferenceSession() != null)
                      InkWell(
                        onTap: () =>
                            _promptLoadReferenceExample(controller, session),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded,
                                  size: 12, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 4),
                              Text(
                                isEn ? 'Example Solution' : 'Contoh Solusi',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (locBinding.description != null &&
                    locBinding.description!.trim().isNotEmpty) ...[
                  Text(
                    locBinding.description!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                ],
                if (locBinding.instructions.isNotEmpty) ...[
                  ...locBinding.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 1, right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF334155),
                                  height: 1.25),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => VirtualLabMissionSheet.show(
                    context: context,
                    binding: binding,
                    session: session,
                    lastTest: _lastTest,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: hasSubmitted
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasSubmitted
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasSubmitted
                              ? Icons.emoji_events_rounded
                              : Icons.assignment_turned_in_rounded,
                          size: 15,
                          color: hasSubmitted
                              ? const Color(0xFF059669)
                              : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasSubmitted
                              ? (isEn
                                  ? 'View Lab Score & Details (${existingSubmission.score}/100)'
                                  : 'Lihat Nilai & Detail Praktikum (${existingSubmission.score}/100)')
                              : (isEn
                                  ? 'Open Checklist & Target Evaluation'
                                  : 'Buka Checklist & Evaluasi Target Misi'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasSubmitted
                                ? const Color(0xFF047857)
                                : const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: hasSubmitted
                              ? const Color(0xFF059669)
                              : const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  label: '+Server',
                  icon: Icons.dns_rounded,
                  active: false,
                  accent: accent,
                  plus: true,
                  onTap: () {
                    controller.addDevice(VirtualLabDeviceKind.server);
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
    return RepaintBoundary(
      key: _canvasKey,
      child: Container(
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
      case VirtualLabDeviceKind.server:
        return Icons.dns_rounded;
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
          _buildPanelTabButton(
            2,
            Icons.terminal_rounded,
            'Terminal',
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
                            : (device.kind == VirtualLabDeviceKind.server
                                ? 'Server · 1 port NIC (DHCP & Web)'
                                : l10n.virtualLabDeviceSwitchPorts)),
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _pcIpMode = VirtualLabIpMode.static_);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _pcIpMode == VirtualLabIpMode.static_
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _pcIpMode == VirtualLabIpMode.static_
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        'Static IP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _pcIpMode == VirtualLabIpMode.static_
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _pcIpMode = VirtualLabIpMode.dhcp);
                      final isEn = ref.read(languageProvider).languageCode == 'en';
                      final lease = controller.requestDhcpLease(device.id);
                      if (lease.success && lease.ipAddress != null) {
                        _ipController.text = lease.ipAddress!;
                        _maskController.text =
                            lease.subnetMask ?? '255.255.255.0';
                        _gatewayController.text = lease.defaultGateway ?? '';
                        NlSnackBar.show(
                          context,
                          isEn
                              ? 'DHCP Success: ${lease.ipAddress} allocated from ${lease.serverName ?? "DHCP Server"}'
                              : 'DHCP Sukses: ${lease.ipAddress} dialokasikan dari ${lease.serverName ?? "DHCP Server"}',
                        );
                      } else {
                        NlSnackBar.show(
                          context,
                          isEn
                              ? 'DHCP Failed: No active DHCP Server found connected to this network.'
                              : 'DHCP Gagal: Tidak ada Server DHCP aktif yang terhubung pada jaringan ini.',
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _pcIpMode == VirtualLabIpMode.dhcp
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _pcIpMode == VirtualLabIpMode.dhcp
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        'DHCP (Dinamis)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _pcIpMode == VirtualLabIpMode.dhcp
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_pcIpMode == VirtualLabIpMode.dhcp) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ipController.text.isNotEmpty &&
                              _ipController.text != '0.0.0.0'
                          ? 'Alamat IP didapatkan secara dinamis dari DHCP Server.'
                          : 'Mode DHCP aktif. Tekan tombol di bawah untuk meminta IP.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
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
                      readOnly: _pcIpMode == VirtualLabIpMode.dhcp,
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
                      readOnly: _pcIpMode == VirtualLabIpMode.dhcp,
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
            readOnly: _pcIpMode == VirtualLabIpMode.dhcp,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration:
                _fieldDecoration(hint: '192.168.1.1 (opsional jika 1 subnet)'),
          ),
          if (_pcIpMode == VirtualLabIpMode.dhcp) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                final isEn = ref.read(languageProvider).languageCode == 'en';
                final lease = controller.requestDhcpLease(device.id);
                if (lease.success && lease.ipAddress != null) {
                  _ipController.text = lease.ipAddress!;
                  _maskController.text =
                      lease.subnetMask ?? '255.255.255.0';
                  _gatewayController.text = lease.defaultGateway ?? '';
                  NlSnackBar.show(
                    context,
                    isEn
                        ? 'DHCP Success: ${lease.ipAddress} allocated from ${lease.serverName ?? "DHCP Server"}'
                        : 'DHCP Sukses: ${lease.ipAddress} dialokasikan dari ${lease.serverName ?? "DHCP Server"}',
                  );
                } else {
                  NlSnackBar.show(
                    context,
                    isEn
                        ? 'DHCP Failed: No active DHCP Server found connected to this network.'
                        : 'DHCP Gagal: Tidak ada Server DHCP aktif yang terhubung pada jaringan ini.',
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                ref.read(languageProvider).languageCode == 'en'
                    ? 'Request IP Address (DHCP Request)'
                    : 'Minta Ulang Alamat IP (DHCP Request)',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => setState(() => _panelTab = 2),
            icon: const Icon(Icons.terminal_rounded, size: 16),
            label: const Text('Buka Command Prompt (Terminal CLI)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
        ] else if (device.kind == VirtualLabDeviceKind.server) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFieldLabel('IP Address Server'),
                    TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(hint: '192.168.1.254'),
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
          const SizedBox(height: 10),
          _buildFieldLabel('Default Gateway (opsional)'),
          TextField(
            controller: _gatewayController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(hint: '192.168.1.1'),
            onChanged: (val) {
              if (_dhcpGatewayController.text.isEmpty ||
                  _dhcpGatewayController.text == device.defaultGateway ||
                  _dhcpGatewayController.text == '192.168.1.1') {
                _dhcpGatewayController.text = val;
              }
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.alt_route_rounded,
                            size: 16, color: Color(0xFF4F46E5)),
                        SizedBox(width: 6),
                        Text(
                          'Layanan DHCP Server',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _labText,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _dhcpServerEnabled,
                      activeThumbColor: const Color(0xFF4F46E5),
                      onChanged: (val) =>
                          setState(() => _dhcpServerEnabled = val),
                    ),
                  ],
                ),
                if (_dhcpServerEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFieldLabel('Mulai IP Pool'),
                            TextField(
                              controller: _dhcpStartIpController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  _fieldDecoration(hint: '192.168.1.100'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFieldLabel('Subnet Mask (Pool)'),
                            TextField(
                              controller: _dhcpMaskController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  _fieldDecoration(hint: '255.255.255.0'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFieldLabel('Default Gateway (Pool)'),
                            TextField(
                              controller: _dhcpGatewayController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(
                                hint: _gatewayController.text.isNotEmpty
                                    ? _gatewayController.text
                                    : '192.168.1.1',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFieldLabel('DNS Server'),
                            TextField(
                              controller: _dhcpDnsController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(hint: '8.8.8.8'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.language_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Layanan HTTP Web Server',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _labText,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _httpServerEnabled,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) =>
                          setState(() => _httpServerEnabled = val),
                    ),
                  ],
                ),
                if (_httpServerEnabled) ...[
                  const SizedBox(height: 8),
                  _buildFieldLabel('Judul Website Portal'),
                  TextField(
                    controller: _httpTitleController,
                    decoration:
                        _fieldDecoration(hint: 'NetLearn Server Portal'),
                  ),
                ],
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
                    : (device.kind == VirtualLabDeviceKind.server
                        ? '${session.cables.where((c) => c.involves(device.id)).length}/1 port NIC terhubung'
                        : (cabled
                            ? l10n.virtualLabCableConnected
                            : l10n.virtualLabCableNotConnected)),
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
        .where((d) =>
            d.kind == VirtualLabDeviceKind.pc ||
            d.kind == VirtualLabDeviceKind.server)
        .toList();
    if (devices.length < 2) {
      return _buildPanelHint(
        Localizations.localeOf(context).languageCode == 'id'
            ? 'Tambahkan minimal dua perangkat host (PC atau Server) untuk melakukan uji ping.'
            : 'Add at least two host devices (PC or Server) to test ping connectivity.',
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

  Widget _buildTerminalTab(
    VirtualLabSession session,
    AppLocalizations l10n,
    Color accent,
  ) {
    final id = session.selectedDeviceId;
    final device = id == null ? null : session.deviceById(id);

    if (device == null) {
      final firstPc = session.devices.cast<VirtualLabDevice?>().firstWhere(
            (d) => d != null && d.kind == VirtualLabDeviceKind.pc,
            orElse: () => null,
          );
      if (firstPc != null) {
        return VirtualLabTerminalWidget(
          device: firstPc,
          session: session,
          accent: accent,
          onPingResult: (result) {
            setState(() => _lastTest = result);
            if (result.success) _startPacketAnimation();
          },
          onDhcpLease: (lease) {
            if (lease.success && lease.ipAddress != null) {
              ref
                  .read(virtualLabControllerProvider.notifier)
                  .requestDhcpLease(firstPc.id);
            }
          },
          onDhcpRelease: () {
            ref
                .read(virtualLabControllerProvider.notifier)
                .releaseDhcp(firstPc.id);
          },
        );
      }
      return _buildPanelHint(
        Localizations.localeOf(context).languageCode == 'id'
            ? 'Tambahkan dan pilih PC di kanvas untuk menggunakan Command Prompt terminal.'
            : 'Add and select a PC on the canvas to use the Command Prompt terminal.',
      );
    }

    if (device.kind != VirtualLabDeviceKind.pc) {
      return _buildPanelHint(
        Localizations.localeOf(context).languageCode == 'id'
            ? 'Terminal Command Prompt hanya tersedia untuk perangkat PC (Host). Pilih salah satu PC di kanvas.'
            : 'Command Prompt terminal is only available on PC (Host) devices. Select a PC on the canvas.',
      );
    }

    return VirtualLabTerminalWidget(
      device: device,
      session: session,
      accent: accent,
      onPingResult: (result) {
        setState(() => _lastTest = result);
        if (result.success) _startPacketAnimation();
      },
      onDhcpLease: (lease) {
        if (lease.success && lease.ipAddress != null) {
          ref
              .read(virtualLabControllerProvider.notifier)
              .requestDhcpLease(device.id);
        }
      },
      onDhcpRelease: () {
        ref
            .read(virtualLabControllerProvider.notifier)
            .releaseDhcp(device.id);
      },
    );
  }

  void _showSavedTopologiesSheet(
    BuildContext context,
    VirtualLabController controller,
    VirtualLabSession session,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return _SavedTopologiesSheet(
          controller: controller,
          currentSession: session,
        );
      },
    );
  }

  void _showTopologyTemplatesSheet(
    BuildContext context,
    VirtualLabController controller,
  ) {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined,
                          color: Color(0xFF4F46E5), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isEn
                            ? 'Select Topology Template'
                            : 'Pilih Template Topologi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _labText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Select a ready-to-use topology design to start testing right away.'
                        : 'Pilih desain topologi siap pakai untuk langsung memulai pengujian jaringan.',
                    style: const TextStyle(fontSize: 12, color: _labMuted),
                  ),
                  const SizedBox(height: 16),
                  _buildTemplateTile(
                    icon: Icons.hub_outlined,
                    title: isEn
                        ? 'Star Topology (Single LAN Subnet)'
                        : 'Topologi Star (LAN 1 Subnet)',
                    subtitle: isEn
                        ? '1 Switch connects 3 PCs (192.168.1.0/24)'
                        : '1 Switch menghubungkan 3 PC (192.168.1.0/24)',
                    accent: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.pop(modalContext);
                      controller.loadPreset(VirtualLabController.presetStar());
                      _invalidateTest();
                      NlSnackBar.show(
                        context,
                        isEn
                            ? 'Star Topology template loaded.'
                            : 'Template Topologi Star berhasil dimuat.',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTemplateTile(
                    icon: Icons.router_outlined,
                    title: isEn
                        ? 'Dual-Subnet Routing (Layer 3)'
                        : 'Dual-Subnet Routing (Layer 3)',
                    subtitle: isEn
                        ? 'Router connects 2 subnets (192.168.1.0/24 & 192.168.2.0/24)'
                        : 'Router menghubungkan 2 subnet (192.168.1.0/24 & 192.168.2.0/24)',
                    accent: const Color(0xFF0EA5E9),
                    onTap: () {
                      Navigator.pop(modalContext);
                      controller
                          .loadPreset(VirtualLabController.presetDualSubnet());
                      _invalidateTest();
                      NlSnackBar.show(
                        context,
                        isEn
                            ? 'Dual-Subnet Routing template loaded.'
                            : 'Template Dual-Subnet Routing berhasil dimuat.',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTemplateTile(
                    icon: Icons.compare_arrows_rounded,
                    title: isEn
                        ? 'Peer-to-Peer (Direct Connection)'
                        : 'Peer-to-Peer (Koneksi Langsung)',
                    subtitle: isEn
                        ? '2 PCs directly connected via cable (10.0.0.0/24)'
                        : '2 PC terhubung langsung dengan kabel (10.0.0.0/24)',
                    accent: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(modalContext);
                      controller
                          .loadPreset(VirtualLabController.presetPeerToPeer());
                      _invalidateTest();
                      NlSnackBar.show(
                        context,
                        isEn
                            ? 'Peer-to-Peer template loaded.'
                            : 'Template Peer-to-Peer berhasil dimuat.',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTemplateTile(
                    icon: Icons.dns_outlined,
                    title: isEn
                        ? 'Client-Server DHCP & Web (LAN)'
                        : 'Client-Server DHCP & Web (LAN)',
                    subtitle: isEn
                        ? '1 DHCP/Web Server + 1 Switch + 2 PCs (Dynamic IP)'
                        : '1 Server DHCP/Web + 1 Switch + 2 PC (IP Dinamis Otomatis)',
                    accent: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(modalContext);
                      controller
                          .loadPreset(VirtualLabController.presetDhcpServer());
                      _invalidateTest();
                      NlSnackBar.show(
                        context,
                        isEn
                            ? 'Client-Server DHCP template loaded.'
                            : 'Template Client-Server DHCP berhasil dimuat.',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTemplateTile(
                    icon: Icons.layers_clear_outlined,
                    title: isEn
                        ? 'Blank Canvas (Reset)'
                        : 'Kanvas Kosong (Reset)',
                    subtitle: isEn
                        ? 'Start with an empty canvas for freeform experiments'
                        : 'Mulai dari kanvas kosong untuk eksperimen bebas',
                    accent: const Color(0xFF64748B),
                    onTap: () {
                      Navigator.pop(modalContext);
                      controller.loadPreset(VirtualLabController.presetBlank());
                      _invalidateTest();
                      NlSnackBar.show(
                        context,
                        isEn
                            ? 'Canvas cleared successfully.'
                            : 'Kanvas berhasil dikosongkan.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _labText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: _labMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCanvasToImage(VirtualLabSession session) async {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    HapticFeedback.lightImpact();
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        NlSnackBar.show(
          context,
          isEn ? 'Failed to locate canvas diagram.' : 'Gagal menemukan kanvas diagram.',
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      if (byteData == null) {
        NlSnackBar.show(
          context,
          isEn ? 'Failed to convert canvas to PNG format.' : 'Gagal mengonversi kanvas ke format PNG.',
        );
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (!mounted) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'NetLearn_Topology_$dateStr.png';

      showDialog(
        context: context,
        builder: (dialogCtx) {
          final pcCount = session.devices
              .where((d) => d.kind == VirtualLabDeviceKind.pc)
              .length;
          final routerCount = session.devices
              .where((d) => d.kind == VirtualLabDeviceKind.router)
              .length;
          final serverCount = session.devices
              .where((d) => d.kind == VirtualLabDeviceKind.server)
              .length;
          final switchCount = session.devices
              .where((d) => d.kind == VirtualLabDeviceKind.switch_)
              .length;
          final cableCount = session.cables.length;

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF4F46E5), size: 22),
                const SizedBox(width: 8),
                Text(
                  isEn ? 'Topology Diagram Preview' : 'Pratinjau Diagram Topologi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEn
                        ? 'Diagram rendered successfully in high-resolution PNG format.'
                        : 'Diagram berhasil dirender dalam format PNG resolusi tinggi.',
                    style: const TextStyle(fontSize: 12, color: _labMuted),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(pngBytes, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _labPageBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isEn
                          ? 'Details: $pcCount PC · $routerCount Router · $serverCount Server · $switchCount Switch · $cableCount Cables'
                          : 'Rincian: $pcCount PC · $routerCount Router · $serverCount Server · $switchCount Switch · $cableCount Kabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _labText),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined,
                            size: 15, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3730A3),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(isEn ? 'Close' : 'Tutup'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    final result =
                        await saveTopologyImage(pngBytes, fileName);
                    if (!mounted) return;
                    NlSnackBar.show(
                      context,
                      isEn
                          ? 'Image saved in Documents: ${result.fileName}'
                          : 'Gambar tersimpan di Dokumen: ${result.fileName}',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    NlSnackBar.show(
                      context,
                      isEn ? 'Failed to save image: $e' : 'Gagal menyimpan gambar: $e',
                    );
                  }
                },
                icon: const Icon(Icons.save_alt_rounded, size: 16),
                label: Text(isEn ? 'Save File' : 'Simpan File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    final result =
                        await saveTopologyImage(pngBytes, fileName);
                    if (!mounted) return;
                    NlSnackBar.show(
                      context,
                      isEn
                          ? 'Image saved. Opening in gallery...'
                          : 'Gambar tersimpan. Membuka di galeri foto...',
                    );
                    final opened = await openTopologyImage(result.filePath);
                    if (!opened && mounted) {
                      NlSnackBar.show(
                        context,
                        isEn
                            ? 'Image saved in Documents: ${result.fileName}'
                            : 'Gambar tersimpan di Dokumen: ${result.fileName}',
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    NlSnackBar.show(
                      context,
                      isEn ? 'Failed to process image: $e' : 'Gagal memproses gambar: $e',
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(isEn ? 'Save & Open' : 'Simpan & Buka'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        NlSnackBar.show(
          context,
          isEn
              ? 'Problem rendering topology diagram image.'
              : 'Terjadi kendala saat merender gambar diagram.',
        );
      }
    }
  }

  void _askNetBotAboutTopology(VirtualLabSession session) {
    final lang = ref.read(languageProvider).languageCode;
    HapticFeedback.lightImpact();

    final devLines = session.devices.map((d) {
      final ip = (d.ipAddress ?? '').trim().isEmpty ? 'no-IP' : d.ipAddress!.trim();
      final sub = (d.subnetMask ?? '').trim().isEmpty ? '' : '/${d.subnetMask!.trim()}';
      final gw = (d.defaultGateway ?? '').trim().isEmpty ? '' : ', GW=${d.defaultGateway!.trim()}';
      return '- ${d.displayName} (${d.kind.name}): $ip$sub$gw';
    }).join('\n');

    final cableLines = session.cables.map((c) {
      final d1 = session.deviceById(c.from)?.displayName ?? c.from;
      final d2 = session.deviceById(c.to)?.displayName ?? c.to;
      return '- $d1 <---> $d2';
    }).join('\n');

    final snippet = 'Topologi Virtual Lab Saat Ini:\n'
        'Daftar Perangkat:\n$devLines\n'
        'Koneksi Antar Perangkat:\n$cableLines';

    showNetBotChatSheet(
      context,
      netBotContext: NetBotContext(
        moduleTitle: 'Virtual Lab 2D Networking',
        topologySnippet: snippet,
        languageCode: lang,
      ),
    );
  }

  void _diagnoseWithNetBot(
    VirtualLabSession session,
    VirtualLabConnectivityResult result,
  ) {
    final lang = ref.read(languageProvider).languageCode;
    HapticFeedback.mediumImpact();

    final devLines = session.devices.map((d) {
      final ip = (d.ipAddress ?? '').trim().isEmpty ? 'no-IP' : d.ipAddress!.trim();
      final sub = (d.subnetMask ?? '').trim().isEmpty ? '' : '/${d.subnetMask!.trim()}';
      final gw = (d.defaultGateway ?? '').trim().isEmpty ? '' : ', GW=${d.defaultGateway!.trim()}';
      return '- ${d.displayName} (${d.kind.name}): $ip$sub$gw';
    }).join('\n');

    final cableLines = session.cables.map((c) {
      final d1 = session.deviceById(c.from)?.displayName ?? c.from;
      final d2 = session.deviceById(c.to)?.displayName ?? c.to;
      return '- $d1 <---> $d2';
    }).join('\n');

    final detailsText = result.details.isNotEmpty ? '\nDetail: ${result.details.join(", ")}' : '';
    final pingDetail = 'Hasil Tes Konektivitas: ${result.success ? "SUKSES" : "GAGAL / MASALAH DITEMUKAN"}\n'
        'Penyebab / Pesan: ${result.reason}$detailsText';

    final snippet = 'Topologi Virtual Lab:\n'
        'Daftar Perangkat:\n$devLines\n'
        'Koneksi:\n$cableLines\n\n'
        'Diagnostik Konektivitas:\n$pingDetail';

    showNetBotChatSheet(
      context,
      netBotContext: NetBotContext(
        moduleTitle: 'Troubleshooting Virtual Lab',
        topologySnippet: snippet,
        languageCode: lang,
      ),
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

// ---------------------------------------------------------------------------
// Bottom Sheet Manajemen Penyimpanan Topologi Kustom (Fase 5)
// ---------------------------------------------------------------------------

class _SavedTopologiesSheet extends ConsumerStatefulWidget {
  final VirtualLabController controller;
  final VirtualLabSession currentSession;

  const _SavedTopologiesSheet({
    required this.controller,
    required this.currentSession,
  });

  @override
  ConsumerState<_SavedTopologiesSheet> createState() =>
      _SavedTopologiesSheetState();
}

class _SavedTopologiesSheetState extends ConsumerState<_SavedTopologiesSheet> {
  int _activeTab = 0; // 0 = Topologi Tersimpan, 1 = Simpan Saat Ini
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  List<VirtualLabSavedTopology>? _savedList;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _nameController = TextEditingController(
      text: 'Topologi Lab ($dateStr)',
    );
    _descController = TextEditingController();
    _loadTopologies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTopologies() async {
    setState(() => _loading = true);
    final storage = ref.read(virtualLabStorageServiceProvider);
    final list = await storage.getSavedTopologies();
    if (mounted) {
      setState(() {
        _savedList = list;
        _loading = false;
        if (list.isEmpty) {
          _activeTab = 1; // Beralih ke simpan jika belum ada data
        }
      });
    }
  }

  Future<void> _handleSave() async {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      NlSnackBar.show(
        context,
        isEn
            ? 'Topology scenario name cannot be empty'
            : 'Nama skenario topologi tidak boleh kosong',
      );
      return;
    }

    final desc = _descController.text.trim();
    final storage = ref.read(virtualLabStorageServiceProvider);
    await storage.saveTopology(
      name: name,
      description: desc.isNotEmpty ? desc : null,
      session: widget.currentSession,
    );

    await _loadTopologies();
    if (mounted) {
      setState(() => _activeTab = 0);
      NlSnackBar.show(
        context,
        isEn
            ? 'Topology "$name" saved successfully!'
            : 'Topologi "$name" berhasil disimpan!',
      );
    }
  }

  Future<void> _handleImportJson() async {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    HapticFeedback.lightImpact();
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return;

      final file = files.first;
      final storage = ref.read(virtualLabStorageServiceProvider);
      final rawContent = await storage.readPickedFile(file);

      if (rawContent == null || rawContent.trim().isEmpty) {
        if (mounted) {
          NlSnackBar.show(
            context,
            isEn
                ? 'Failed to read the selected JSON file.'
                : 'Gagal membaca berkas JSON yang dipilih.',
          );
        }
        return;
      }

      final session = storage.parseTopologyJson(rawContent);
      if (session == null) {
        if (mounted) {
          NlSnackBar.show(
            context,
            isEn
                ? 'Invalid or corrupted JSON file format.'
                : 'Format berkas JSON tidak sesuai atau rusak.',
          );
        }
        return;
      }

      widget.controller.loadSession(session);
      if (mounted) {
        Navigator.pop(context);
        NlSnackBar.show(
          context,
          isEn
              ? 'Topology imported: ${session.devices.length} devices & ${session.cables.length} cables loaded!'
              : 'Topologi berhasil diimpor: ${session.devices.length} perangkat & ${session.cables.length} kabel dimuat!',
        );
      }
    } catch (e) {
      if (mounted) {
        NlSnackBar.show(
          context,
          isEn
              ? 'Error importing file: $e'
              : 'Terjadi kesalahan saat mengimpor berkas: $e',
        );
      }
    }
  }

  Future<void> _handleExportJson(VirtualLabSavedTopology topology) async {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    HapticFeedback.lightImpact();
    try {
      final storage = ref.read(virtualLabStorageServiceProvider);
      final result = await storage.exportTopologyToJsonFile(
        session: topology.toSession(),
        name: topology.name,
        description: topology.description,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 8),
                Text(
                  isEn ? 'JSON Export Successful' : 'Ekspor JSON Sukses',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Topology file exported to device storage successfully:'
                      : 'Berkas topologi berhasil diekspor ke penyimpanan perangkat:',
                  style: const TextStyle(fontSize: 12.5, color: _labText),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: SelectableText(
                    result.filePath,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(isEn ? 'Close' : 'Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NlSnackBar.show(
          context,
          isEn
              ? 'Failed to export JSON file: $e'
              : 'Gagal mengekspor berkas JSON: $e',
        );
      }
    }
  }

  Future<void> _handleDelete(VirtualLabSavedTopology topology) async {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEn ? 'Delete Topology?' : 'Hapus Topologi?',
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          isEn
              ? 'Topology "${topology.name}" will be deleted permanently from your device.'
              : 'Topologi "${topology.name}" akan dihapus permanen dari perangkat.',
          style: const TextStyle(fontSize: 13, color: _labText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isEn ? 'Cancel' : 'Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final storage = ref.read(virtualLabStorageServiceProvider);
              await storage.deleteTopology(topology.id);
              await _loadTopologies();
              if (mounted) {
                NlSnackBar.show(
                  context,
                  isEn
                      ? 'Topology "${topology.name}" deleted successfully'
                      : 'Topologi "${topology.name}" berhasil dihapus',
                );
              }
            },
            child: Text(isEn ? 'Delete' : 'Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLoadToCanvas(VirtualLabSavedTopology topology) async {
    final isEn = ref.read(languageProvider).languageCode == 'en';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEn ? 'Load to Canvas?' : 'Muat ke Kanvas?',
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          isEn
              ? 'Topology "${topology.name}" will replace current canvas design (${widget.currentSession.devices.length} devices). Continue?'
              : 'Topologi "${topology.name}" akan menggantikan rancangan kanvas saat ini (${widget.currentSession.devices.length} perangkat). Lanjutkan?',
          style: const TextStyle(fontSize: 13, color: _labText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isEn ? 'Cancel' : 'Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.controller.loadSession(topology.toSession());
              Navigator.pop(context);
              NlSnackBar.show(
                context,
                isEn
                    ? 'Topology "${topology.name}" loaded onto canvas successfully!'
                    : 'Topologi "${topology.name}" berhasil dimuat ke kanvas!',
              );
            },
            child: Text(isEn ? 'Load' : 'Muat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(languageProvider).languageCode == 'en';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header & Tombol Impor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Manage Topologies' : 'Kelola Topologi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _labText,
                          ),
                        ),
                        Text(
                          isEn
                              ? 'Save, load, export & import scenarios'
                              : 'Simpan, muat, ekspor & impor skenario',
                          style: const TextStyle(fontSize: 11.5, color: _labMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _handleImportJson,
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: Text(
                      isEn ? 'Import JSON' : 'Impor JSON',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Selector (Pill Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            isEn
                                ? 'Saved (${_savedList?.length ?? 0})'
                                : 'Tersimpan (${_savedList?.length ?? 0})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _activeTab == 0
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            isEn ? '+ Save New' : '+ Simpan Baru',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _activeTab == 1
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tab Content
            Expanded(
              child: _loading
                  ? const NlSkeletonList(
                      itemCount: 3,
                      padding: EdgeInsets.all(16),
                    )
                  : _activeTab == 0
                      ? _buildSavedListTab(isEn)
                      : _buildSaveFormTab(isEn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedListTab(bool isEn) {
    final list = _savedList ?? [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_rounded,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'No Saved Topologies Yet'
                    : 'Belum Ada Topologi Tersimpan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _labText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEn
                    ? 'Your saved network designs will appear here so you can reopen them anytime.'
                    : 'Rancangan jaringan yang Anda simpan akan muncul di sini agar dapat dibuka kapan saja.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: _labMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _activeTab = 1),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isEn ? 'Save Current Topology' : 'Simpan Topologi Saat Ini',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final timeStr =
            '${item.updatedAt.day.toString().padLeft(2, '0')}/${item.updatedAt.month.toString().padLeft(2, '0')}/${item.updatedAt.year} ${item.updatedAt.hour.toString().padLeft(2, '0')}:${item.updatedAt.minute.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _labText,
                          ),
                        ),
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _labMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Color(0xFFEF4444)),
                    tooltip: isEn ? 'Delete' : 'Hapus',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _handleDelete(item),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEn
                          ? '${item.deviceCount} Devices'
                          : '${item.deviceCount} Perangkat',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEn
                          ? '${item.cableCount} Cables'
                          : '${item.cableCount} Kabel',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10.5, color: _labMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleLoadToCanvas(item),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: Text(
                        isEn ? 'Load to Canvas' : 'Muat ke Kanvas',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _handleExportJson(item),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: Text(
                      isEn ? 'Export JSON' : 'Ekspor JSON',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveFormTab(bool isEn) {
    final devCount = widget.currentSession.devices.length;
    final cableCount = widget.currentSession.cables.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Canvas Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lan_rounded,
                    color: Color(0xFF4F46E5), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Active Canvas Design' : 'Rancangan Kanvas Aktif',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _labText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEn
                            ? '$devCount devices · $cableCount cables attached'
                            : '$devCount perangkat · $cableCount sambungan kabel terpasang',
                        style:
                            const TextStyle(fontSize: 11, color: _labMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nama Topologi
          Text(
            isEn ? 'Topology Scenario Name *' : 'Nama Skenario Topologi *',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _labText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: isEn
                  ? 'e.g.: Star LAN Subnetting Lab'
                  : 'Misal: Praktikum Subnetting Star LAN',
              hintStyle: const TextStyle(fontSize: 12, color: _labMuted),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Deskripsi / Catatan
          Text(
            isEn ? 'Notes / Description (optional)' : 'Catatan / Deskripsi (opsional)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _labText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isEn
                  ? 'Add lab notes, IP subnets used, or assignment notes...'
                  : 'Tambahkan catatan praktikum, subnet IP yang dipakai, atau tugas dosen...',
              hintStyle: const TextStyle(fontSize: 12, color: _labMuted),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Tombol Simpan
          FilledButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(
              isEn ? 'Save to Topology List' : 'Simpan ke Daftar Topologi',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

