import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/onboarding_scenes.dart';

/// The material banner illustration (`material-topic-thumbnail`, viewBox
/// 360x140) from the Figma Make reference, ported 1:1 as a `CustomPaint`.
///
/// [moduleNumber] 1-4 maps to the four scenes in `MaterialThumbnail.tsx`
/// (`material_network_basics`, `material_network_devices`,
/// `material_network_topology`, `material_ip_address`). Any other value - e.g.
/// a supporting material with no module number - renders only the tinted
/// banner, like the CSS-only fallback would.
///
/// Layering note: this shared widget imports the scene kit from
/// `features/auth/onboarding_scenes.dart` because the network components
/// (RouterDevice / Computer / Laptop) were first drawn for the onboarding
/// scenes and the `netArt*` facade keeps their geometry defined in exactly one
/// place; duplicating those components here would be the worse trade.
/// [exampleIpLabel] is the localized EXAMPLE IP label painted inside the
/// module-4 address card (CONTOH IP in Indonesian).
class NlMaterialThumbnail extends StatelessWidget {
  const NlMaterialThumbnail({
    super.key,
    required this.moduleNumber,
    required this.exampleIpLabel,
  });

  final int? moduleNumber;
  final String exampleIpLabel;

  @override
  Widget build(BuildContext context) {
    // `color-mix(in srgb, var(--primary) 9%, white)` in light mode; the dark
    // variant in material-thumbnails.css lifts the primary share to 14% and
    // mixes into the surface instead of white.
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bannerColor = Color.lerp(
      dark ? scheme.surface : Colors.white,
      scheme.primary,
      dark ? 0.14 : 0.09,
    )!;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius:
            const BorderRadius.all(Radius.circular(NetLearnRadius.button)),
        child: DecoratedBox(
          decoration: BoxDecoration(color: bannerColor),
          child: AspectRatio(
            aspectRatio: 360 / 140,
            // The SVG is aria-hidden, so the painting stays out of the
            // semantics tree as well.
            child: ExcludeSemantics(
              child: CustomPaint(
                painter:
                    _MaterialThumbnailPainter(moduleNumber, exampleIpLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialThumbnailPainter extends CustomPainter {
  const _MaterialThumbnailPainter(this._moduleNumber, this._exampleIpLabel);

  final int? _moduleNumber;
  final String _exampleIpLabel;

  // SVG strokeDasharray with the caps of the source file (`<path>` defaults to
  // butt caps inside a dashed stroke).
  static const _butt = StrokeCap.butt;
  static const _miter = StrokeJoin.miter;

  /// Generous saveLayer bounds for the few paths that carry a fractional SVG
  /// `opacity` (covers the 360x140 viewBox plus the 4px shadow blur).
  static final _fullBounds = Rect.fromLTRB(-40, -40, 400, 190);

  @override
  void paint(Canvas canvas, Size size) {
    final module = _moduleNumber;
    if (module == null || module < 1 || module > 4) return;

    final scale = math.min(size.width / 360, size.height / 140);
    canvas.translate(
      (size.width - 360 * scale) / 2,
      (size.height - 140 * scale) / 2,
    );
    canvas.scale(scale);

    // Shared ground glow, identical for all four scenes.
    netArtAmbient(canvas, const Offset(172, 119), 128, 15);

    switch (module) {
      case 1:
        _paintNetworkBasicsScene(canvas);
      case 2:
        _paintNetworkDevicesScene(canvas);
      case 3:
        _paintNetworkTopologyScene(canvas);
      case 4:
        _paintIpAddressScene(canvas);
    }

    _paintCornerNumber(canvas, module);
  }

  @override
  bool shouldRepaint(_MaterialThumbnailPainter oldDelegate) =>
      oldDelegate._moduleNumber != _moduleNumber ||
      oldDelegate._exampleIpLabel != _exampleIpLabel;

  // ── Module 1: material_network_basics ─────────────────────────────────────
  void _paintNetworkBasicsScene(Canvas canvas) {
    // Backing plane and its paper projection.
    final planeBack = _svg('M34 76L169 28L326 73V82L188 131L34 85Z');
    _withOpacityLayer(
      canvas,
      0.6,
      () => canvas.drawPath(planeBack, netArtFlatPaint(const Color(0xFFCDBFE8))),
    );
    final planeTop = _svg('M34 76L169 28L326 73L188 123Z');
    _withOpacityLayer(
      canvas,
      0.72,
      () => canvas.drawPath(planeTop, netArtPaperFill(planeTop)),
    );

    netArtStroke(
      canvas,
      'M64 66L218 112M96 54L251 101M130 42L286 89M69 86L202 38'
      'M104 98L237 48M143 110L276 59',
      netArtFlatStroke(const Color(0xFFC9BEE3), 0.8,
          opacity: 0.7, cap: _butt, join: _miter),
    );

    // Connectors from the router to the laptop and up to the workspace.
    netArtStroke(
      canvas,
      'M92 82L176 62L282 84M176 62V30',
      netArtFlatStroke(const Color(0xFF9C86C3), 3),
    );
    netArtStroke(
      canvas,
      'M112 77L127 73M222 72L239 75',
      netArtFlatStroke(const Color(0xFF9BD7CB), 3),
    );

    netArtTransformed(
      canvas,
      dx: 142,
      dy: 15,
      scale: 0.78,
      paint: () => netArtRouterDevice(canvas, contactShadow: true),
    );
    netArtTransformed(
      canvas,
      dx: 49,
      dy: 47,
      scale: 1.1,
      paint: () => netArtComputer(canvas, contactShadow: true),
    );
    netArtTransformed(
      canvas,
      dx: 241,
      dy: 29,
      scale: 0.66,
      paint: () => netArtLaptop(canvas, contactShadow: true),
    );

    _paintRingDots(canvas, const [
      _RingDot(Offset(135, 72), 4),
      _RingDot(Offset(222, 72), 4),
      _RingDot(Offset(176, 30), 3.5),
    ], const Color(0xFF9ED3BB), 2);

    // Tablet stack on the plane front.
    canvas.save();
    canvas.translate(118, 91);
    final tabletEdge = _svg('M0 9L24 2L43 10V17L19 24L0 16Z');
    canvas.drawPath(tabletEdge, netArtEdgeFill(tabletEdge));
    final tabletTop = _svg('M0 9L24 2L43 10L19 17Z');
    canvas.drawPath(tabletTop, netArtPaperFill(tabletTop));
    canvas.drawPath(
      netArtDashedPath(_svg('M24 19L36 15'), 2, 2),
      netArtFlatStroke(const Color(0xFF6EAEBB), 2),
    );
    canvas.restore();
  }

  // ── Module 2: material_network_devices ────────────────────────────────────
  void _paintNetworkDevicesScene(Canvas canvas) {
    final groundBack = Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(171, 111),
        width: 252,
        height: 32,
      ));
    _withOpacityLayer(
      canvas,
      0.55,
      () => canvas.drawPath(groundBack, netArtFlatPaint(const Color(0xFFDBD1EF))),
    );
    _withOpacityLayer(
      canvas,
      0.75,
      () => canvas.drawPath(groundBack, netArtPaperFill(groundBack)),
    );

    netArtTransformed(
      canvas,
      dx: 66,
      dy: 16,
      scale: 1.12,
      paint: () => netArtRouterDevice(canvas, contactShadow: true),
    );

    // The four-port switch, drawn over the router's shadow line.
    netArtTransformed(
      canvas,
      dx: 192,
      dy: 52,
      degrees: -4,
      paint: () {
        final switchFront = _svg('M0 15L66 3L97 18V37L30 51L0 36Z');
        netArtContactShadow(canvas, blobs: [switchFront]);
        canvas.drawPath(switchFront, netArtEdgeFill(switchFront));
        final switchTop = _svg('M0 15L66 3L97 18L30 32Z');
        canvas.drawPath(switchTop, netArtPaperFill(switchTop));

        for (var index = 0; index < 6; index++) {
          canvas.drawPath(
            _svg('M${36 + index * 9} ${34 - index * 1.8}l5 -1v6l-5 1z'),
            netArtFlatPaint(const Color(0xFF514265)),
          );
        }
        netArtStroke(canvas, 'M12 26L19 30',
            netArtFlatStroke(const Color(0xFF9ED3BB), 2));
        netArtStroke(
            canvas,
            'M39 17L62 12M43 20L66 15M47 23L70 18',
            netArtFlatStroke(const Color(0xFFD1C6E5), 1.5));
        netArtStroke(
            canvas,
            'M32 33L90 21',
            netArtFlatStroke(Colors.white, 1, opacity: 0.75));
        for (var index = 0; index < 4; index++) {
          netArtDot(
            canvas,
            Offset(41 + index * 11, 43 - index * 2),
            1.5,
            index == 1
                ? const Color(0xFFA3B9E9)
                : const Color(0xFFA0DBC8),
          );
        }
      },
    );

    // Ethernet cable arcing out of the switch with its highlight.
    netArtStroke(
      canvas,
      'M143 86Q148 119 175 117H190Q212 117 213 98',
      netArtFlatStroke(const Color(0xFF7D9FB6), 4),
    );
    netArtStroke(
      canvas,
      'M143 86Q148 115 175 113H190Q207 113 209 98',
      netArtFlatStroke(const Color(0xFFB6D8DC), 1.3),
    );

    // RJ45 plug.
    netArtTransformed(
      canvas,
      dx: 201,
      dy: 87,
      degrees: -8,
      paint: () {
        final plug = netArtRoundedRect(0, 0, 15, 18, 3);
        canvas.drawPath(plug, netArtPaperFill(plug));
        canvas.drawPath(plug, netArtFlatStroke(const Color(0xFFA68FC1), 1));
        netArtStroke(canvas, 'M4 1V7M8 1V7M12 1V7',
            netArtFlatStroke(const Color(0xFF8BAD9F), 1.5));
      },
    );

    // Device manual lying on the plane.
    netArtTransformed(
      canvas,
      dx: 64,
      dy: 99,
      degrees: -11,
      paint: () {
        netArtContactShadow(canvas, blobs: [_svg('M0 0H48L56 17L8 20Z')]);
        canvas.drawPath(
            _svg('M0 0H48L56 17L8 20Z'), netArtFlatPaint(const Color(0xFF9BB6B5)));
        netArtStroke(canvas, 'M9 6H29M12 10H32',
            netArtFlatStroke(const Color(0xFFCAE5DB), 1.2));
        final sticker = netArtRoundedRect(34, 1, 15, 11, 2);
        canvas.drawPath(sticker, netArtPaperFill(sticker));
        canvas.drawPath(
            netArtRoundedRect(37, 4, 9, 5, 1),
            netArtFlatPaint(const Color(0xFF645270)));
        canvas.drawPath(
          netArtDashedPath(_svg('M13 18L33 17'), 2, 1),
          netArtFlatStroke(const Color(0xFFD5C48D), 3),
        );
      },
    );
  }

  // ── Module 3: material_network_topology ──────────────────────────────────
  void _paintNetworkTopologyScene(Canvas canvas) {
    final bigGround = Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(180, 90),
        width: 252,
        height: 80,
      ));
    _withOpacityLayer(
      canvas,
      0.65,
      () => canvas.drawPath(bigGround, netArtFlatPaint(const Color(0xFFCBBBE6))),
    );
    _withOpacityLayer(
      canvas,
      0.85,
      () => canvas.drawPath(bigGround, netArtPaperFill(bigGround)),
    );

    final groundRing = Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(180, 85),
        width: 204,
        height: 62,
      ));
    canvas.drawPath(
      netArtDashedPath(groundRing, 3, 5),
      netArtFlatStroke(const Color(0xFFCCBEE2), 1, cap: _butt),
    );

    // Star connectors from the central switch out to four desks.
    netArtStroke(
      canvas,
      'M174 69H130Q121 69 121 60V39H88'
      'M174 69H226Q235 69 235 60V39H264'
      'M174 69H130Q121 69 121 78V110H88'
      'M174 69H226Q235 69 235 78V110H264',
      netArtFlatStroke(const Color(0xFFAD98CB), 3),
    );
    netArtStroke(
      canvas,
      'M174 69H130Q121 69 121 60V39H88'
      'M174 69H226Q235 69 235 60V39H264',
      netArtFlatStroke(const Color(0xFFF5F0FF), 1),
    );

    // One contact shadow behind the whole switch-plus-computers group, the
    // way the SVG's `filter=contact` group does it.
    netArtContactShadow(canvas, blobs: [
      for (final step in const [
        Offset(62, 11),
        Offset(251, 11),
        Offset(62, 86),
        Offset(251, 86),
      ]) ...[
        _transformedComputerSilhouette(step.dx, step.dy),
      ],
      _svg('M142 53L183 44L211 56V80L168 91L142 77Z'),
      _svg('M142 53L183 44L211 56L168 66Z'),
    ]);

    for (final step in const [
      Offset(62, 11),
      Offset(251, 11),
      Offset(62, 86),
      Offset(251, 86),
    ]) {
      netArtTransformed(
        canvas,
        dx: step.dx,
        dy: step.dy,
        scale: 0.72,
        paint: () => netArtComputer(canvas, contactShadow: false),
      );
    }

    final switchFront = _svg('M142 53L183 44L211 56V80L168 91L142 77Z');
    canvas.drawPath(switchFront, netArtPurpleFill(switchFront));
    final switchTop = _svg('M142 53L183 44L211 56L168 66Z');
    canvas.drawPath(switchTop, netArtPaperFill(switchTop));
    canvas.drawPath(
      netArtDashedPath(_svg('M172 72L203 64'), 4, 3),
      netArtFlatStroke(const Color(0xFF514265), 5, cap: _butt),
    );
    netArtStroke(canvas, 'M151 61L160 65',
        netArtFlatStroke(const Color(0xFFA4E0CD), 2));
    canvas.drawPath(
      _svg('M160 56L183 51L195 56L172 62Z'),
      netArtFlatPaint(const Color(0xFFE1D7F0)),
    );
    netArtDot(canvas, const Offset(155, 76), 2.5, const Color(0xFF9ED3BB));

    _paintRingDots(canvas, const [
      _RingDot(Offset(121, 50), 3.5),
      _RingDot(Offset(235, 87), 3.5),
      _RingDot(Offset(108, 110), 3.5),
      _RingDot(Offset(250, 39), 3.5),
    ], const Color(0xFF9DD4D3), 1.5);
  }

  // ── Module 4: material_ip_address ────────────────────────────────────────
  void _paintIpAddressScene(Canvas canvas) {
    final planeBack = _svg('M45 91L135 48L314 87V96L224 132L45 100Z');
    _withOpacityLayer(
      canvas,
      0.5,
      () => canvas.drawPath(planeBack, netArtFlatPaint(const Color(0xFFD9CFEE))),
    );
    final planeTop = _svg('M45 91L135 48L314 87L224 123Z');
    _withOpacityLayer(
      canvas,
      0.75,
      () => canvas.drawPath(planeTop, netArtPaperFill(planeTop)),
    );

    netArtStroke(
      canvas,
      'M111 91H152Q164 91 164 79V54H200M164 79V113H237',
      netArtFlatStroke(const Color(0xFF98A9CB), 2.5),
    );

    netArtTransformed(
      canvas,
      dx: 53,
      dy: 32,
      scale: 1.15,
      paint: () => netArtComputer(canvas, contactShadow: true),
    );

    // The tilted, faded card behind the address card.
    netArtTransformed(
      canvas,
      dx: 205,
      dy: 18,
      degrees: 6,
      paint: () => _withOpacityLayer(
        canvas,
        0.7,
        () {
          final back = netArtRoundedRect(0, 0, 102, 70, 10);
          canvas.drawPath(back, netArtEdgeFill(back));
          netArtStroke(canvas, 'M13 16H48M13 26H75',
              netArtFlatStroke(const Color(0xFFEEE8F7), 3));
        },
      ),
    );

    // The address card itself, with the example octets.
    netArtTransformed(
      canvas,
      dx: 188,
      dy: 32,
      paint: () {
        final back = netArtRoundedRect(3, 4, 112, 79, 12);
        final front = netArtRoundedRect(0, 0, 112, 79, 12);
        netArtContactShadow(canvas, blobs: [back, front]);
        canvas.drawPath(back, netArtEdgeFill(back));
        canvas.drawPath(front, netArtPaperFill(front));

        _paintLabel(
          canvas,
          text: _exampleIpLabel,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF796094),
          ),
          anchor: const Offset(13, 24),
        );

        canvas.drawPath(
          netArtRoundedRect(10, 35, 92, 27, 7),
          netArtFlatPaint(const Color(0xFFE9E0F7)),
        );
        _paintLabel(
          canvas,
          text: '192.168.1.10',
          // The SVG uses fontFamily=monospace, so the octets align.
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF543875),
          ),
          anchor: const Offset(56, 53),
          centered: true,
        );

        netArtStroke(canvas, 'M14 69H40',
            netArtFlatStroke(const Color(0xFFB7A8D0), 2));
        netArtDot(
            canvas, const Offset(93, 69), 3, const Color(0xFF92C9B7));
      },
    );

    _paintRingDots(canvas, const [
      _RingDot(Offset(147, 91), 4),
      _RingDot(Offset(222, 113), 4),
      _RingDot(Offset(237, 113), 4),
    ], const Color(0xFFA2D7C6), 1.5);

    // Little routing chip on the plane front.
    netArtTransformed(
      canvas,
      dx: 101,
      dy: 103,
      paint: () {
        final chip = netArtRoundedRect(0, 0, 31, 15, 4);
        canvas.drawPath(chip, netArtPurpleFill(chip));
        canvas.drawPath(
          netArtDashedPath(_svg('M7 7H23'), 3, 2),
          netArtFlatStroke(const Color(0xFFE8E0F4), 2),
        );
      },
    );
  }

  // ── Shared pieces ─────────────────────────────────────────────────────────

  /// The padded `01`…`04` index, right-aligned at (337, 28).
  void _paintCornerNumber(Canvas canvas, int module) {
    final padded = module.toString().padLeft(2, '0');
    final textPainter = TextPainter(
      text: TextSpan(
        text: padded,
        style: TextStyle(
          fontFamily: AppTheme.displayFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFA58EC7).withValues(alpha: 0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        337 - textPainter.width,
        28 - textPainter
            .computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );
  }

  void _paintLabel(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required Offset anchor,
    bool centered = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx =
        centered ? anchor.dx - textPainter.width / 2 : anchor.dx;
    final dy = anchor.dy -
        textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    textPainter.paint(canvas, Offset(dx, dy));
  }

  /// `<g fill=fill stroke=#fff>` dots: a filled circle with a white ring.
  void _paintRingDots(
    Canvas canvas,
    List<_RingDot> dots,
    Color fill,
    double stroke,
  ) {
    for (final dot in dots) {
      canvas.drawCircle(dot.center, dot.radius, netArtFlatPaint(fill));
      canvas.drawCircle(
          dot.center, dot.radius, netArtFlatStroke(Colors.white, stroke));
    }
  }

  void _withOpacityLayer(Canvas canvas, double opacity, VoidCallback paint) {
    canvas.saveLayer(
      _fullBounds,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    paint();
    canvas.restore();
  }

  Path _svg(String source) => parseSvgPathData(source);

  /// The computer silhouette (body + stand), translated into the group's space
  /// so the topology scene can shadow all four computers at once.
  Path _transformedComputerSilhouette(double dx, double dy) {
    final matrix = Matrix4.translationValues(dx, dy, 0)
      ..scaleByDouble(0.72, 0.72, 1, 1);
    final silhouette = Path()
      ..addPath(
        parseSvgPathData(
            'M4 4Q4 1 8 2L48 8Q51 9 51 13V36Q51 40 47 39L6 33Q3 32 3 29Z'),
        Offset.zero,
      )
      ..addPath(
        parseSvgPathData('M24 32V43L13 46L29 51L42 47L31 43V31'),
        Offset.zero,
      );
    return silhouette.transform(matrix.storage);
  }
}

class _RingDot {
  const _RingDot(this.center, this.radius);

  final Offset center;
  final double radius;
}
