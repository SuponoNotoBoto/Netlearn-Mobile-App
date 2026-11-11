import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/widgets.dart' show Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_marker_catalog.dart';
import 'package:netlearn/features/ar/ar_node_factory.dart';

// The AR stages wire one module's models at a time. These tests pin the
// marker→model decision down offline (no camera, no platform channel): each
// wired marker must load its own GLB, the Modul 4 marker must not invent a
// model, and the detected pose must place the node. This is the guard that a
// future catalog edit cannot silently swap the router's model for the switch's.
void main() {
  ArMarker marker(ArMarkerId id) =>
      arMarkerCatalog.firstWhere((m) => m.id == id);

  group('arNodeForMarker', () {
    test('loads the computer GLB for the Modul 1 marker', () {
      final ARNode? node = arNodeForMarker(marker(ArMarkerId.komputer));
      expect(node, isNotNull);
      expect(node!.type, NodeType.localGLB);
      expect(node.uri, 'assets/3D/pc_2.glb');
    });

    test('loads each Modul 2 device GLB from its own marker', () {
      expect(arNodeForMarker(marker(ArMarkerId.switchDevice))?.uri,
          'assets/3D/switch.glb');
      expect(arNodeForMarker(marker(ArMarkerId.hub))?.uri, 'assets/3D/hub.glb');
      expect(arNodeForMarker(marker(ArMarkerId.router))?.uri,
          'assets/3D/router.glb');
    });

    test('never reuses another marker model (router must not load switch)',
        () {
      final ARNode? router = arNodeForMarker(marker(ArMarkerId.router));
      expect(router?.uri, isNot('assets/3D/switch.glb'));
      expect(router?.uri, contains('router'));
    });

    test('returns null for the Modul 4 marker (no single GLB)', () {
      expect(arNodeForMarker(marker(ArMarkerId.ipAddress)), isNull);
    });

    test('loads the Modul 3 topology model by default (Tahap 4)', () {
      // Modul 3 (marker 5) is wired; only Modul 4 still has no single model.
      expect(
        arNodeForMarker(marker(ArMarkerId.topologi))?.uri,
        'assets/3D/topologi_star.glb',
      );
    });

    test('places the node at the detected pose, centred on the marker', () {
      final Matrix4 transform = Matrix4.translationValues(1.5, -2.0, 3.25);
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final ARNode? node = arNodeForMarker(komputer, transformation: transform);
      // The anchor shift is baked in pre-scaled (the native 0.33 factor scales
      // only the linear part, never the translation column), so the node lands
      // at pose - e * anchor instead of raw pose.
      final List<double> anchor = komputer.anchor!;
      final double e = kArAndroidModelScaleFactor * komputer.finalScale;
      final t = node!.transform.getTranslation();

      expect(t.x, closeTo(1.5 - e * anchor[0], 1e-5));
      expect(t.y, closeTo(-2.0 - e * anchor[1], 1e-5));
      expect(t.z, closeTo(3.25 - e * anchor[2], 1e-5));
    });

    test('centres the model so its bounding-box anchor sits on the marker', () {
      // The Modul 1 PC's origin is at its corner (~0.28 units of +X), which
      // used to place it ~40 cm off the side of the card. The anchor must pull
      // it back over the marker without touching the linear (scale/rotation)
      // part.
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final ARNode node = arNodeForMarker(komputer)!;
      final List<double> anchor = komputer.anchor!;
      final double e = kArAndroidModelScaleFactor * komputer.finalScale;
      final t = node.transform.getTranslation();

      expect(t.x, closeTo(-e * anchor[0], 1e-6));
      expect(t.y, closeTo(-e * anchor[1], 1e-6));
      expect(t.z, closeTo(-e * anchor[2], 1e-6));
      expect(node.transform.getMaxScaleOnAxis(),
          closeTo(komputer.finalScale, 1e-6));
    });

    test('applies the display scale on top of normalization', () {
      // Each marker's tuning knob multiplies the normalization scale; with no
      // pose the node's linear part is exactly the final scale.
      for (final ArMarker m in arMarkerCatalog) {
        final ARNode? node = arNodeForMarker(m);
        if (node == null) continue; // Modul 4 has no single model.
        expect(
          node.transform.getMaxScaleOnAxis(),
          closeTo(m.finalScale, 1e-6),
        );
        expect(m.finalScale, closeTo(m.modelScale * m.displayScale, 1e-12));
      }
    });

    test('normalizes the switch smaller and the router larger', () {
      // The raw GLBs differ by orders of magnitude; the factory must apply the
      // catalog's per-model scale (normalization + display tuning) so both
      // render at the user-approved size.
      final ARNode switchNode = arNodeForMarker(marker(ArMarkerId.switchDevice))!;
      final ARNode routerNode = arNodeForMarker(marker(ArMarkerId.router))!;

      expect(switchNode.transform.getMaxScaleOnAxis(), lessThan(0.1));
      expect(routerNode.transform.getMaxScaleOnAxis(), greaterThan(1.0));
    });

    test('does not mutate the caller transformation matrix', () {
      final Matrix4 transform = Matrix4.translationValues(4.0, 5.0, 6.0);
      arNodeForMarker(marker(ArMarkerId.komputer), transformation: transform);
      final t = transform.getTranslation();
      expect(t.x, closeTo(4.0, 1e-6));
      expect(t.y, closeTo(5.0, 1e-6));
      expect(t.z, closeTo(6.0, 1e-6));
    });

    test('gives each marker a distinct node name', () {
      final Set<String> names = <String>{};
      for (final ArMarker m in arMarkerCatalog) {
        final ARNode? node = arNodeForMarker(m, maxModule: 4);
        if (node != null) names.add(node.name);
      }
      expect(names, hasLength(names.length));
    });
  });

  group('arMarkerOnDeviceSize', () {
    test('is the plugin-scaled largest dimension of the model', () {
      // The native 0.33 factor (kArAndroidModelScaleFactor) applies to the
      // linear part only, so the rendered size is 0.33 * finalScale *
      // nativeMaxDimension — that is what the tap radius derives from.
      final ArMarker komputer = marker(ArMarkerId.komputer);
      expect(
        arMarkerOnDeviceSize(komputer),
        closeTo(0.33 * komputer.finalScale * komputer.nativeMaxDimension, 1e-9),
      );
      expect(arMarkerOnDeviceSize(komputer), closeTo(0.44, 0.01));
    });

    test('grows with the model, so the topology tap area is the widest', () {
      // The star topology renders ~1 m across, the single devices ~0.4 m, so
      // its tap area must be wider or edge taps would be missed.
      expect(
        arMarkerOnDeviceSize(marker(ArMarkerId.topologi)),
        greaterThan(arMarkerOnDeviceSize(marker(ArMarkerId.komputer))),
      );
      expect(
        arMarkerOnDeviceSize(marker(ArMarkerId.hub)),
        closeTo(arMarkerOnDeviceSize(marker(ArMarkerId.switchDevice)), 1e-9),
      );
    });
  });

  group('arMarkerTappedAt', () {
    test('accepts a tap exactly at the model centre (pose origin)', () {
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      expect(arMarkerTappedAt(komputer, pose, <double>[0.0, 0.0, 0.0]), isTrue);
    });

    test('rejects a tap far from the model (empty-area tap)', () {
      // 1 m away is double the computer's explicit 0.50 m tap radius.
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      expect(arMarkerTappedAt(komputer, pose, <double>[1.0, 0.0, 0.0]), isFalse);
      expect(arMarkerTappedAt(komputer, pose, <double>[-1.0, 0.0, 0.0]), isFalse);
    });

    test('accepts a tap just inside the marker radius and rejects just outside',
        () {
      // Router boundary test: the effective radius is the marker's explicit
      // 0.50 m tapRadius, which is larger than the old fraction-based default
      // (0.7 × ~0.38 m) — that widening is exactly what makes taps through the
      // tall model body register on device.
      final ArMarker router = marker(ArMarkerId.router);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      final double radius = router.tapRadius!;
      expect(
        radius,
        greaterThan(kArObjectTapFraction * arMarkerOnDeviceSize(router)),
      );
      expect(
        arMarkerTappedAt(router, pose, <double>[radius * 0.999, 0.0, 0.0]),
        isTrue,
      );
      expect(
        arMarkerTappedAt(router, pose, <double>[radius * 1.001, 0.0, 0.0]),
        isFalse,
      );
    });

    test('falls back to the fraction-based radius when tapRadius is not set',
        () {
      // Markers without an explicit tapRadius keep the historical default:
      // 0.7 × on-device size. This is what protects a future catalog entry from
      // accidentally becoming untappable the moment it forgets the field.
      const ArMarker synthetic = ArMarker(
        id: ArMarkerId.komputer,
        imageName: 'synthetic_no_radius',
        moduleNumber: 1,
        modelPath: 'assets/3D/pc_2.glb',
        nativeMaxDimension: 0.4568,
        displayScale: 0.70,
      );
      expect(synthetic.tapRadius, isNull);
      final double radius =
          kArObjectTapFraction * arMarkerOnDeviceSize(synthetic);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      expect(
        arMarkerTappedAt(synthetic, pose, <double>[radius * 0.999, 0.0, 0.0]),
        isTrue,
      );
      expect(
        arMarkerTappedAt(synthetic, pose, <double>[radius * 1.001, 0.0, 0.0]),
        isFalse,
      );
    });

    test('interprets tapRadius as world metres, at any pose position', () {
      // The radius is a real-world distance in the AR session space: 0.49 m
      // accepts, 0.51 m rejects, at a pose shifted far from the world origin —
      // the same numbers whether the GLB is authored in 0.27-unit (router) or
      // 33-unit (switch) space.
      final ArMarker komputer = marker(ArMarkerId.komputer);
      expect(komputer.tapRadius, closeTo(0.50, 1e-9));
      final Matrix4 pose = Matrix4.translationValues(1.5, -2.0, 3.25);
      expect(
        arMarkerTappedAt(
          komputer,
          pose,
          <double>[1.5 + 0.49, -2.0, 3.25],
        ),
        isTrue,
      );
      expect(
        arMarkerTappedAt(
          komputer,
          pose,
          <double>[1.5 + 0.51, -2.0, 3.25],
        ),
        isFalse,
      );
    });

    test('works at any pose position, not only the world origin', () {
      final Matrix4 pose = Matrix4.translationValues(1.5, -2.0, 3.25);
      final ArMarker komputer = marker(ArMarkerId.komputer);
      expect(
        arMarkerTappedAt(komputer, pose, <double>[1.5, -2.0, 3.25]),
        isTrue,
      );
      expect(
        arMarkerTappedAt(komputer, pose, <double>[2.5, -2.0, 3.25]),
        isFalse,
      );
    });

    test('compares against the marker pose, not the baked node offset', () {
      // The node matrix carries the pre-scaled anchor shift in its translation
      // column, so the node centre is NOT the pose origin. The tap radius must
      // be centred on the pose, which is where the anchor bake places the
      // model's footprint.
      final Matrix4 pose = Matrix4.translationValues(1.5, -2.0, 3.25);
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final ARNode node = arNodeForMarker(komputer, transformation: pose)!;
      final t = node.transform.getTranslation();
      expect(t.x, isNot(closeTo(1.5, 1e-3)));
      expect(arMarkerTappedAt(komputer, pose, <double>[1.5, -2.0, 3.25]), isTrue);
    });

    test('ignores the card-normal axis, so a tilted card still registers', () {
      // The card tilted 45° back: a tap that lands straight "above" the card
      // centre (along its rotated normal) is 0.1 m away in raw 3D world space
      // but sits exactly on the card plane in the marker's local frame. The
      // old Euclidean metric rejected it; the card-plane metric accepts it.
      final Matrix4 pose = Matrix4.rotationX(0.7853981633974483);
      pose.translateByDouble(1.5, -2.0, 3.25, 1.0);
      final ArMarker komputer = marker(ArMarkerId.komputer);
      // Local Y axis (card normal) in world = rotation column 1; read the
      // actual pose centre from the matrix instead of assuming the translation
      // argument (translateByDouble composes through the rotation).
      final double nx = pose.storage[4];
      final double ny = pose.storage[5];
      final double nz = pose.storage[6];
      final List<double> aboveCard = <double>[
        pose.storage[12] + 0.1 * nx,
        pose.storage[13] + 0.1 * ny,
        pose.storage[14] + 0.1 * nz,
      ];
      expect(
        arMarkerTappedAt(komputer, pose, aboveCard),
        isTrue,
      );
      // With a flat pose the card normal is world-Y, so an offset straight
      // above the card is ignored entirely — only the card-plane projection
      // decides.
      expect(
        arMarkerTappedAt(
          komputer,
          Matrix4.translationValues(0.0, 0.0, 0.0),
          <double>[0.0, 10.0, 0.0],
        ),
        isTrue,
      );
    });

    test('an explicit threshold overrides the marker tapRadius', () {
      // The threshold parameter is the tester's override and wins over both the
      // per-marker radius and the fraction-based default: komputer's tapRadius
      // is 0.50, but a 0.6 threshold still accepts 0.5 and rejects 0.7.
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      expect(
        arMarkerTappedAt(komputer, pose, <double>[0.5, 0.0, 0.0],
            threshold: 0.6),
        isTrue,
      );
      expect(
        arMarkerTappedAt(komputer, pose, <double>[0.7, 0.0, 0.0],
            threshold: 0.6),
        isFalse,
      );
    });
  });

  group('arMarkerTappedAtAny', () {
    test('matches when any delivered hit is near the model', () {
      // onPlaneOrPointTap sends every point hit along the tapped ray, nearest
      // to the camera first. The nearest one can be far from the marker while
      // a deeper one sits on the card, so any-hit matching is what makes the
      // object tappable in practice.
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      expect(
        arMarkerTappedAtAny(komputer, pose, <List<double>>[
          <double>[0.9, 0.0, 0.0], // Stray point, outside the radius.
          <double>[0.05, 0.0, 0.0], // On the card.
        ]),
        isTrue,
      );
    });

    test('rejects when no delivered hit is near the model', () {
      final ArMarker komputer = marker(ArMarkerId.komputer);
      final Matrix4 pose = Matrix4.translationValues(0.0, 0.0, 0.0);
      expect(
        arMarkerTappedAtAny(komputer, pose, <List<double>>[
          <double>[0.9, 0.0, 0.0],
          <double>[1.2, 1.2, 1.2],
        ]),
        isFalse,
      );
      expect(arMarkerTappedAtAny(komputer, pose, <List<double>>[]), isFalse);
    });
  });
}
