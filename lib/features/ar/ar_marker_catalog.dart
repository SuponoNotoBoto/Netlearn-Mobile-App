import 'package:flutter/foundation.dart';

/// Logical identity of each AR marker, in PRD marker-number order.
///
/// `switch` is a reserved word in Dart, so the Modul 2 switch marker uses
/// [switchDevice]. The rest match the object they represent.
enum ArMarkerId {
  komputer,
  switchDevice,
  hub,
  router,
  topologi,
  ipAddress,
}

/// Reference size, in the model's own world-space units, that every marker's
/// GLB is normalized to.
///
/// The five GLBs were authored in wildly different units (the switch spans
/// ~33 units, the router ~0.27), so displaying them unchanged made the switch
/// a ~11 m slab and the router a ~9 cm speck. The hub happened to render at the
/// size the user approved on device (after a later on-device pass every Modul 2
/// device was tuned *down* with [ArMarker.displayScale], and the topology up),
/// so its measured largest extent (1.903 world units) is still the
/// normalization target. `modelScale` divides this by each model's
/// [ArMarker.nativeMaxDimension].
const double kArReferenceModelDimension = 1.903;

/// The plugin's global per-model scale applied natively on Android
/// (`AndroidARView.kt` local-space load): every node matrix's linear part is
/// multiplied by this factor, while its translation column is left alone. All
/// size math in this feature divides by it to reach the intended real-world
/// size — both the single-model nodes (`ar_node_factory.dart`) and the Modul 4
/// lab scene (`ar_lab_scene.dart`) bake the already-scaled offsets into the
/// node translation.
const double kArAndroidModelScaleFactor = 0.33;

/// A single marker-to-content mapping.
///
/// This is a pure data table on purpose: the scanner only needs the tracking
/// image asset (what the plugin registers and reports back) plus, from the model
/// stage on, the GLB path. Keeping it free of widgets, l10n and Supabase lets a
/// unit test assert the whole mapping offline — the PRD requires that scanning
/// the router marker must never surface the switch object.
@immutable
class ArMarker {
  const ArMarker({
    required this.id,
    required this.imageName,
    required this.moduleNumber,
    required this.modelPath,
    required this.nativeMaxDimension,
    this.displayScale = 1.0,
    this.anchor,
    this.tapRadius,
  });

  /// Which object/module this marker belongs to.
  final ArMarkerId id;

  /// Tracking name reported by `onImageDetected`.
  ///
  /// The native side derives it from the asset file name without extension
  /// (`substringAfterLast('/')` then `substringBeforeLast('.')` in
  /// AndroidARView.kt), so it must stay in sync with [assetPath].
  final String imageName;

  /// 1-based module number from the PRD marker table (1..4).
  final int moduleNumber;

  /// GLB path used by the model stage. Modul 4 is a fixed two-PC/one-switch
  /// simulation with no single combined model, so it stays `null`.
  final String? modelPath;

  /// Largest extent of the model in its own world-space units, measured by
  /// composing each GLB's node transforms (the raw vertex bounds are misleading
  /// because the node matrices carry hidden ×100 / ×0.01 scales). Used only to
  /// derive [modelScale]; see [kArReferenceModelDimension].
  final double nativeMaxDimension;

  /// Per-marker display-size multiplier over [modelScale].
  ///
  /// Normalizing every model to one reference size was wrong for the classroom:
  /// on device a ~0.63 m computer was too big, all Modul 2 devices forced the
  /// student to step back, and the star-topology scene read as too small. This
  /// is the one-knob-per-marker correction (see the catalog values) — on-device
  /// tuning means editing one number here, nothing else.
  final double displayScale;

  /// Asset-space point that is placed at the marker origin: the bounding-box
  /// centre in X/Z and the lowest Y, so the model sits centred on the card and
  /// rests on the marker plane (same anchor convention as the Modul 4 lab in
  /// `ar_lab_scene.dart`).
  ///
  /// Measured from each GLB with the node transforms composed. Most models were
  /// authored with the mesh offset away from the origin — the Modul 1 PC sits
  /// ~0.28 units in +X, which after normalization placed it ~40 cm off the side
  /// of the marker ("tidak center di markernya"). `null` only for Modul 4,
  /// which has no single model.
  final List<double>? anchor;

  /// Tap radius around the marker-anchored centre, in **world metres**, that
  /// counts as a tap on this model (AR-10).
  ///
  /// The plugin delivers only sparse ARCore feature-point hits (planes and
  /// depth are disabled) and a tap through a tall model's body lands on the
  /// surface *behind* the card, so a generous per-marker radius is what makes
  /// the object tappable on device. It is a real-world distance in the AR
  /// session's coordinate space, not a screen-pixel or model-unit value — the
  /// switch GLB is authored in ~33-unit space, so 0.50 is unmistakably metres.
  ///
  /// `null` (the default) keeps `ar_node_factory.dart`'s fallback radius of
  /// `kArObjectTapFraction × on-device size`. All Modul 1–3 markers carry an
  /// explicit value tuned in the catalog; Modul 4 (`ipAddress`) leaves it
  /// `null` on purpose because its PC selection is the separate `arLabDeviceAt`
  /// path and must not pick up a Modul 1–3 style radius.
  ///
  /// **Currently unwired:** the scanner's Modul 1–3 tap-to-open path is
  /// disabled (an approved AR-10 deviation), so this value is only read by
  /// `ar_node_factory.dart`'s matching helpers and their unit tests; it is kept
  /// for a possible re-enable.
  final double? tapRadius;

  /// Per-model scale that normalizes the model to [kArReferenceModelDimension].
  ///
  /// The plugin already multiplies every node by its own global scale factor
  /// (0.33 on Android), and our scale is composed on top of it, so this value is
  /// purely the *relative* correction between models.
  double get modelScale => kArReferenceModelDimension / nativeMaxDimension;

  /// Scale actually applied on device: the normalization correction tuned by
  /// [displayScale]. The node factory renders the model at this size.
  double get finalScale => modelScale * displayScale;

  /// Flutter asset path handed to the AR session for image tracking.
  String get assetPath => 'assets/ar/markers/$imageName.png';
}

/// The six markers from `AR_PRD.md`. Access Point is intentionally absent.
///
/// [displayScale] values are the current on-device tuning (Modul 1–2 smaller,
/// Modul 3 larger), [anchor] values are measured bounding-box anchors, and
/// [ArMarker.tapRadius] values are the AR-10 tap radii in world metres (kept
/// though the tap path is currently disabled); all three are cheap to re-tune
/// after the next device pass.
const List<ArMarker> arMarkerCatalog = <ArMarker>[
  ArMarker(
    id: ArMarkerId.komputer,
    imageName: 'marker_01_komputer',
    moduleNumber: 1,
    modelPath: 'assets/3D/pc_2.glb',
    nativeMaxDimension: 0.4568,
    displayScale: 0.70,
    tapRadius: 0.50,
    anchor: <double>[0.28219, 0.02622, 0.08193],
  ),
  ArMarker(
    id: ArMarkerId.switchDevice,
    imageName: 'marker_02_switch',
    moduleNumber: 2,
    modelPath: 'assets/3D/switch.glb',
    nativeMaxDimension: 33.000,
    displayScale: 0.60,
    tapRadius: 0.50,
    anchor: <double>[0.0, -2.1596, 3.0093],
  ),
  ArMarker(
    id: ArMarkerId.hub,
    imageName: 'marker_03_hub',
    moduleNumber: 2,
    modelPath: 'assets/3D/hub.glb',
    nativeMaxDimension: 1.903,
    displayScale: 0.60,
    tapRadius: 0.50,
    anchor: <double>[-0.00053, -0.19621, -0.0052],
  ),
  ArMarker(
    id: ArMarkerId.router,
    imageName: 'marker_04_router',
    moduleNumber: 2,
    modelPath: 'assets/3D/router.glb',
    nativeMaxDimension: 0.273,
    displayScale: 0.60,
    tapRadius: 0.50,
    anchor: <double>[0.0, -0.00051, 0.01114],
  ),
  ArMarker(
    id: ArMarkerId.topologi,
    imageName: 'marker_05_topologi',
    moduleNumber: 3,
    modelPath: 'assets/3D/topologi_star.glb',
    nativeMaxDimension: 256.060,
    displayScale: 1.70,
    tapRadius: 1.00,
    anchor: <double>[91.46481, -1.31913, -13.75666],
  ),
  ArMarker(
    id: ArMarkerId.ipAddress,
    imageName: 'marker_06_ipaddress',
    moduleNumber: 4,
    modelPath: null,
    nativeMaxDimension: 1.0,
  ),
];

/// Tracking image asset paths, in catalog order, ready for `onInitialize`.
List<String> get arMarkerAssetPaths =>
    arMarkerCatalog.map((marker) => marker.assetPath).toList(growable: false);

/// Looks up a marker by the tracking name emitted by the plugin.
///
/// Returns `null` for an image the catalog does not own, which is how an
/// unrelated marker is ignored instead of surfacing a wrong object.
ArMarker? arMarkerByImageName(String imageName) {
  for (final marker in arMarkerCatalog) {
    if (marker.imageName == imageName) return marker;
  }
  return null;
}
