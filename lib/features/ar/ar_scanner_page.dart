import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';

import '../../l10n/app_localizations.dart';
import '../achievements/achievement_service.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../dashboard_lecturer/lecturer_bottom_navbar.dart';
import 'ar_lab_panel.dart';
import 'ar_lab_scene.dart';
import 'ar_marker_catalog.dart';
import 'ar_narration.dart';
import 'ar_narration_controller.dart';
import 'ar_node_factory.dart';
import 'ar_object_detail_panel.dart';
import 'ip_simulation.dart';

/// Brightness multiplier applied to the plugin's two directional lights.
///
/// The GLB models were authored for offline renderers with image-based
/// lighting; the plugin only sets two directional lights (`ModelRenderer.kt`),
/// so dark-albedo meshes (the Modul 1 PC is ~12% grey) came out nearly black.
/// 2.0 lifts them into view without washing out the lighter models. Tune down if
/// the hub/switch ever look overexposed on device — the switch is emissive, so
/// it is unaffected by this value.
const double kArLightIntensityMultiplier = 2.0;

/// Current scanning state, drives which overlay the page shows.
///
/// - [initializing] — session is starting, camera has no image database yet.
/// - [searching]    — image tracking is configured, waiting for a marker.
/// - [detected]     — a catalog marker was recognized, info card is shown.
/// - [failed]       — session/init failed; user is offered a retry.
enum _ArScanStatus { initializing, searching, detected, failed }

/// Which loop the Modul 4 packet is playing, if any.
///
/// Success runs the full A -> switch -> B path; failure runs only the A ->
/// switch leg and restarts (the packet pauses at the switch each loop), so a
/// failed connection is never shown as a packet arriving at Computer B
/// (AR_PRD §6.4C, AR-12).
enum _LabPacketMode { none, success, failure }

/// AR Scanner page with camera feed and marker-scanning UI.
///
/// Uses [ARView] from `ar_flutter_plugin_plus` for the camera and AR session.
/// The page recognizes the six NetLearn markers, loads the matching 3D model
/// ([ArMarker.modelPath]) onto the detected card, and shows a learning-info
/// card. Modul 1–3 models are wired via [arNodeForMarker]. Modul 4's marker has
/// no single GLB, so it instead builds the interactive 3D lab (see
/// `ar_lab_scene.dart`) and swaps the info card for [ArLabPanel].
///
/// The page deliberately does not touch learning progress, unlock state or any
/// other feature: scanning a marker is a read-only learning aid. See the PRD
/// rule "Pemindaian marker tidak otomatis memperbarui progres".
///
/// For testing, pass a [testArViewBuilder] to replace the real [ARView] with a
/// test-friendly placeholder that doesn't require camera permissions or platform
/// views. The test view's managers are accepted loosely (see [_onARViewCreated]),
/// so a builder may hand over nulls or stand-in objects.
class ArScannerPage extends StatefulWidget {
  final bool isLecturer;
  final int currentNavIndex;

  /// Optional builder for test environments. When provided, this replaces the
  /// real [ARView] with a test-friendly widget that doesn't require camera
  /// permissions or platform views.
  /// Uses `dynamic` for callback parameters to allow test-friendly builders
  /// that don't depend on the AR plugin types.
  final Widget Function(
    BuildContext,
    void Function(
      dynamic,
      dynamic,
      dynamic,
      dynamic,
    ),
  )? testArViewBuilder;

  const ArScannerPage.student({super.key})
      : isLecturer = false,
        currentNavIndex = 2,
        testArViewBuilder = null;

  const ArScannerPage.lecturer({super.key})
      : isLecturer = true,
        currentNavIndex = 2,
        testArViewBuilder = null;

  /// Creates a test-friendly version with a fake AR view.
  const ArScannerPage.test({
    super.key,
    required this.isLecturer,
    required this.currentNavIndex,
    required this.testArViewBuilder,
  });

  @override
  State<ArScannerPage> createState() => _ArScannerPageState();
}

class _ArScannerPageState extends State<ArScannerPage>
    with TickerProviderStateMixin {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  /// Drives the Modul 4 packet: the full A -> switch -> B path after a
  /// successful test, or only the A -> switch leg (repeated) after a failed
  /// one — `_labPacketMode` decides which transform each frame gets.
  late AnimationController _labPacketController;

  late _ArScanStatus _status;
  ArMarker? _detectedMarker;

  /// Whether the Modul 1–3 detail panel is open. Opened only by the summary
  /// card's "View Full Information" button (`_ObjectInfoCard.onShowDetail`),
  /// closed by the panel's close button, a marker switch or a rescan.
  bool _showDetail = false;

  /// 3D model currently in the scene, if any. Only one marker's model is shown
  /// at a time: detecting a new marker removes this before adding the next.
  ARNode? _currentNode;

  /// Modul 4 lab: the static props (PCs, switch, cables) added for marker 6.
  /// The packet is tracked separately because it is added/removed per test.
  final List<ARNode> _labNodes = <ARNode>[];
  ARNode? _labPacketNode;

  /// Which packet animation is playing (see [_LabPacketMode]).
  _LabPacketMode _labPacketMode = _LabPacketMode.none;

  /// Pose the lab was anchored to. `null` while no lab is on screen; also the
  /// guard that stops taps on other markers' models from selecting a device.
  Matrix4? _labMarkerPose;

  /// Which computer the panel is currently editing. Kept on the page (not the
  /// panel) so a tap on a 3D computer can switch it.
  ArLabDevice _labSelectedDevice = ArLabDevice.pcA;

  /// Key for the real [ARView]. Setting it to `null` unmounts the platform view,
  /// which is the only way to tear down the native session and clear the
  /// plugin's one-shot detection set; a fresh key then rebuilds it. See
  /// [_restartScanning].
  Key? _arViewKey = UniqueKey();

  /// True when a test builder stands in for the camera. The fake view never
  /// produces a session, so the page starts already "ready to scan" and does
  /// not animate the reticle forever (an infinite animation would make
  /// `pumpAndSettle` time out in widget tests).
  bool get _isTestMode => widget.testArViewBuilder != null;

  /// Object narration for this AR session. Owned by the page (not a provider):
  /// the player must stop the moment the page is left, and an AR session is the
  /// natural lifetime. Tests never reach a real player because the page is not
  /// driven past detection there.
  late final ArNarrationController _narration;

  /// Active app language, used to pick `<clip>_en.mp3` or `<clip>_id.mp3`.
  String get _narrationLanguage =>
      Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();

    _narration = ArNarrationController();
    unawaited(_narration.loadPreference());

    _status = _isTestMode ? _ArScanStatus.searching : _ArScanStatus.initializing;

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );

    // The packet ticker updates only the packet node's transform each frame,
    // which the plugin forwards over its channel — keep it created here but not
    // running so a compared-against value is always available.
    _labPacketController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..addListener(_updateLabPacketTransform);

    if (_isTestMode) {
      // Static mid-position so the reticle still paints without scheduling
      // frames forever.
      _scanLineController.value = 0.5;
    } else {
      _scanLineController.repeat(reverse: false);
    }
  }

  @override
  void dispose() {
    _narration.dispose();
    _scanLineController.dispose();
    _labPacketController.dispose();
    // Release the camera and native AR session while leaving the page. Without
    // this the platform view keeps the camera open and can leak memory (PRD AR
    // lifecycle requirement).
    _arSessionManager?.dispose();
    super.dispose();
  }

  /// Callback from [ARView] (real) or [ArScannerPage.testArViewBuilder] (test).
  ///
  /// The parameters are accepted loosely so a test builder can pass nulls or
  /// mock objects without triggering a type cast error. In real use they are the
  /// concrete plugin managers created by the plugin.
  void _onARViewCreated(
    Object? sessionManager,
    Object? objectManager,
    Object? anchorManager,
    Object? locationManager,
  ) {
    if (sessionManager is ARSessionManager) {
      _arSessionManager = sessionManager;
    }
    if (objectManager is ARObjectManager) {
      _arObjectManager = objectManager;
    }

    // A fake/test view never supplies a real session: stop here so no platform
    // channel calls are made.
    if (_arSessionManager == null || _arObjectManager == null) return;

    _initializeARSession();
  }

  Future<void> _initializeARSession() async {
    final session = _arSessionManager;
    final objects = _arObjectManager;
    if (session == null || objects == null) return;

    // Image detection fires once per marker entry because continuous tracking is
    // off. Re-detection after a marker is lost and found again comes through the
    // same handler, which is why [_handleImageDetected] is written to be
    // idempotent.
    session.onImageDetected = (imageName, transformation) {
      _handleImageDetected(imageName, transformation);
    };

    // The native side emits every screen tap through this handler whether or
    // not taps are "enabled" (the `handleTaps` flag is parsed but unused, and
    // `onPlaneOrPointTap` is a non-nullable `late` field), so it must always be
    // assigned or a tap would throw. The 3D lab uses the hit pose to select a
    // computer; for every other marker this simply ignores the tap.
    session.onPlaneOrPointTap = _handleScreenTap;

    session.onImageTrackingConfigured = (success) {
      if (!mounted) return;
      setState(() {
        _status = success ? _ArScanStatus.searching : _ArScanStatus.failed;
      });
    };

    session.onTrackingStateChanged = (state, reason) {
      // Surfaced for future tuning; the visible state is driven by the image
      // configuration callback and detections.
    };

    try {
      // Object manager must be initialized before any node work — it sets the
      // native model scale factor used when the detected marker's GLB loads.
      objects.onInitialize();

      await session.onInitialize(
        showFeaturePoints: false,
        showPlanes: false,
        showWorldOrigin: false,
        // Kept true for clarity even though the native side ignores the flag:
        // taps are always delivered (see the onPlaneOrPointTap assignment).
        handleTaps: true,
        trackingImagePaths: arMarkerAssetPaths,
        // One-shot detection: the native side emits once when a marker enters
        // tracking and again only after it is lost and re-found. This is what
        // stops the info handling from firing uncontrollably.
        continuousImageTracking: false,
        imageTrackingUpdateIntervalMs: 1000,
        lightIntensityMultiplier: kArLightIntensityMultiplier,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ArScanStatus.failed;
      });
    }
  }

  /// Maps a detected image name to its catalog entry, updates the info card and
  /// loads the matching 3D model at the detected pose.
  ///
  /// Unknown names are ignored (should not happen — only catalog images are
  /// registered — but it keeps a stray detection from showing a wrong object).
  /// Repeated detections of the marker already on screen are no-ops, so the card
  /// and model never stack.
  void _handleImageDetected(String imageName, Matrix4 transformation) {
    final marker = arMarkerByImageName(imageName);
    if (marker == null) return;
    if (!mounted) return;
    if (_status == _ArScanStatus.detected &&
        _detectedMarker?.id == marker.id) {
      return;
    }
    setState(() {
      _detectedMarker = marker;
      _status = _ArScanStatus.detected;
    });

    AchievementService.unlockBadge(context, 'ar_pioneer');

    // Narration replaces the tap-to-open path the plugin cannot deliver
    // reliably (AR-10): the object introduces itself once the marker is on
    // screen. The controller waits a second so the voice does not start while
    // the camera is still settling.
    final ArNarrationClip? clip = arNarrationForMarker(marker.id);

    if (clip != null) {
      _narration.speak(clip, language: _narrationLanguage);
    }

    _showMarkerModel(marker, transformation);
  }

  /// Replaces the on-screen model with [marker]'s, placed at [transformation]
  /// (the detected card's pose). A marker without a model (e.g. Modul 4) clears
  /// the scene and shows only its info card.
  ///
  /// The previous node is always removed first so switching markers never leaves
  /// two objects in the scene. A failed load is swallowed: the PRD requires the
  /// page to stay stable when a model cannot be loaded, and the info card is
  /// still useful on its own.
  Future<void> _showMarkerModel(ArMarker marker, Matrix4 transformation) async {
    final objects = _arObjectManager;
    if (objects == null) return;

    // Clear anything the previous marker placed, so switching markers never
    // leaves two objects (or a whole lab) in the scene.
    _removeLabScene();

    final ARNode? previous = _currentNode;
    if (previous != null) {
      objects.removeNode(previous);
      _currentNode = null;
    }

    // Modul 4 (marker 6) has no single GLB: it builds the interactive lab of
    // separate nodes (PCs, switch, cables) so devices can be selected and the
    // packet animated independently. Device selection matches its own device
    // centres (see [_handleScreenTap]), not the marker anchor.
    if (marker.id == ArMarkerId.ipAddress) {
      _showDetail = false;
      await _showLabScene(objects, transformation);
      return;
    }

    // A new single-model marker starts on its summary card; the detail panel
    // opens only from the card's "View Full Information" button. (The 3D tap
    // path is disabled — see [_handleScreenTap].)
    _showDetail = false;

    final ARNode? node =
        arNodeForMarker(marker, transformation: transformation);
    if (node == null) return;

    try {
      await objects.addNode(node);
      if (!mounted) return;
      _currentNode = node;
    } catch (e) {
      // Model load failed; keep the info card and do not crash.
    }
  }

  /// Adds the Modul 4 lab's static props anchored to the detected marker pose.
  ///
  /// Each node is registered in [_labNodes] before its `addNode` await so a
  /// mid-way failure still leaves every successfully-added node tracked for
  /// teardown. A failed load is swallowed: the panel still works on its own and
  /// the PRD requires the page to stay stable when a model cannot be loaded.
  Future<void> _showLabScene(
    ARObjectManager objects,
    Matrix4 transformation,
  ) async {
    _labMarkerPose = transformation.clone();
    final List<ARNode> nodes = arLabStaticNodes(_labMarkerPose!);
    for (final ARNode node in nodes) {
      _labNodes.add(node);
      try {
        await objects.addNode(node);
      } catch (e) {
        // Keep going; a partial lab is still usable.
      }
    }
    if (!mounted) return;
    setState(() {
      _labSelectedDevice = ArLabDevice.pcA;
    });

    // Orientation for the lab scene: say what the student is looking at, then
    // let each computer introduce itself when tapped. The switch is not a
    // selectable device (`ArLabDevice` has only the two computers), so this is
    // its only entry point.
    _narration.speak(
      ArNarrationClip.labSwitch,
      language: _narrationLanguage,
    );
  }

  /// Removes every lab node and stops the packet. Safe to call when no lab is
  /// present (used by marker switches, rescan and teardown).
  void _removeLabScene() {
    _stopLabPacket();
    final objects = _arObjectManager;
    if (objects != null) {
      for (final ARNode node in _labNodes) {
        objects.removeNode(node);
      }
    }
    _labNodes.clear();
    _labMarkerPose = null;
  }

  /// Stops the packet animation and removes the packet node, leaving the static
  /// props in place.
  void _stopLabPacket() {
    _labPacketController.stop();
    _labPacketController.value = 0;
    _labPacketMode = _LabPacketMode.none;
    final ARNode? packet = _labPacketNode;
    if (packet != null) {
      _arObjectManager?.removeNode(packet);
      _labPacketNode = null;
    }
  }

  /// Runs the packet animation for the result of a connection test.
  ///
  /// On success the packet loops along the full A -> switch -> B path. On
  /// failure it loops along the A -> switch leg only and pauses at the switch —
  /// a failed connection must never be accompanied by a packet that appears to
  /// reach the destination (AR_PRD §6.4C, AR-12). The same node is reused and
  /// just retargeted, so switching from a success loop to a failure loop (or
  /// back) never stacks packets.
  Future<void> _onLabTestResult(IpConnectionResult result) async {
    final objects = _arObjectManager;
    final pose = _labMarkerPose;
    if (objects == null || pose == null) return;

    if (_labPacketNode == null) {
      final ARNode packet = arLabPacketNode(kArLabNodePacket, pose);
      try {
        await objects.addNode(packet);
      } catch (e) {
        return; // Packet node could not be shown; the result card still shows.
      }
      if (!mounted) return;
      _labPacketNode = packet;
    }
    setState(() {
      _labPacketMode =
          result.success ? _LabPacketMode.success : _LabPacketMode.failure;
    });
    _labPacketController
      ..value = 0
      ..repeat();

    // The result is the payoff of the whole simulation, so it is spoken right
    // away (no detection delay) alongside the packet animation.
    unawaited(
      _narration.replay(
        result.success
            ? ArNarrationClip.labTestSuccess
            : ArNarrationClip.labTestFailure,
        language: _narrationLanguage,
      ),
    );
  }

  /// Frame callback that moves the packet along the path chosen by
  /// [_labPacketMode].
  void _updateLabPacketTransform() {
    final ARNode? packet = _labPacketNode;
    final Matrix4? pose = _labMarkerPose;
    if (packet == null || pose == null) return;
    switch (_labPacketMode) {
      case _LabPacketMode.success:
        packet.transform = arLabPacketTransform(pose, _labPacketController.value);
      case _LabPacketMode.failure:
        packet.transform = arLabPacketToSwitchTransform(
          pose,
          arLabPacketFailureProgress(_labPacketController.value),
        );
      case _LabPacketMode.none:
        break;
    }
  }

  void _onLabReset() {
    _stopLabPacket();
  }

  /// Handles a tap on the camera feed via the ARCore hit-test pose.
  ///
  /// Only the Modul 4 lab reacts to taps: the tap's hit point selects the
  /// nearest computer to its device centres ([arLabDeviceAt]). Taps on empty
  /// space never select a device (the PRD rule that a tap on an empty area
  /// must not be mistaken for an object tap).
  ///
  /// The Modul 1–3 tap-to-open-info path is intentionally disabled (an
  /// approved AR-10 deviation): the plugin cannot report mesh taps on Android
  /// (`onNodeTap` is never sent) and the sparse ARCore feature points it
  /// delivers instead are not reliable on every surface, so taps only opened
  /// the panel intermittently. The detail panel now opens exclusively from
  /// the summary card's "View Full Information" button, the guaranteed
  /// affordance. The matching helpers ([arMarkerTappedAt] /
  /// [arMarkerTappedAtAny] and [ArMarker.tapRadius]) and their unit tests are
  /// kept unwired in case the tap path is ever re-enabled.
  void _handleScreenTap(List<ARHitTestResult> hits) {
    // The Modul 4 lab keeps its exact behaviour: taps select a device centre.
    final Matrix4? labPose = _labMarkerPose;
    if (labPose == null) return;
    if (hits.isEmpty || !mounted) return;
    final t = hits.first.worldTransform.getTranslation();
    final ArLabDevice? device =
        arLabDeviceAt(<double>[t.x, t.y, t.z], labPose);
    if (device == null) return;

    if (device != _labSelectedDevice) {
      setState(() {
        _labSelectedDevice = device;
      });
    }

    // Taps are the only reliable object interaction the plugin offers (Modul 4
    // keeps its device pick), so they also speak: tapping the same computer
    // again replays its narration instead of being swallowed by the selection
    // guard above.
    unawaited(
      _narration.replay(
        arNarrationForLabDevice(device),
        language: _narrationLanguage,
      ),
    );
  }

  /// Dismisses the info card and returns to scanning, so the student can point
  /// the camera at another marker. The model stays placed until another marker
  /// is detected, so the scene does not blink empty.
  void _resumeScanning() {
    // Freeze the packet when its panel is dismissed so the channel is not
    // written every frame for an off-screen animation; the props stay placed so
    // the scene does not blink empty.
    _labPacketController.stop();
    _narration.stop();
    setState(() {
      _detectedMarker = null;
      _showDetail = false;
      _status = _ArScanStatus.searching;
    });
  }

  /// Tears down and rebuilds the AR platform view so a marker that was already
  /// recognized can be detected again.
  ///
  /// The plugin emits each catalog image only once per native session: it adds
  /// the name to `activeAugmentedImages` on first full tracking and only clears
  /// that set when the view is destroyed (`AndroidARView.onPause`/`onDestroy`).
  /// ARCore never reports `STOPPED` for an out-of-frame image, so Dart cannot
  /// clear the set through the session API — the supported reset is to destroy
  /// the platform view. Unmounting the [ARView] (key → null) does that; a fresh
  /// key then builds a new session whose detection set starts empty.
  Future<void> _restartScanning() async {
    if (!mounted) return;
    // The test view never produces a session, so there is nothing to recreate.
    if (_isTestMode) return;

    _narration.stop();

    setState(() {
      _status = _ArScanStatus.initializing;
      _detectedMarker = null;
      _showDetail = false;
      _currentNode = null;
      // The platform view is about to be destroyed, which drops every native
      // node; clear the Dart-side lab bookkeeping to match and stop the ticker
      // so it does not write to a dying channel.
      _stopLabPacket();
      _labNodes.clear();
      _labMarkerPose = null;
      _arSessionManager = null;
      _arObjectManager = null;
      // Drop the platform view; Flutter disposes it, running the native
      // teardown that clears the one-shot detection set.
      _arViewKey = null;
    });

    // Let the old platform view finish disposing before rebuilding, so the new
    // session does not race it for the camera.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _arViewKey = UniqueKey();
    });
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.arHelpTitle),
        content: Text(l10n.arHelpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (_status) {
      case _ArScanStatus.initializing:
        return l10n.arStatusInitializing;
      case _ArScanStatus.searching:
        return l10n.arStatusSearching;
      case _ArScanStatus.detected:
        return l10n.arMarkerDetected;
      case _ArScanStatus.failed:
        return l10n.arInitFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Build the AR camera view - use test builder if provided, otherwise real ARView
    final Widget arCameraView = widget.testArViewBuilder != null
        ? widget.testArViewBuilder!(
            context,
            (dynamic a, dynamic b, dynamic c, dynamic d) =>
                _onARViewCreated(a, b, c, d),
          )
        : (_arViewKey == null
            ? const ColoredBox(color: Colors.black)
            : ARView(
                key: _arViewKey,
                onARViewCreated: _onARViewCreated,
                planeDetectionConfig: PlaneDetectionConfig.none,
                permissionPromptDescription: l10n.arScanPermissionDenied,
                permissionPromptButtonText: l10n.retry,
              ));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // AR Camera View
          arCameraView,

          // Initializing spinner while the image database is being built.
          if (_status == _ArScanStatus.initializing)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Top Controls: Back button and Help
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ControlButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    tooltip: l10n.back,
                  ),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: _narration.muted,
                    builder: (context, muted, _) {
                      return _ControlButton(
                        icon: muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onTap: () =>
                            unawaited(_narration.toggleMuted()),
                        tooltip: muted
                            ? l10n.arNarrationUnmute
                            : l10n.arNarrationMute,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    onTap: _restartScanning,
                    tooltip: l10n.arRescanTooltip,
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.help_outline_rounded,
                    onTap: _showHelp,
                    tooltip: l10n.arHelpTooltip,
                  ),
                ],
              ),
            ),
          ),

          // Center Reticle with Scan Line, hidden once a marker is recognized.
          if (_status == _ArScanStatus.searching ||
              _status == _ArScanStatus.initializing)
            Center(
              child: _ScanReticle(animation: _scanLineAnimation),
            ),

          // Bottom area: object info card when detected, otherwise a hint.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _detectedMarker != null &&
                        _status == _ArScanStatus.detected
                    ? (_detectedMarker!.id == ArMarkerId.ipAddress
                        ? ArLabPanel(
                            selectedDevice: _labSelectedDevice,
                            onSelect: (device) => setState(
                              () => _labSelectedDevice = device,
                            ),
                            onTestResult: _onLabTestResult,
                            onReset: _onLabReset,
                            onClose: _resumeScanning,
                          )
                        : _showDetail
                            ? ArObjectDetailPanel(
                                marker: _detectedMarker!,
                                onClose: () =>
                                    setState(() => _showDetail = false),
                              )
                            : _ObjectInfoCard(
                                marker: _detectedMarker!,
                                onClose: _resumeScanning,
                                onShowDetail: () =>
                                    setState(() => _showDetail = true),
                                onReplay: () {
                                  final ArNarrationClip clip =
                                      arNarrationForMarker(
                                    _detectedMarker!.id,
                                  )!;

                                  unawaited(
                                    _narration.replay(
                                      clip,
                                      language: _narrationLanguage,
                                    ),
                                  );
                                },
                              ))
                    : _StatusHint(
                        text: _statusLabel(l10n),
                        isError: _status == _ArScanStatus.failed,
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isLecturer
          ? LecturerBottomNavbar(currentIndex: widget.currentNavIndex)
          : StudentBottomNavbar(currentIndex: widget.currentNavIndex),
    );
  }
}

/// Localized object name for a recognized marker.
String _objectName(AppLocalizations l10n, ArMarkerId id) {
  switch (id) {
    case ArMarkerId.komputer:
      return l10n.arObjKomputerName;
    case ArMarkerId.switchDevice:
      return l10n.arObjSwitchName;
    case ArMarkerId.hub:
      return l10n.arObjHubName;
    case ArMarkerId.router:
      return l10n.arObjRouterName;
    case ArMarkerId.topologi:
      return l10n.arObjTopologiName;
    case ArMarkerId.ipAddress:
      return l10n.arObjIpAddressName;
  }
}

/// Localized learning description for a recognized marker.
String _objectDescription(AppLocalizations l10n, ArMarkerId id) {
  switch (id) {
    case ArMarkerId.komputer:
      return l10n.arObjKomputerDesc;
    case ArMarkerId.switchDevice:
      return l10n.arObjSwitchDesc;
    case ArMarkerId.hub:
      return l10n.arObjHubDesc;
    case ArMarkerId.router:
      return l10n.arObjRouterDesc;
    case ArMarkerId.topologi:
      return l10n.arObjTopologiDesc;
    case ArMarkerId.ipAddress:
      return l10n.arObjIpAddressDesc;
  }
}

/// Hint / status text shown at the bottom while no object card is visible.
class _StatusHint extends StatelessWidget {
  final String text;
  final bool isError;

  const _StatusHint({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.4,
            ),
      ),
    );
  }
}

/// Learning-info card shown after a marker is recognized.
///
/// Provides the object name, its module, a short description and a control to
/// hide the card and continue scanning (PRD object-information UI requirements).
class _ObjectInfoCard extends StatelessWidget {
  final ArMarker marker;
  final VoidCallback onClose;
  final VoidCallback onShowDetail;

  /// Plays the recorded object narration again. The card's own action area is
  /// the guaranteed affordance (the 3D tap path is disabled, AR-10), so the
  /// replay lives next to "View Full Information" rather than on the model.
  final VoidCallback onReplay;

  const _ObjectInfoCard({
    required this.marker,
    required this.onClose,
    required this.onShowDetail,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.arMarkerDetected,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _objectName(l10n, marker.id),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.arModuleBadge(marker.moduleNumber),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.close,
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _objectDescription(l10n, marker.id),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: Text(l10n.arNarrationReplay),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      // The only way into the detail panel: the 3D tap path is
                      // intentionally disabled (an approved AR-10 deviation)
                      // since the sparse ARCore feature points the plugin
                      // delivers made taps unreliable, so the summary card
                      // carries the guaranteed affordance.
                      onPressed: onShowDetail,
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: Text(l10n.arDetailOpenButton),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Control button for top bar (back, help)
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated scan reticle: four corner brackets around a moving scan line.
///
/// Drawn on top of the live camera feed, so the stroke is a fixed white with a
/// soft dark halo rather than a theme colour. A theme-dependent colour made the
/// reticle black in the default light theme, which vanished against a dark
/// scene and read as a rendering glitch.
class _ScanReticle extends StatelessWidget {
  final Animation<double> animation;

  const _ScanReticle({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _ReticlePainter(progress: animation.value),
        );
      },
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final double progress;

  _ReticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // CustomPaint's origin is its top-left. Move to the centre first so the
    // four corners form a symmetric frame — without this they were drawn
    // half a frame up-left of where they belong (the "four anomalies").
    canvas.translate(size.width / 2, size.height / 2);

    final double half = size.width / 2;
    const double inset = 4;
    const double cornerLength = 28;
    const double cornerRadius = 12;

    // Two passes: a soft dark halo first so the white bracket stays legible on
    // a bright camera frame, then the white bracket itself.
    final Paint halo = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 5.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // One canonical "opens down-right" bracket is rotated into each quadrant.
    // The rotation turns its arms inward: TL 0°, TR 90°, BR 180°, BL 270°.
    final List<(Offset, double)> corners = <(Offset, double)>[
      (Offset(-(half - inset), -(half - inset)), 0),
      (Offset(half - inset, -(half - inset)), 90),
      (Offset(half - inset, half - inset), 180),
      (Offset(-(half - inset), half - inset), 270),
    ];

    final Path path = _cornerPath(cornerLength, cornerRadius);
    for (final (Offset offset, double rotation) in corners) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(rotation * math.pi / 180);
      canvas.drawPath(path, halo);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }

    // Scan line sweeping top to bottom between the brackets, with a soft glow.
    final double scanY = -half + inset + (size.height - 2 * inset) * progress;
    final Offset scanStart = Offset(-half + inset + cornerLength + 8, scanY);
    final Offset scanEnd = Offset(half - inset - cornerLength - 8, scanY);

    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Paint scanPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(scanStart, scanEnd, glowPaint);
    canvas.drawLine(scanStart, scanEnd, scanPaint);
  }

  /// Canonical corner bracket: a rounded "L" whose two arms run along +x (right)
  /// and +y (down) away from the origin corner. A quadratic Bézier rounds the
  /// elbow without needing arc-sweep direction bookkeeping.
  Path _cornerPath(double length, double radius) {
    return Path()
      ..moveTo(length, 0)
      ..lineTo(radius, 0)
      ..quadraticBezierTo(0, 0, 0, radius)
      ..lineTo(0, length);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
