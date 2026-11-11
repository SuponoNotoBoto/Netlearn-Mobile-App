import 'dart:math' as math;

import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/widgets.dart' show Matrix4;

import 'ar_marker_catalog.dart';

/// Builds the AR scene node that displays [marker]'s 3D model, or `null` when
/// the marker has no single model to show.
///
/// [transformation] is the pose ARCore reports for the detected image, so the
/// model appears where the printed card sits. The matrix is column-major on
/// both sides (ARCore `pose.toMatrix` → `MatrixConverter.fromJson` →
/// `MatrixValueNotifierConverter.toJson`), so it is passed straight through.
///
/// The marker assets are GLB files in the Flutter asset folder, which the
/// plugin loads via [NodeType.localGLB] (`AndroidARView.kt` reads them with the
/// asset lookup key).
///
/// The node matrix is composed as `markerPose * T(-e * anchor) * S(finalScale)`
/// with `e = kArAndroidModelScaleFactor * finalScale`. The native renderer
/// multiplies the linear part by 0.33 but leaves the translation column alone,
/// so the anchor shift is baked in pre-scaled — the same convention the Modul 4
/// lab uses (`ar_lab_scene.dart`). Without the shift the model's bounding-box
/// centre would sit metres off the marker whenever the GLB was authored with an
/// offset origin (the Modul 1 PC, the star topology).
///
/// [maxModule] limits which modules are wired up yet, because the PRD stages the
/// work: Modul 1–3 (markers 1–5) are wired, and Modul 4 (marker 6) belongs to
/// Tahap 5. Modul 4's marker has no single GLB — its "simulation" is built in
/// Tahap 5 — so it stays null regardless of [maxModule]. Raise [maxModule] only
/// if a later module gains a single model of its own.
ARNode? arNodeForMarker(
  ArMarker marker, {
  Matrix4? transformation,
  int maxModule = 3,
}) {
  final String? path = marker.modelPath;
  if (path == null) return null;
  if (marker.moduleNumber > maxModule) return null;

  final Matrix4 matrix = transformation?.clone() ?? Matrix4.identity();
  final double scale = marker.finalScale;
  final List<double>? anchor = marker.anchor;
  if (anchor != null) {
    final double e = kArAndroidModelScaleFactor * scale;
    matrix.translateByDouble(
      -e * anchor[0],
      -e * anchor[1],
      -e * anchor[2],
      1.0,
    );
  }
  if (scale != 1.0) {
    matrix.scaleByDouble(
      scale,
      scale,
      scale,
      1.0,
    );
  }

  return ARNode(
    type: NodeType.localGLB,
    uri: path,
    name: 'ar_node_${marker.id.name}',
    transformation: matrix,
  );
}

/// Fraction of a Modul 1–3 model's on-device size used as the *fallback* tap
/// radius.
///
/// A tap counts as tapping the object when its distance from the model's
/// marker-anchored centre (measured in the card plane, see [arMarkerTappedAt])
/// is no more than the marker's own [ArMarker.tapRadius] in world metres, or —
/// when that is `null` — this fraction of the rendered size. Deliberately
/// generous (0.7): with planes and depth disabled the plugin only ever delivers
/// sparse feature-point hits (`AndroidARView.handleQueuedTap`), so a tight
/// radius makes the model untappable on device. Every Modul 1–3 marker now sets
/// an explicit [ArMarker.tapRadius] (0.50 m devices, 1.00 m topology), so this
/// constant only applies to markers without one.
const double kArObjectTapFraction = 0.7;

/// On-device size (metres) of [marker]'s largest dimension after the plugin's
/// native 0.33 factor and the marker's own [ArMarker.finalScale].
double arMarkerOnDeviceSize(ArMarker marker) =>
    kArAndroidModelScaleFactor * marker.finalScale * marker.nativeMaxDimension;

/// Whether a tapped world point (metres, from the ARCore hit test) counts as a
/// tap on [marker]'s model.
///
/// The anchor bake places the model's footprint centre (asset-space X/Z
/// bounding-box centre at the lowest Y) exactly at the marker pose origin. The
/// tap point is transformed into the marker's local frame and compared in the
/// **card plane** (the pose's X and Z axes): the pose's Y axis is the card
/// normal, so ignoring it keeps a tilted card from adding a false vertical
/// offset to an otherwise on-target tap. This mirrors `arLabDeviceAt` in
/// `ar_lab_scene.dart`: the plugin sends no `onNodeTap` on Android, so object
/// selection goes through the ARCore hit-test pose instead.
///
/// The radius is `threshold` (a test override) when given, else the marker's
/// explicit [ArMarker.tapRadius] in world metres, else the fraction-based
/// default `kArObjectTapFraction × [arMarkerOnDeviceSize]`. Modul 4 never
/// reaches this helper: the scanner routes its taps through `arLabDeviceAt`.
///
/// **Currently unwired:** the scanner's Modul 1–3 tap-to-open path is disabled
/// (an approved AR-10 deviation — the sparse feature-point hits proved
/// unreliable on device). The helper and its unit tests are kept in case the
/// tap path is ever re-enabled.
bool arMarkerTappedAt(
  ArMarker marker,
  Matrix4 markerPose,
  List<double> worldPoint, {
  double? threshold,
}) {
  final double radius = threshold ??
      marker.tapRadius ??
      kArObjectTapFraction * arMarkerOnDeviceSize(marker);
  final List<double> storage = markerPose.storage;
  // Rigid ARCore pose: the first three columns are the world directions of the
  // marker's local axes and the fourth is its position (column-major order).
  final double dx = worldPoint[0] - storage[12];
  final double dy = worldPoint[1] - storage[13];
  final double dz = worldPoint[2] - storage[14];
  final double localX =
      storage[0] * dx + storage[1] * dy + storage[2] * dz;
  final double localZ =
      storage[8] * dx + storage[9] * dy + storage[10] * dz;
  return math.sqrt(localX * localX + localZ * localZ) <= radius;
}

/// Whether any of [worldPoints] counts as a tap on [marker]'s model.
///
/// `onPlaneOrPointTap` delivers *every* plane/point hit along the tapped ray,
/// closest to the camera first; the point nearest the camera is not necessarily
/// the one nearest the marker (the plugin only has sparse feature points, since
/// planes and depth are disabled), so a match on any hit is far more
/// predictable on device than `hits.first` alone.
bool arMarkerTappedAtAny(
  ArMarker marker,
  Matrix4 markerPose,
  List<List<double>> worldPoints, {
  double? threshold,
}) {
  for (final List<double> point in worldPoints) {
    if (arMarkerTappedAt(marker, markerPose, point, threshold: threshold)) {
      return true;
    }
  }
  return false;
}
