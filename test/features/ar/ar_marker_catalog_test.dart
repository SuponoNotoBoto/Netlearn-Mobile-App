import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_marker_catalog.dart';
import 'package:netlearn/features/ar/ar_node_factory.dart';

// The PRD requires that each marker maps to the correct object and module and
// that markers never swap objects (scanning the router marker must not surface
// the switch). These assertions pin that mapping down offline — no camera, no
// Supabase — so a future edit to the catalog cannot silently mis-wire it.
void main() {
  group('arMarkerCatalog', () {
    test('has exactly six markers for four modules', () {
      expect(arMarkerCatalog, hasLength(6));
      expect(arMarkerCatalog.map((m) => m.id).toSet(), hasLength(6));
    });

    test('does not contain an Access Point marker', () {
      // Access Point was removed from the AR scope; guard against reintroducing
      // it through the catalog file name.
      final names = arMarkerCatalog.map((m) => m.imageName.toLowerCase());
      expect(names.any((n) => n.contains('access')), isFalse);
      expect(names.any((n) => n.contains('access_point')), isFalse);
    });

    test('maps each marker to its PRD module and object/model', () {
      ArMarker byId(ArMarkerId id) =>
          arMarkerCatalog.firstWhere((m) => m.id == id);

      expect(byId(ArMarkerId.komputer).moduleNumber, 1);
      expect(byId(ArMarkerId.komputer).modelPath, 'assets/3D/pc_2.glb');

      expect(byId(ArMarkerId.switchDevice).moduleNumber, 2);
      expect(byId(ArMarkerId.switchDevice).modelPath, 'assets/3D/switch.glb');

      expect(byId(ArMarkerId.hub).moduleNumber, 2);
      expect(byId(ArMarkerId.hub).modelPath, 'assets/3D/hub.glb');

      expect(byId(ArMarkerId.router).moduleNumber, 2);
      expect(byId(ArMarkerId.router).modelPath, 'assets/3D/router.glb');

      expect(byId(ArMarkerId.topologi).moduleNumber, 3);
      expect(byId(ArMarkerId.topologi).modelPath, 'assets/3D/topologi_star.glb');

      // Modul 4 is a fixed simulation; no single combined model is loaded.
      expect(byId(ArMarkerId.ipAddress).moduleNumber, 4);
      expect(byId(ArMarkerId.ipAddress).modelPath, isNull);
    });

    test('never reuses an object: every model path is distinct', () {
      final paths = arMarkerCatalog
          .map((m) => m.modelPath)
          .whereType<String>()
          .toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('image names and asset paths are unique and consistent', () {
      final names = arMarkerCatalog.map((m) => m.imageName).toSet();
      expect(names, hasLength(arMarkerCatalog.length));

      for (final marker in arMarkerCatalog) {
        expect(marker.assetPath, 'assets/ar/markers/${marker.imageName}.png');
        // The plugin reports the file name without extension, so imageName must
        // not itself carry a suffix.
        expect(marker.imageName.endsWith('.png'), isFalse);
      }
      expect(
        arMarkerAssetPaths,
        arMarkerCatalog.map((m) => m.assetPath).toList(),
      );
    });

    test('module numbers stay within the four supported modules', () {
      for (final marker in arMarkerCatalog) {
        expect(marker.moduleNumber, inInclusiveRange(1, 4));
      }
    });

    test('normalizes every model to the reference dimension', () {
      ArMarker byId(ArMarkerId id) =>
          arMarkerCatalog.firstWhere((m) => m.id == id);

      // The hub was the size approved on device, so it is the 1.0 reference.
      expect(byId(ArMarkerId.hub).modelScale, closeTo(1.0, 1e-9));

      // The switch was a ~11 m slab and the router a ~9 cm speck: their scales
      // must shrink and grow respectively, not stay at 1.0.
      expect(byId(ArMarkerId.switchDevice).modelScale, lessThan(0.1));
      expect(byId(ArMarkerId.router).modelScale, greaterThan(1.0));

      // The topology scene spans ~256 units, so its correction is tiny too.
      expect(byId(ArMarkerId.topologi).modelScale, lessThan(0.1));

      // Every scale must be a usable positive factor.
      for (final marker in arMarkerCatalog) {
        expect(marker.modelScale.isFinite, isTrue);
        expect(marker.modelScale, greaterThan(0));
      }
    });

    test('carries a per-marker display tuning on top of normalization', () {
      // On-device pass: Modul 1–2 render smaller than the reference so the
      // student stops stepping back, Modul 3 larger so the topology reads. The
      // exact numbers are tuning that may move again, so only the intent is
      // pinned here.
      ArMarker byId(ArMarkerId id) =>
          arMarkerCatalog.firstWhere((m) => m.id == id);

      expect(byId(ArMarkerId.komputer).displayScale, lessThan(1.0));
      expect(byId(ArMarkerId.switchDevice).displayScale, lessThan(1.0));
      expect(byId(ArMarkerId.hub).displayScale, lessThan(1.0));
      expect(byId(ArMarkerId.router).displayScale, lessThan(1.0));
      expect(byId(ArMarkerId.topologi).displayScale, greaterThan(1.0));

      for (final marker in arMarkerCatalog) {
        expect(marker.displayScale.isFinite, isTrue);
        expect(marker.displayScale, greaterThan(0));
        expect(marker.finalScale.isFinite, isTrue);
        expect(marker.finalScale, greaterThan(0));
      }
    });

    test('carries a per-marker tap radius, in world metres', () {
      ArMarker byId(ArMarkerId id) =>
          arMarkerCatalog.firstWhere((m) => m.id == id);

      // On-device the single devices render ~0.4 m and the topology ~1 m; the
      // radii below are world/meter distances centred on the marker pose (where
      // the anchor bake places the model's footprint). They must cover a tap
      // through the tall model body, whose ray lands on the surface *behind*
      // the card, plus a margin for the sparse ARCore feature points.
      expect(byId(ArMarkerId.komputer).tapRadius, closeTo(0.50, 1e-9));
      expect(byId(ArMarkerId.switchDevice).tapRadius, closeTo(0.50, 1e-9));
      expect(byId(ArMarkerId.hub).tapRadius, closeTo(0.50, 1e-9));
      expect(byId(ArMarkerId.router).tapRadius, closeTo(0.50, 1e-9));
      expect(byId(ArMarkerId.topologi).tapRadius, closeTo(1.00, 1e-9));

      for (final marker in arMarkerCatalog) {
        final double? radius = marker.tapRadius;
        if (radius == null) continue;
        expect(radius.isFinite, isTrue);
        expect(radius, greaterThan(0));
        // Metres, not model units: the radius stays close to the marker's own
        // on-device size. The switch GLB is authored in ~33-unit space, so a
        // radius of 0.50 can only be a real-world value.
        expect(radius, greaterThan(arMarkerOnDeviceSize(marker) * 0.5));
        expect(radius, lessThan(arMarkerOnDeviceSize(marker) * 2.0));
      }
    });

    test('Modul 4 keeps no tap radius (the lab uses its own matching)', () {
      // Modul 4's PC selection is the separate arLabDeviceAt path against the
      // lab device centres; it must not pick up a Modul 1–3 style tap radius.
      expect(
        arMarkerCatalog
            .firstWhere((m) => m.id == ArMarkerId.ipAddress)
            .tapRadius,
        isNull,
      );
    });

    test('anchors every model over the marker origin', () {
      ArMarker byId(ArMarkerId id) =>
          arMarkerCatalog.firstWhere((m) => m.id == id);

      // The hub was exported centred at the origin; the others were not (the
      // Modul 1 PC's mesh sits ~0.28 units in +X, which is exactly the
      // "object not centred on the marker" the user reported).
      final List<double> hubAnchor = byId(ArMarkerId.hub).anchor!;
      expect(hubAnchor[0].abs(), lessThan(0.01));
      expect(hubAnchor[2].abs(), lessThan(0.01));
      expect(byId(ArMarkerId.komputer).anchor![0], greaterThan(0.2));
      expect(byId(ArMarkerId.topologi).anchor![0].abs(), greaterThan(50));

      // Every marker that loads a model must carry a usable 3-component anchor.
      for (final marker in arMarkerCatalog) {
        if (marker.modelPath == null) {
          expect(marker.anchor, isNull); // Modul 4 has no single model.
        } else {
          expect(marker.anchor, isNotNull);
          expect(marker.anchor, hasLength(3));
          for (final v in marker.anchor!) {
            expect(v.isFinite, isTrue);
          }
        }
      }
    });
  });

  group('arMarkerByImageName', () {
    test('resolves every catalog marker by its tracking name', () {
      for (final marker in arMarkerCatalog) {
        expect(arMarkerByImageName(marker.imageName)?.id, marker.id);
      }
    });

    test('returns null for an unknown or foreign marker', () {
      expect(arMarkerByImageName('marker_99_unknown'), isNull);
      expect(arMarkerByImageName(''), isNull);
      expect(arMarkerByImageName('marker_01_komputer.png'), isNull);
    });
  });
}
