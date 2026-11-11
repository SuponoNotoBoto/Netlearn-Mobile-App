import 'dart:math' as math;

import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/widgets.dart' show Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_lab_layout.dart';
import 'package:netlearn/features/ar/ar_lab_scene.dart';
import 'package:netlearn/features/ar/ar_marker_catalog.dart'
    show kArAndroidModelScaleFactor;

// The Modul 4 lab is one assembled GLB placed relative to the marker pose, plus
// a packet the scanner animates along the cables baked into that model. These
// tests pin that geometry down offline (no camera, no native channel): the lab
// loads as a single node, it is scaled/anchored by the generated layout, the
// packet follows the cable polyline from Computer A to Computer B, and taps
// select the right computer. A future tweak to the layout or the packed path
// cannot silently detach the lab from its cables.

List<double> _anchor() => <double>[
      (kArLabBoundsMin[0] + kArLabBoundsMax[0]) / 2,
      kArLabBoundsMin[1],
      (kArLabBoundsMin[2] + kArLabBoundsMax[2]) / 2,
    ];

double _nativeWidth() => kArLabBoundsMax[0] - kArLabBoundsMin[0];

void main() {
  group('arLabStaticNodes', () {
    test('loads the whole lab as a single node', () {
      final List<ARNode> nodes = arLabStaticNodes(Matrix4.identity());
      expect(nodes, hasLength(1));
      expect(nodes.single.name, kArLabNodeScene);
      expect(nodes.single.uri, kArLabSceneAsset);
      expect(nodes.single.type, NodeType.localGLB);
    });

    test('scales the lab so its native X span hits the target width', () {
      final ARNode lab = arLabStaticNodes(Matrix4.identity()).single;
      final double nodeScale = lab.transform.storage[0];
      // native extent * 0.33 native factor * node scale must hit the target.
      expect(
        nodeScale * kArAndroidModelScaleFactor * _nativeWidth(),
        closeTo(kArLabSceneTargetWidth, 1e-9),
      );
    });

    test('anchors the lab centre over the marker and rests it on the plane', () {
      final ARNode lab = arLabStaticNodes(Matrix4.identity()).single;
      final double nodeScale = lab.transform.storage[0];
      final double e = kArAndroidModelScaleFactor * nodeScale;
      final List<double> anchor = _anchor();
      final List<double> t = _translation(lab.transform);

      // The anchor point maps to the marker origin: translation = -e * anchor.
      for (int i = 0; i < 3; i++) {
        expect(t[i], closeTo(-e * anchor[i], 1e-6));
      }
      // The anchor's Y is the model's lowest point, so the lab rests on the
      // marker plane instead of sinking half-through it.
      expect(anchor[1], closeTo(kArLabBoundsMin[1], 1e-9));
    });

    test('follows the marker pose and does not mutate it', () {
      final Matrix4 pose = Matrix4.translationValues(1.5, -2.0, 3.25);
      final ARNode lab = arLabStaticNodes(pose).single;
      final List<double> expected =
          _translation(arLabStaticNodes(Matrix4.identity()).single.transform);
      final List<double> t = _translation(lab.transform);
      final p = pose.getTranslation();

      expect(t[0], closeTo(expected[0] + p.x, 1e-6));
      expect(t[1], closeTo(expected[1] + p.y, 1e-6));
      expect(t[2], closeTo(expected[2] + p.z, 1e-6));

      final Matrix4 unchanged = Matrix4.translationValues(4.0, 5.0, 6.0);
      arLabStaticNodes(unchanged);
      final tv = unchanged.getTranslation();
      expect(tv.x, closeTo(4.0, 1e-6));
      expect(tv.y, closeTo(5.0, 1e-6));
      expect(tv.z, closeTo(6.0, 1e-6));
    });
  });

  group('packet path', () {
    test('starts at Computer A and ends at Computer B', () {
      final Matrix4 pose = Matrix4.identity();
      expect(arLabDeviceAt(arLabPacketLocalPosition(0.0), pose), ArLabDevice.pcA);
      expect(arLabDeviceAt(arLabPacketLocalPosition(1.0), pose), ArLabDevice.pcB);
    });

    test('clamps outside 0..1', () {
      for (int i = 0; i < 3; i++) {
        expect(arLabPacketLocalPosition(-1)[i],
            closeTo(arLabPacketLocalPosition(0.0)[i], 1e-9));
        expect(arLabPacketLocalPosition(2)[i],
            closeTo(arLabPacketLocalPosition(1.0)[i], 1e-9));
      }
    });

    test('travels at constant arc-length speed', () {
      double step(double a, double b) {
        final List<double> p = arLabPacketLocalPosition(a);
        final List<double> q = arLabPacketLocalPosition(b);
        double sum = 0;
        for (int i = 0; i < 3; i++) {
          sum += (q[i] - p[i]) * (q[i] - p[i]);
        }
        return sum;
      }

      // Equal t-steps cover (nearly) equal distances when parameterised by arc
      // length, so the packet does not speed up on the longer cable. (A naive
      // A->B lerp would make the start step many times the end step.)
      final double early = step(0.0, 0.1);
      final double late = step(0.9, 1.0);
      expect((early - late).abs(), lessThan(early * 0.3));
    });

    test('the packet node starts on the path', () {
      final Matrix4 pose = Matrix4.translationValues(2.0, 0.0, 0.0);
      final ARNode packet = arLabPacketNode(kArLabNodePacket, pose);
      expect(packet.name, kArLabNodePacket);
      expect(packet.uri, kArLabPacketAsset);
      expect(packet.type, NodeType.localGLB);
      final List<double> t = _translation(packet.transform);
      final List<double> p = arLabPacketLocalPosition(0.0);
      expect(t[0], closeTo(2.0 + p[0], 1e-6));
    });

    test('transform lands the packet on the local path point', () {
      final Matrix4 pose = Matrix4.translationValues(0.5, 1.0, -0.5);
      final List<double> t = _translation(arLabPacketTransform(pose, 0.37));
      final List<double> p = arLabPacketLocalPosition(0.37);
      expect(t[0], closeTo(0.5 + p[0], 1e-6));
      expect(t[1], closeTo(1.0 + p[1], 1e-6));
      expect(t[2], closeTo(-0.5 + p[2], 1e-6));
    });
  });

  group('packet to switch (failed connection)', () {
    test('the switch fraction is a real truncation of the full path', () {
      expect(kArLabPacketToSwitchFraction, greaterThan(0.01));
      expect(kArLabPacketToSwitchFraction, lessThan(0.99));
    });

    test('the failure leg starts at Computer A and stops at the switch', () {
      final Matrix4 pose = Matrix4.identity();

      // t = 0 is the very start of the A -> switch -> B path, which is PC A.
      expect(
        arLabDeviceAt(arLabPacketLocalPosition(0.0), pose),
        ArLabDevice.pcA,
      );
      // The truncation is a real cut: the endpoint is not the path's end.
      final List<double> end =
          arLabPacketLocalPosition(kArLabPacketToSwitchFraction);
      final List<double> fullEnd = arLabPacketLocalPosition(1.0);
      double dist(List<double> a, List<double> b) {
        double s = 0;
        for (int i = 0; i < 3; i++) {
          s += (a[i] - b[i]) * (a[i] - b[i]);
        }
        return math.sqrt(s);
      }

      expect(dist(end, fullEnd), greaterThan(0.5 * dist(
        arLabPacketLocalPosition(0.0),
        fullEnd,
      )));
    });

    test('the failure endpoint sits at the switch, not at a computer', () {
      // The truncated endpoint (the A drop cable's plug) must be far closer to
      // the switch than to either computer, so the animation reads "reached the
      // switch and no further".
      final List<double> end =
          arLabPacketLocalPosition(kArLabPacketToSwitchFraction);

      double d(List<double> a, List<double> b) {
        double s = 0;
        for (int i = 0; i < 3; i++) {
          s += (a[i] - b[i]) * (a[i] - b[i]);
        }
        return math.sqrt(s);
      }

      final List<double> switchCenter = kArLabSwitchLocalCenter;
      final double toSwitch = d(end, switchCenter);
      expect(toSwitch, lessThan(d(end, arLabDeviceLocalCenter(ArLabDevice.pcA))));
      expect(toSwitch, lessThan(d(end, arLabDeviceLocalCenter(ArLabDevice.pcB))));
    });

    test('the failure transform matches the full path truncated', () {
      final Matrix4 pose = Matrix4.translationValues(0.5, 1.0, -0.5);
      final List<double> end =
          _translation(arLabPacketToSwitchTransform(pose, 1.0));
      final List<double> truncated =
          arLabPacketLocalPosition(kArLabPacketToSwitchFraction);
      expect(end[0], closeTo(0.5 + truncated[0], 1e-6));
      expect(end[1], closeTo(1.0 + truncated[1], 1e-6));
      expect(end[2], closeTo(-0.5 + truncated[2], 1e-6));

      // t = 0 matches the full path at t = 0.
      final List<double> start =
          _translation(arLabPacketToSwitchTransform(pose, 0.0));
      final List<double> pathStart = arLabPacketLocalPosition(0.0);
      expect(start[0], closeTo(0.5 + pathStart[0], 1e-6));
      expect(start[1], closeTo(1.0 + pathStart[1], 1e-6));
      expect(start[2], closeTo(-0.5 + pathStart[2], 1e-6));
    });

    test('failure progress moves then holds at the switch, then loops', () {
      expect(arLabPacketFailureProgress(0.0), closeTo(0.0, 1e-9));
      expect(arLabPacketFailureProgress(0.35), closeTo(0.5, 1e-9));
      expect(arLabPacketFailureProgress(kArLabPacketFailureMovePortion),
          closeTo(1.0, 1e-9));
      expect(arLabPacketFailureProgress(0.9), closeTo(1.0, 1e-9));
      expect(arLabPacketFailureProgress(1.0), closeTo(1.0, 1e-9));

      // Out-of-range ticks clamp like the rest of the path math.
      expect(arLabPacketFailureProgress(-1.0), closeTo(0.0, 1e-9));
      expect(arLabPacketFailureProgress(2.0), closeTo(1.0, 1e-9));

      // Monotonic: the packet never runs backwards mid-loop.
      for (int i = 0; i <= 10; i++) {
        for (int j = i + 1; j <= 10; j++) {
          expect(
            arLabPacketFailureProgress(i / 10),
            lessThanOrEqualTo(arLabPacketFailureProgress(j / 10)),
          );
        }
      }
    });
  });

  group('arLabDeviceAt', () {
    test('selects the nearest computer within the tap threshold', () {
      final Matrix4 pose = Matrix4.identity();
      final List<double> centerA = arLabDeviceWorldCenter(ArLabDevice.pcA, pose);
      final List<double> centerB = arLabDeviceWorldCenter(ArLabDevice.pcB, pose);

      expect(arLabDeviceAt(centerA, pose), ArLabDevice.pcA);
      expect(arLabDeviceAt(centerB, pose), ArLabDevice.pcB);
    });

    test('tracks the marker pose', () {
      final Matrix4 pose = Matrix4.translationValues(3.0, 0.0, -1.0);
      final List<double> centerA = arLabDeviceWorldCenter(ArLabDevice.pcA, pose);
      expect(centerA[0], closeTo(3.0 + arLabDeviceWorldCenter(ArLabDevice.pcA, Matrix4.identity())[0], 1e-6));
    });

    test('returns null when the tap is far from both', () {
      final Matrix4 pose = Matrix4.identity();
      expect(arLabDeviceAt(<double>[5, 5, 5], pose), isNull);
      // The marker origin sits over the switch, which is not configurable.
      expect(arLabDeviceAt(<double>[0, 0, 0], pose), isNull);
    });

    test('picks the closer computer when the tap leans to one side', () {
      final Matrix4 pose = Matrix4.identity();
      final List<double> centerA = arLabDeviceWorldCenter(ArLabDevice.pcA, pose);
      expect(
        arLabDeviceAt(
          <double>[centerA[0] + 0.03, centerA[1], centerA[2]],
          pose,
        ),
        ArLabDevice.pcA,
      );
    });
  });
}

List<double> _translation(Matrix4 matrix) {
  final s = matrix.storage;
  return <double>[s[12], s[13], s[14]];
}
