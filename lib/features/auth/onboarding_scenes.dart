import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Vector port of the Figma Make onboarding artwork
/// (`OnboardingScenes.tsx` + its inline `<defs>` gradients).
///
/// Figma Make does not export the scenes as image assets; the artwork is pure
/// SVG paths painted with objectBoundingBox gradients (`purple`, `paper`,
/// `edge`, `navy`, `screen`, `skin`, `ambient`), one shared contact drop
/// shadow filter, and dashed connector strokes. This file reproduces that
/// geometry 1:1 in Flutter `CustomPainter`s so onboarding needs no bundled
/// bitmaps and stays offline-testable.
///
/// Fidelity notes (difference from the SVG original, kept intentionally):
/// - The `contact` filter (`feDropShadow dy=5 stdDeviation=4`) is drawn per
///   group from representative filled silhouettes unioned into one blurred
///   path plus separate blurred strokes, not from the filter's exact Gaussian
///   of every member shape.
/// - Radial gradients that SVG maps over the bounding box (skin, ambient) are
///   drawn inside a bbox scaled canvas so the gradient stretches into the same
///   ellipse; linear gradients are computed in pixel space over the shape's
///   own bounds, which matches objectBoundingBox semantics for lines.
///
/// The coordinate spaces are the SVG viewBoxes: scene 360×290, module 80×56.

/// The three onboarding hero scenes, matching `OnboardingScene`'s variants.
enum OnboardingSceneVariant { student, network, journey }

/// The four module card illustrations, matching `ModuleIllustration`'s
/// 0..3 modules (Dasar-Dasar Jaringan, Perangkat Jaringan,
/// Topologi Jaringan, IP Address).
enum OnboardingModuleArt { fundamentals, devices, topology, ipAddress }

/// Renders one onboarding hero scene scaled to fit its parent, preserving the
/// 360×290 aspect of the SVG viewBox.
class OnboardingSceneView extends StatelessWidget {
  const OnboardingSceneView({
    super.key,
    required this.variant,
    this.semanticLabel,
  });

  final OnboardingSceneVariant variant;

  /// Screen-reader description of the artwork (the SVG had role="img" with an
  /// aria-label; pass localized copy here).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: 360 / 290,
        child: CustomPaint(
          size: Size.infinite,
          painter: _ScenePainter(variant),
        ),
      ),
    );
  }
}

/// Renders one module illustration scaled to fit its parent, preserving the
/// 80×56 aspect of the SVG viewBox.
class OnboardingModuleIllustration extends StatelessWidget {
  const OnboardingModuleIllustration({super.key, required this.module});

  final OnboardingModuleArt module;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The source SVG marks the module icons aria-hidden / presentational.
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ModulePainter(module.index),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.variant);

  final OnboardingSceneVariant variant;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final scale = math.min(size.width / 360, size.height / 290);
    if (scale <= 0) {
      return;
    }
    canvas.save();
    canvas.translate((size.width - 360 * scale) / 2,
        (size.height - 290 * scale) / 2);
    canvas.scale(scale, scale);
    switch (variant) {
      case OnboardingSceneVariant.student:
        _paintStudentScene(canvas);
      case OnboardingSceneVariant.network:
        _paintNetworkScene(canvas);
      case OnboardingSceneVariant.journey:
        _paintJourneyScene(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.variant != variant;

  @override
  bool operator ==(Object other) =>
      other is _ScenePainter && other.variant == variant;

  @override
  int get hashCode => variant.hashCode;
}

class _ModulePainter extends CustomPainter {
  const _ModulePainter(this.module);

  final int module;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final scale = math.min(size.width / 80, size.height / 56);
    if (scale <= 0) {
      return;
    }
    canvas.save();
    canvas.translate((size.width - 80 * scale) / 2,
        (size.height - 56 * scale) / 2);
    canvas.scale(scale, scale);
    _paintModule(canvas, module);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ModulePainter oldDelegate) =>
      oldDelegate.module != module;

  @override
  bool operator ==(Object other) =>
      other is _ModulePainter && other.module == module;

  @override
  int get hashCode => module.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// SVG path data parser
//
// The scenes only ever use M m L l H h V v Q q Z z (verified against
// OnboardingScenes.tsx), so the parser deliberately covers just that subset.
// ─────────────────────────────────────────────────────────────────────────────

// Tokenizer distinguishes real nodes so a stray command (e.g. 'C') fails
// loudly instead of being dropped silently. Group 1 = command, group 2 =
// number, group 3 = anything else (unsupported).
final RegExp _svgPathTokens = RegExp(
  r'([MmLlHhVvQqZz])'
  r'|(-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)'
  r'|([^\s,]+)',
);

bool _isCommandToken(String token) =>
    token.length == 1 && 'MmLlHhVvQqZz'.contains(token);

/// Parses the restricted SVG path grammar used by the onboarding scenes
/// (M m L l H h V v Q q Z z only).
///
/// Throws [ArgumentError] on any command outside the supported subset so that
/// transcription mistakes surface as test failures instead of missing shapes.
Path parseSvgPathData(String source) {
  final tokens = <String>[];
  for (final match in _svgPathTokens.allMatches(source)) {
    final command = match.group(1);
    final number = match.group(2);
    final unsupported = match.group(3);
    if (unsupported != null) {
      throw ArgumentError(
        'Unsupported SVG path character "$unsupported" in "$source"',
      );
    }
    tokens.add(command ?? number!);
  }
  if (tokens.isEmpty) {
    return Path();
  }

  final path = Path();
  var index = 0;
  double x = 0;
  double y = 0;
  double subpathStartX = 0;
  double subpathStartY = 0;

  double nextNumber() {
    if (index >= tokens.length || _isCommandToken(tokens[index])) {
      throw ArgumentError(
        'Missing coordinate for command "${tokens[index - 1]}" at '
        'token $index in "$source"',
      );
    }
    return double.parse(tokens[index++]);
  }

  while (index < tokens.length) {
    if (!_isCommandToken(tokens[index])) {
      throw ArgumentError(
        'Unexpected token "${tokens[index]}" at position $index in "$source"',
      );
    }
    final command = tokens[index++];
    final relative = command.length == 1 && command == command.toLowerCase();

    switch (command.toLowerCase()) {
      case 'm':
        // A moveto followed by additional pairs degrades into linetos (SVG 8.3).
        var first = true;
        while (index < tokens.length && !_isCommandToken(tokens[index])) {
          final px = nextNumber();
          final py = nextNumber();
          final nx = relative ? x + px : px;
          final ny = relative ? y + py : py;
          if (first) {
            path.moveTo(nx, ny);
            subpathStartX = nx;
            subpathStartY = ny;
            first = false;
          } else {
            path.lineTo(nx, ny);
          }
          x = nx;
          y = ny;
        }
        if (first) {
          throw ArgumentError('Moveto without coordinates in "$source"');
        }
      case 'l':
        while (index < tokens.length && !_isCommandToken(tokens[index])) {
          final px = nextNumber();
          final py = nextNumber();
          final nx = relative ? x + px : px;
          final ny = relative ? y + py : py;
          path.lineTo(nx, ny);
          x = nx;
          y = ny;
        }
      case 'h':
        while (index < tokens.length && !_isCommandToken(tokens[index])) {
          final px = nextNumber();
          final nx = relative ? x + px : px;
          path.lineTo(nx, y);
          x = nx;
        }
      case 'v':
        while (index < tokens.length && !_isCommandToken(tokens[index])) {
          final py = nextNumber();
          final ny = relative ? y + py : py;
          path.lineTo(x, ny);
          y = ny;
        }
      case 'q':
        while (index < tokens.length && !_isCommandToken(tokens[index])) {
          final cpx = nextNumber();
          final cpy = nextNumber();
          final px = nextNumber();
          final py = nextNumber();
          final cx = relative ? x + cpx : cpx;
          final cy = relative ? y + cpy : cpy;
          final nx = relative ? x + px : px;
          final ny = relative ? y + py : py;
          path.quadraticBezierTo(cx, cy, nx, ny);
          x = nx;
          y = ny;
        }
      case 'z':
        path.close();
        // After a close the current point returns to the subpath start.
        x = subpathStartX;
        y = subpathStartY;
      default:
        // The token check above guarantees one of the handled commands, but
        // keep the default arm total in case the regex set ever grows.
        throw ArgumentError(
          'Unsupported SVG path command "$command" in "$source"',
        );
    }
  }

  return path;
}

Path _svgPath(String data) => parseSvgPathData(data);

// ─────────────────────────────────────────────────────────────────────────────
// Painting helpers (Maps: <defs> gradients, filter contact, dashes)
// ─────────────────────────────────────────────────────────────────────────────

const List<double> _defaultStops = [0.0, 1.0];

/// objectBoundingBox linear fill: gradient corners are fractions of the
/// shape's own bounding box, exactly like the SVG `gradientUnits` default.
Paint _linearFill(
  Path shape, {
  required double x1,
  required double y1,
  required double x2,
  required double y2,
  required List<Color> colors,
  List<double>? stops,
}) {
  final box = shape.getBounds();
  final start = Offset(box.left + x1 * box.width, box.top + y1 * box.height);
  final end = Offset(box.left + x2 * box.width, box.top + y2 * box.height);
  return Paint()
    ..isAntiAlias = true
    ..shader = ui.Gradient.linear(start, end, colors, stops);
}

/// objectBoundingBox radial fill / stroke painting. Runs inside a bbox-scaled
/// canvas so a unit circle gradient stretches into the same ellipse SVG
/// produces for non-square bounding boxes. [strokeWidth] > 0 renders a stroke
/// in the unit space (widths are therefore in box fractions, used for the
/// thin ambient ring only).
void _drawBBoxRadial(
  Canvas canvas,
  Path shape, {
  required Offset center,
  required double radius,
  required List<Color> colors,
  List<double>? stops,
}) {
  final box = shape.getBounds();
  if (box.width <= 0 || box.height <= 0) {
    return;
  }
  canvas.save();
  canvas.translate(box.left, box.top);
  canvas.scale(box.width, box.height);
  canvas.drawPath(
    shape,
    Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(center, radius, colors,
          stops ?? _defaultStops),
  );
  canvas.restore();
}

// <defs> — shared Materials gradients, verbatim colors and stop offsets.

Paint _purpleFill(Path shape) => _linearFill(
      shape,
      x1: 0.1,
      y1: 0,
      x2: 0.85,
      y2: 1,
      colors: const [
        Color(0xFFB7A4EF),
        Color(0xFF8063D6),
        Color(0xFF543CD1),
      ],
      stops: const [0.0, 0.55, 1.0],
    );

Paint _paperFill(Path shape) => _linearFill(
      shape,
      x1: 0.15,
      y1: 0,
      x2: 0.8,
      y2: 1,
      colors: const [
        Color(0xFFFFFFFF),
        Color(0xFFF2EEFB),
        Color(0xFFD9CFEC),
      ],
      stops: const [0.0, 0.65, 1.0],
    );

Paint _edgeFill(Path shape) => _linearFill(
      shape,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      colors: const [Color(0xFFC5B6E7), Color(0xFF8A73B7)],
    );

Paint _navyFill(Path shape) => _linearFill(
      shape,
      x1: 0,
      y1: 0,
      x2: 0.8,
      y2: 1,
      colors: const [Color(0xFF544374), Color(0xFF241A39)],
    );

Paint _screenFill(Path shape) => _linearFill(
      shape,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      colors: const [Color(0xFF514285), Color(0xFF25203F)],
    );

void _skinFillPaint(Canvas canvas, Path shape) => _drawBBoxRadial(
      canvas,
      shape,
      center: const Offset(0.28, 0.3),
      radius: 0.85,
      colors: const [
        Color(0xFFF8DECF),
        Color(0xFFE9BDA5),
        Color(0xFFC79179),
      ],
      stops: const [0.0, 0.65, 1.0],
    );

/// Skin gradient for small stroked shapes (hands): a linear approximation
/// over the stroke path bounds — the SVG's objectBoundingBox radial over a
/// tiny capsule is visually flat, so the linear cross-section reads the same.
Paint _skinStrokePaint(Path shape, double width) {
  final box = shape.getBounds();
  return Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..shader = ui.Gradient.linear(
      box.topLeft,
      box.bottomRight,
      const [Color(0xFFF8DECF), Color(0xFFC79179)],
    );
}

Paint _purpleStrokePaint(Path shape, double width) {
  final paint = _linearFill(
    shape,
    x1: 0.1,
    y1: 0,
    x2: 0.85,
    y2: 1,
    colors: const [
      Color(0xFFB7A4EF),
      Color(0xFF8063D6),
      Color(0xFF543CD1),
    ],
    stops: const [0.0, 0.55, 1.0],
  );
  paint.style = PaintingStyle.stroke;
  paint.strokeWidth = width;
  return paint;
}

Paint _flatPaint(Color color, [double opacity = 1]) => Paint()
  ..isAntiAlias = true
  ..color = opacity == 1 ? color : color.withValues(alpha: opacity);

Paint _flatStroke(
  Color color,
  double width, {
  double opacity = 1,
  StrokeCap cap = StrokeCap.round,
  StrokeJoin join = StrokeJoin.round,
}) =>
    Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..strokeJoin = join
      ..color = opacity == 1 ? color : color.withValues(alpha: opacity);

void _paintStroke(Canvas canvas, String data, Paint paint) {
  canvas.drawPath(_svgPath(data), paint);
}

void _paintDot(Canvas canvas, Offset center, double radius, Color color) =>
    canvas.drawCircle(center, radius, _flatPaint(color));

/// `<filter id="contact">` — feDropShadow(0, 5, 4) at 15% #392261, painted
/// from the group's filled silhouettes (unioned) plus separate blurred
/// strokes so overlapping bodies do not darken the shadow twice.
void _paintContactShadow(
  Canvas canvas, {
  List<Path> blobs = const [],
  List<StrokeShadow> strokes = const [],
}) {
  const shadowColor = Color(0xFF392261);
  const offset = Offset(0, 5);

  if (blobs.isNotEmpty) {
    var combined = blobs.first;
    for (var i = 1; i < blobs.length; i++) {
      combined = Path.combine(PathOperation.union, combined, blobs[i]);
    }
    canvas.drawPath(
      combined.shift(offset),
      Paint()
        ..isAntiAlias = true
        ..color = shadowColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  for (final stroke in strokes) {
    canvas.drawPath(
      stroke.path.shift(offset),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..color = shadowColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
}

class StrokeShadow {
  const StrokeShadow(this.path, this.width);

  final Path path;
  final double width;
}

/// Stops a stroke short in `dash, gap` runs (SVG strokeDasharray with the
/// round line caps preserved on each segment).
Path _dashedStrokePath(Path source, double dash, double gap) {
  final result = Path();
  for (final metric in source.computeMetrics()) {
    final length = metric.length;
    var distance = 0.0;
    var draw = true;
    while (distance < length) {
      final step = math.min(draw ? dash : gap, length - distance);
      if (draw && step > 0) {
        result.addPath(
          metric.extractPath(distance, distance + step),
          Offset.zero,
        );
      }
      distance += step;
      draw = !draw;
    }
  }
  return result;
}

Path _roundedRect(double x, double y, double width, double height,
        double radius) =>
    Path()..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height), Radius.circular(radius)));

Path _circlePath(Offset center, double radius) =>
    Path()..addOval(Rect.fromCircle(center: center, radius: radius));

/// The `<ellipse … fill=ambient>` ground glows: a bbox-stretched radial that
/// fades #d5c9ef (65% alpha) to transparent across the ellipse, so no hard
/// edge appears along the tighter axis.
void _paintAmbient(Canvas canvas, Offset center, double rx, double ry) {
  final ellipse = Path()..addOval(Rect.fromCenter(
      center: center, width: rx * 2, height: ry * 2));
  _drawBBoxRadial(
    canvas,
    ellipse,
    center: const Offset(0.5, 0.5),
    radius: 0.5,
    colors: const [Color(0xA6D5C9EF), Color(0x00D5C9EF)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Component painters (RouterDevice, Computer, Laptop)
// ─────────────────────────────────────────────────────────────────────────────

void _paintRouterDevice(Canvas canvas, {required bool contactShadow}) {
  if (contactShadow) {
    _paintContactShadow(
      canvas,
      blobs: [
        _svgPath(
            'M4 32Q3 29 8 28L65 17Q69 16 73 19L89 29Q93 32 86 34L30 45Q26 46 22 44Z'),
      ],
      strokes: [
        StrokeShadow(_svgPath('M14 30L11 1M76 29L79 0'), 6),
        StrokeShadow(_svgPath('M25 46V58'), 1),
      ],
    );
  }

  _paintAmbient(canvas, const Offset(46, 57), 47, 10);
  final bodyEdge = _svgPath(
      'M7 27L65 16Q69 15 73 18L91 29V43Q91 46 86 47L29 59Q24 60 20 57L4 46V32Z');
  canvas.drawPath(bodyEdge, _edgeFill(bodyEdge));
  final bodyPaper = _svgPath(
      'M4 32Q3 29 8 28L65 17Q69 16 73 19L89 29Q93 32 86 34L30 45Q26 46 22 44Z');
  canvas.drawPath(bodyPaper, _paperFill(bodyPaper));
  _paintStroke(
      canvas, 'M25 46V58', _flatStroke(const Color(0xFFB09BD2), 1));
  final antennas = _svgPath('M14 30L11 1M76 29L79 0');
  final antennaPaint = _edgeFill(antennas)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(antennas, antennaPaint);
  _paintStroke(
      canvas,
      'M13 25L11 1M77 22L79 0',
      _flatStroke(const Color(0xFFE2D9F0), 2));
  for (var portIndex = 0; portIndex < 4; portIndex++) {
    canvas.drawPath(
      _svgPath('M${34 + portIndex * 10} ${45 - portIndex * 2}l6 -1v6l-6 1z'),
      _flatPaint(const Color(0xFF574570)),
    );
  }
  _paintStroke(
      canvas,
      'M41 29L64 24M41 32L64 27',
      _flatStroke(const Color(0xFFD6CCE8), 1.5));
  _paintDot(canvas, const Offset(81, 41), 2, const Color(0xFF8DD6BA));
}

void _paintComputer(Canvas canvas, {required bool contactShadow}) {
  if (contactShadow) {
    _paintContactShadow(
      canvas,
      blobs: [
        _svgPath(
            'M4 4Q4 1 8 2L48 8Q51 9 51 13V36Q51 40 47 39L6 33Q3 32 3 29Z'),
        _svgPath('M24 32V43L13 46L29 51L42 47L31 43V31'),
      ],
    );
  }

  final stand = _svgPath('M24 32V43L13 46L29 51L42 47L31 43V31');
  canvas.drawPath(stand, _edgeFill(stand));
  final bodyEdge = _svgPath(
      'M4 4Q4 1 8 2L48 8Q51 9 51 13V36Q51 40 47 39L6 33Q3 32 3 29Z');
  canvas.drawPath(bodyEdge, _edgeFill(bodyEdge));
  final face = _svgPath('M5 3L47 9Q49 9 49 13V33Q49 36 46 35L6 29Z');
  canvas.drawPath(face, _paperFill(face));
  final screen = _svgPath('M9 8L44 13V28L9 23Z');
  canvas.drawPath(screen, _screenFill(screen));
  _paintStroke(
      canvas,
      'M16 17L24 18M28 19L36 20',
      _flatStroke(const Color(0xFFAD99E1), 2));
  _paintDot(canvas, const Offset(27, 31), 1, const Color(0xFF9B89BB));
  _paintStroke(
      canvas,
      'M14 46L29 49L40 46',
      _flatStroke(const Color(0xFFEEE9F7), 1.5));
}

void _paintLaptop(Canvas canvas, {required bool contactShadow}) {
  if (contactShadow) {
    _paintContactShadow(
      canvas,
      blobs: [
        _svgPath(
            'M5 76L87 61L115 77Q119 80 113 82L35 98Q31 99 27 97L3 83Q0 81 5 76Z'),
        _svgPath(
            'M28 78L106 64L96 5Q95 0 89 1L13 14Q9 15 10 20L20 74Q21 80 28 78Z'),
      ],
    );
  }

  final baseEdge = _svgPath(
      'M5 76L87 61L115 77Q119 80 113 82L35 98Q31 99 27 97L3 83Q0 81 5 76Z');
  canvas.drawPath(baseEdge, _edgeFill(baseEdge));
  final baseTop = _svgPath('M5 76L86 62L115 76L32 93L3 80Z');
  canvas.drawPath(baseTop, _paperFill(baseTop));
  canvas.drawPath(
      _svgPath('M20 76L83 65L98 73L34 85Z'),
      _flatPaint(const Color(0xFFB6A8D0)));
  canvas.drawPath(
      _svgPath('M39 86L60 82L67 85L46 89Z'),
      _flatPaint(const Color(0xFFD9CFEB)));
  final lidEdge = _svgPath(
      'M28 78L106 64L96 5Q95 0 89 1L13 14Q9 15 10 20L20 74Q21 80 28 78Z');
  canvas.drawPath(lidEdge, _edgeFill(lidEdge));
  final lidScreen = _svgPath('M24 73L101 60L92 7L15 20Z');
  canvas.drawPath(lidScreen, _screenFill(lidScreen));
  _paintStroke(
      canvas, 'M21 21L90 9', _flatStroke(const Color(0xFFA28ABD), 1,
          opacity: 0.35));
  _paintStroke(
      canvas,
      'M42 47L62 43L81 48M62 43V28M62 43V59',
      _flatStroke(const Color(0xFFB9A4E8), 2));
  for (final node in const [
    Offset(42, 47),
    Offset(81, 48),
    Offset(62, 28),
  ]) {
    _paintDot(canvas, node, 3.5, const Color(0xFF9CD7BF));
  }
  _paintDot(canvas, const Offset(62, 43), 5, const Color(0xFFD7C7F6));
  _paintDot(canvas, const Offset(62, 59), 3.5, const Color(0xFF9CD7BF));
}

// ─────────────────────────────────────────────────────────────────────────────
// Scene painters (viewBox 360×290)
// ─────────────────────────────────────────────────────────────────────────────

void _runTransformed(
  Canvas canvas, {
  required double dx,
  required double dy,
  double scale = 1,
  double degrees = 0,
  required VoidCallback paint,
}) {
  canvas.save();
  canvas.translate(dx, dy);
  if (degrees != 0) {
    canvas.rotate(degrees * math.pi / 180);
  }
  if (scale != 1) {
    canvas.scale(scale, scale);
  }
  paint();
  canvas.restore();
}

void _paintStudentScene(Canvas canvas) {
  // Ambient washes.
  _paintAmbient(canvas, const Offset(181, 155), 146, 121);
  _paintAmbient(canvas, const Offset(180, 268), 131, 17);

  // Thin dashed connectors.
  final connectors = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFB8A6D9);
  canvas.drawPath(
    _dashedStrokePath(
      _svgPath('M59 139V94Q59 81 72 81H120M219 66H264Q282 66 282 82V113'),
      4,
      5,
    ),
    connectors,
  );
  canvas.drawPath(
    _svgPath('M75 220H47Q33 220 33 205V178M271 219H310Q321 219 321 206V165'),
    connectors,
  );

  // Router + side computer with their contact shadows.
  _runTransformed(
    canvas,
    dx: 242,
    dy: 59,
    scale: 0.77,
    paint: () => _paintRouterDevice(canvas, contactShadow: true),
  );
  _runTransformed(
    canvas,
    dx: 275,
    dy: 129,
    scale: 0.78,
    paint: () => _paintComputer(canvas, contactShadow: true),
  );

  // Wi-Fi arcs above the laptop area.
  final wifi = _svgPath('M0 0Q16 -16 32 0M6 7Q16 -3 26 7M12 14Q16 10 20 14');
  canvas.save();
  canvas.translate(48, 109);
  canvas.drawPath(wifi, _purpleStrokePaint(wifi, 4));
  _paintDot(canvas, const Offset(16, 21), 2, const Color(0xFF8A70C5));
  canvas.restore();

  // The seated student, desk and laptop (one shared contact shadow group).
  final torsoBack = _svgPath(
      'M117 181Q109 174 108 187V225Q109 243 125 246H192Q209 245 209 226V187Z');
  final body = _svgPath(
      'M143 138Q157 130 181 135Q203 139 207 169L203 206Q180 218 142 207L132 164Z');
  final navyShoe = _svgPath(
      'M145 206Q156 205 168 211L185 241L173 254L153 231L139 227Z');
  final deskEdge = _svgPath(
      'M70 211L223 188Q229 187 234 190L274 209Q280 213 273 215L121 241Q116 242 112 239L69 219Q62 215 70 211Z');
  final laptopLid = _svgPath(
      'M28 78L106 64L96 5Q95 0 89 1L13 14Q9 15 10 20L20 74Q21 80 28 78Z');
  final legs = _svgPath('M127 237L123 269M192 237L201 268');
  final armLeft = _svgPath(
      'M150 145Q140 148 132 164L116 183Q112 190 120 193L144 199');
  final armRight = _svgPath(
      'M191 148Q201 155 206 168L222 185Q226 191 218 193L194 197');
  _paintContactShadow(
    canvas,
    blobs: [torsoBack, body, navyShoe, deskEdge, laptopLid],
    strokes: [
      StrokeShadow(legs, 8),
      StrokeShadow(armLeft, 19),
      StrokeShadow(armRight, 18),
    ],
  );

  canvas.drawPath(torsoBack, _purpleFill(torsoBack));
  _paintStroke(canvas, 'M127 237L123 269M192 237L201 268',
      _flatStroke(const Color(0xFF9279BD), 8));
  canvas.drawPath(navyShoe, _navyFill(navyShoe));
  final paperShoe = _svgPath(
      'M173 252L183 248L193 255Q198 261 192 263L177 263Q169 262 173 252Z');
  canvas.drawPath(paperShoe, _paperFill(paperShoe));
  canvas.drawPath(body, _purpleFill(body));
  _paintStroke(
      canvas,
      'M151 141L164 152L181 139M164 152V186',
      _flatStroke(const Color(0xFFD0C0F0), 2.5));
  canvas.drawPath(armLeft, _purpleStrokePaint(armLeft, 19));
  canvas.drawPath(armRight, _purpleStrokePaint(armRight, 18));
  final hands = _svgPath('M126 188L150 194M214 189L192 194');
  canvas.drawPath(
      hands, _skinStrokePaint(hands, 10));
  final fingers = _svgPath(
      'M149 190Q157 189 162 196L159 200L145 198M194 190L182 194L183 199L196 198');
  _skinFillPaint(canvas, fingers);
  final neck = _svgPath('M156 124V141Q164 150 175 141V121Z');
  _skinFillPaint(canvas, neck);
  canvas.drawPath(
      _svgPath('M157 132Q165 136 175 131V123H157Z'),
      _flatPaint(const Color(0xFFBB8774), 0.35));
  _skinFillPaint(canvas, Path()..addOval(Rect.fromCenter(
      center: const Offset(145, 108), width: 10, height: 16)));
  _skinFillPaint(canvas, Path()..addOval(Rect.fromCenter(
      center: const Offset(190, 107), width: 10, height: 16)));
  final head = _svgPath(
      'M145 92Q146 71 167 70Q190 69 192 92L188 117Q183 133 169 134Q153 132 147 118Z');
  _skinFillPaint(canvas, head);
  final hair = _svgPath(
      'M144 111Q134 99 140 81Q144 62 165 62Q190 59 198 79Q202 95 191 109L187 89Q173 90 160 79Q158 97 146 102Z');
  canvas.drawPath(hair, _navyFill(hair));
  _paintStroke(
      canvas,
      'M145 82Q149 68 166 68Q181 65 189 76',
      _flatStroke(const Color(0xFF6E5687), 2.5, opacity: 0.55));
  _paintStroke(
      canvas, 'M155 104L159 104M176 104L180 103',
      _flatStroke(const Color(0xFF57404B), 2));
  _paintStroke(
      canvas, 'M168 106L166 114L170 115',
      _flatStroke(const Color(0xFFCB9C86), 1.5));
  _paintStroke(
      canvas, 'M162 121Q169 124 175 120',
      _flatStroke(const Color(0xFFAC7468), 1.5));
  canvas.drawPath(deskEdge, _edgeFill(deskEdge));
  final deskTop = _svgPath(
      'M68 210L223 187Q229 187 234 189L274 207Q280 210 273 212L120 236Q116 237 111 235L68 216Q62 213 68 210Z');
  canvas.drawPath(deskTop, _paperFill(deskTop));
  final deskLegs = _svgPath('M90 229V270M253 220V259');
  final deskLegPaint = _edgeFill(deskLegs)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(deskLegs, deskLegPaint);
  canvas.drawPath(
      Path()..addOval(Rect.fromCenter(
          center: const Offset(189, 211), width: 110, height: 18)),
      _flatPaint(const Color(0xFF84709E), 0.12));
  _runTransformed(
    canvas,
    dx: 127,
    dy: 135,
    scale: 0.91,
    paint: () => _paintLaptop(canvas, contactShadow: false),
  );

  // Ethernet cable plug detail.
  canvas.save();
  canvas.translate(50, 231);
  _paintStroke(
      canvas, 'M0 9Q-13 22 6 27H25Q39 27 37 15',
      _flatStroke(const Color(0xFF9A84C0), 3));
  final plug = _svgPath('M33 7L43 8L42 19L32 18Z');
  canvas.drawPath(plug, _paperFill(plug));
  canvas.drawPath(plug,
      _flatStroke(const Color(0xFFA08ABA), 1.5));
  _paintStroke(
      canvas, 'M36 8V12M39 8V12',
      _flatStroke(const Color(0xFF8BBDA8), 1.5));
  canvas.restore();

  // Green connection dots (white ring under a green disc, like fill + stroke).
  _paintWhiteRingDots(canvas, const [
    Offset(59, 81),
    Offset(282, 113),
    Offset(321, 189),
  ], 4, 2, const Color(0xFFA2D6C0));
}

/// Small decorative dots rendered as `<circle fill=green stroke=#fff>`: a
/// white disc slightly larger under the colored disc.
void _paintWhiteRingDots(
  Canvas canvas,
  List<Offset> centers,
  double radius,
  double strokeWidth,
  Color fill,
) {
  for (final center in centers) {
    final outer = radius + strokeWidth / 2;
    canvas.drawCircle(center, outer, _flatPaint(const Color(0xFFFFFFFF)));
    canvas.drawCircle(center, radius, _flatPaint(fill));
  }
}

void _paintNetworkScene(Canvas canvas) {
  _paintAmbient(canvas, const Offset(181, 155), 136, 111);
  _paintStroke(
      canvas,
      'M95 184L179 152L265 184M179 152V84',
      _flatStroke(const Color(0xFFA892CF), 4));

  _runTransformed(
    canvas,
    dx: 118,
    dy: 104,
    scale: 1.3,
    paint: () => _paintRouterDevice(canvas, contactShadow: true),
  );
  _runTransformed(
    canvas,
    dx: 57,
    dy: 164,
    scale: 1.1,
    paint: () => _paintComputer(canvas, contactShadow: true),
  );
  _runTransformed(
    canvas,
    dx: 243,
    dy: 164,
    scale: 1.1,
    paint: () => _paintComputer(canvas, contactShadow: true),
  );
  _runTransformed(
    canvas,
    dx: 151,
    dy: 36,
    scale: 1.1,
    paint: () => _paintComputer(canvas, contactShadow: true),
  );

  _paintWhiteRingDots(
    canvas,
    const [Offset(112, 177), Offset(243, 176), Offset(179, 97)],
    5,
    2,
    const Color(0xFF9ED3BB),
  );
}

void _paintJourneyScene(Canvas canvas) {
  _paintAmbient(canvas, const Offset(181, 157), 140, 112);
  _paintAmbient(canvas, const Offset(180, 246), 124, 19);

  canvas.drawPath(
    _dashedStrokePath(
      _svgPath('M99 178V92Q99 78 115 78H189M165 212H265Q281 212 281 197V125'),
      5,
      6,
    ),
    _flatStroke(const Color(0xFFB4A0D7), 3),
  );

  // Assessment checklist card.
  final checklistBack =
      _roundedRect(4, 4, 99, 139, 14);
  final checklistFront = _roundedRect(0, 0, 99, 139, 14);
  _paintContactShadow(
      canvas, blobs: [checklistBack, checklistFront]);
  _runTransformed(
    canvas,
    dx: 176,
    dy: 42,
    degrees: 8,
    paint: () {
      canvas.drawPath(checklistBack, _edgeFill(checklistBack));
      canvas.drawPath(checklistFront, _paperFill(checklistFront));
      final clip = _roundedRect(27, -5, 45, 17, 6);
      canvas.drawPath(clip, _purpleFill(clip));
      for (final y in const [35.0, 66.0, 97.0]) {
        canvas.drawPath(_roundedRect(15, y, 15, 15, 4),
            _flatPaint(const Color(0xFFE8E0F5)));
        _paintStroke(
            canvas,
            'M19 ${y + 7}l3 3 5 -6',
            _flatStroke(const Color(0xFF7E62B9), 2));
        _paintStroke(
            canvas,
            'M41 ${y + 4}h34M41 ${y + 12}h23',
            _flatStroke(const Color(0xFFC4B6DA), 4));
      }
    },
  );

  // Learning laptop.
  _runTransformed(
    canvas,
    dx: 56,
    dy: 123,
    scale: 1.28,
    paint: () => _paintLaptop(canvas, contactShadow: true),
  );

  // Results chart card.
  final chartBack = _roundedRect(3, 4, 86, 72, 13);
  final chartFront = _roundedRect(0, 0, 86, 72, 13);
  _paintContactShadow(canvas, blobs: [chartBack, chartFront]);
  _runTransformed(
    canvas,
    dx: 220,
    dy: 164,
    degrees: -7,
    paint: () {
      canvas.drawPath(chartBack, _edgeFill(chartBack));
      canvas.drawPath(chartFront, _paperFill(chartFront));
      _paintStroke(canvas, 'M17 53H70',
          _flatStroke(const Color(0xFFD9CEE8), 3));
      final bar1 = _roundedRect(20, 37, 9, 14, 3);
      canvas.drawPath(bar1, _flatPaint(const Color(0xFFB9A4DE)));
      final bar2 = _roundedRect(36, 27, 9, 24, 3);
      canvas.drawPath(bar2, _flatPaint(const Color(0xFF9C80CD)));
      final bar3 = _roundedRect(52, 15, 9, 36, 3);
      canvas.drawPath(bar3, _purpleFill(bar3));
      _paintDot(canvas, const Offset(71, 12), 14,
          const Color(0xFFB5DFCB));
      _paintStroke(canvas, 'M65 12l4 4 8 -9',
          _flatStroke(const Color(0xFF3C7761), 3));
    },
  );

  _paintWhiteRingDots(
    canvas,
    const [Offset(100, 92), Offset(283, 135)],
    6,
    3,
    const Color(0xFF9ED3BB),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Module illustrations (viewBox 80×56)
// ─────────────────────────────────────────────────────────────────────────────

void _paintModule(Canvas canvas, int module) {
  switch (module) {
    case 0:
      // Dasar-Dasar Jaringan — computers joined through a central node.
      _paintStroke(
          canvas, 'M17 39L40 29L64 39M40 29V14',
          _flatStroke(const Color(0xFF9F87C4), 2.5, cap: StrokeCap.butt,
              join: StrokeJoin.miter));
      _runTransformed(
          canvas, dx: 2, dy: 25, scale: 0.43,
          paint: () => _paintComputer(canvas, contactShadow: false));
      _runTransformed(
          canvas, dx: 54, dy: 25, scale: 0.43,
          paint: () => _paintComputer(canvas, contactShadow: false));
      _runTransformed(
          canvas, dx: 28, dy: 0, scale: 0.43,
          paint: () => _paintComputer(canvas, contactShadow: false));
      final hub = _circlePath(const Offset(40, 29), 4.5);
      canvas.drawPath(hub, _purpleFill(hub));
      _paintDot(canvas, const Offset(40, 29), 2,
          const Color(0xFFB5DFCB));
    case 1:
      // Perangkat Jaringan — the router with its port bank (includes the
      // RouterDevice's own ambient ground ellipse, exactly like the SVG).
      _runTransformed(
          canvas, dx: 4, dy: 5, scale: 0.78,
          paint: () => _paintRouterDevice(canvas, contactShadow: false));
    case 2:
      // Topologi Jaringan — star topology diagram.
      _paintStroke(
          canvas,
          'M40 27L15 9M40 27L65 9M40 27L15 47M40 27L65 47',
          _flatStroke(const Color(0xFFAD97CC), 2.5));
      for (final rect in const [
        Offset(6, 2),
        Offset(55, 2),
        Offset(6, 40),
        Offset(55, 40),
      ]) {
        final leaf = _roundedRect(rect.dx, rect.dy, 19, 13, 3);
        canvas.drawPath(leaf, _paperFill(leaf));
        canvas.drawPath(leaf, _flatStroke(const Color(0xFFAA91C7), 2));
      }
      final center = _roundedRect(30, 17, 20, 20, 6);
      canvas.drawPath(center, _purpleFill(center));
      _paintDot(canvas, const Offset(40, 27), 4, const Color(0xFFB5DFCB));
    case 3:
      // IP Address — address card octets.
      final cardBack = _roundedRect(7, 7, 66, 43, 9);
      canvas.drawPath(cardBack, _edgeFill(cardBack));
      final cardFront = _roundedRect(5, 4, 66, 43, 9);
      canvas.drawPath(cardFront, _paperFill(cardFront));
      _paintStroke(canvas, 'M16 15H29',
          _flatStroke(const Color(0xFF9479BF), 4));
      for (final x in const [15.0, 28.0, 41.0, 54.0]) {
        final octet = _roundedRect(x, 26, 9, 10, 2);
        canvas.drawPath(octet, _purpleFill(octet));
        if (x < 54) {
          _paintDot(canvas, Offset(x + 11, 34), 1,
              const Color(0xFF7B629D));
        }
      }
      _paintDot(canvas, const Offset(59, 14), 4, const Color(0xFF9ED3BB));
    default:
      break;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cross-feature reuse facade for the material thumbnails (see
// lib/shared/widgets/nl_material_thumbnail.dart). The network components
// (RouterDevice / Computer / Laptop) and the painting primitives were first
// drawn for the onboarding scenes; the material banner thumbnails compose the
// same components, and this public wrapper keeps their geometry defined in
// exactly one place.
// ─────────────────────────────────────────────────────────────────────────────

Paint netArtPurpleFill(Path shape) => _purpleFill(shape);
Paint netArtPaperFill(Path shape) => _paperFill(shape);
Paint netArtEdgeFill(Path shape) => _edgeFill(shape);

Paint netArtFlatPaint(Color color, [double opacity = 1]) =>
    _flatPaint(color, opacity);

Paint netArtFlatStroke(
  Color color,
  double width, {
  double opacity = 1,
  StrokeCap cap = StrokeCap.round,
  StrokeJoin join = StrokeJoin.round,
}) =>
    _flatStroke(color, width, opacity: opacity, cap: cap, join: join);

void netArtStroke(Canvas canvas, String data, Paint paint) =>
    _paintStroke(canvas, data, paint);

void netArtDot(Canvas canvas, Offset center, double radius, Color color) =>
    _paintDot(canvas, center, radius, color);

/// The `<ellipse … fill=ambient>` ground glow (see [_paintAmbient]).
void netArtAmbient(Canvas canvas, Offset center, double rx, double ry) =>
    _paintAmbient(canvas, center, rx, ry);

void netArtContactShadow(
  Canvas canvas, {
  List<Path> blobs = const [],
  List<StrokeShadow> strokes = const [],
}) =>
    _paintContactShadow(canvas, blobs: blobs, strokes: strokes);

Path netArtDashedPath(Path source, double dash, double gap) =>
    _dashedStrokePath(source, dash, gap);

Path netArtRoundedRect(
        double x, double y, double width, double height, double radius) =>
    _roundedRect(x, y, width, height, radius);

void netArtRouterDevice(Canvas canvas, {required bool contactShadow}) =>
    _paintRouterDevice(canvas, contactShadow: contactShadow);

void netArtComputer(Canvas canvas, {required bool contactShadow}) =>
    _paintComputer(canvas, contactShadow: contactShadow);

void netArtLaptop(Canvas canvas, {required bool contactShadow}) =>
    _paintLaptop(canvas, contactShadow: contactShadow);

void netArtTransformed(
  Canvas canvas, {
  required double dx,
  required double dy,
  double scale = 1,
  double degrees = 0,
  required VoidCallback paint,
}) =>
    _runTransformed(canvas,
        dx: dx, dy: dy, scale: scale, degrees: degrees, paint: paint);
