import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'config.dart';
import 'document.dart';

class StrategyCanvasPainter extends CustomPainter {
  StrategyCanvasPainter({required this.elements, this.preview});

  final List<StrategyElement> elements;
  final StrategyStroke? preview;

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      switch (element) {
        case StrategyStroke():
          _drawStroke(canvas, size, element);
        case StrategyText():
          _drawText(canvas, size, element);
        case StrategyMarker():
          break;
      }
    }
    if (preview != null) _drawStroke(canvas, size, preview!);
  }

  void _drawStroke(Canvas canvas, Size size, StrategyStroke stroke) {
    if (stroke.points.isEmpty) return;
    final points = stroke.points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList();
    final bounds = _pointsBounds(points);
    final center = bounds.center;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(stroke.rotation);
    canvas.scale(stroke.scale);
    canvas.translate(-center.dx, -center.dy);
    final paint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      canvas.restore();
      return;
    }

    if (stroke.kind == StrategyToolKind.rectangle ||
        stroke.kind == StrategyToolKind.filledRectangle) {
      canvas.drawRect(
        Rect.fromPoints(points.first, points.last),
        stroke.kind == StrategyToolKind.filledRectangle
            ? (paint..style = PaintingStyle.fill)
            : paint,
      );
      canvas.restore();
      return;
    }
    if (stroke.kind == StrategyToolKind.ellipse ||
        stroke.kind == StrategyToolKind.filledEllipse) {
      canvas.drawOval(
        Rect.fromPoints(points.first, points.last),
        stroke.kind == StrategyToolKind.filledEllipse
            ? (paint..style = PaintingStyle.fill)
            : paint,
      );
      canvas.restore();
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (_followsGesture(stroke.kind)) {
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    } else {
      path.lineTo(points.last.dx, points.last.dy);
    }

    if (stroke.kind == StrategyToolKind.wave) {
      canvas.drawPath(_wavePath(path, stroke.width), paint);
    } else if (stroke.kind == StrategyToolKind.backwards) {
      _drawBackwardMarks(canvas, path, paint);
    } else if (stroke.kind == StrategyToolKind.lateral ||
        stroke.kind == StrategyToolKind.lateralStop) {
      _drawLateralPath(canvas, points, paint);
    } else if (_usesFreehandDashes(stroke.kind)) {
      _drawDashedPath(
        canvas,
        path,
        paint,
        dash: math.max(5, stroke.width * 2),
        gap: math.max(7, stroke.width * 3),
      );
    } else if (_usesStraightDashes(stroke.kind)) {
      _drawDashedPath(
        canvas,
        path,
        paint,
        dash: math.max(8, stroke.width * 4),
        gap: math.max(6, stroke.width * 3),
      );
    } else {
      canvas.drawPath(path, paint);
    }

    final directionSample = math.max(12.0, stroke.width * 4);
    final end = resolveEndArrowAnchor(path, directionSample);
    if (stroke.kind == StrategyToolKind.lateral ||
        stroke.kind == StrategyToolKind.lateralStop) {
      _drawLateralEndpoint(
        canvas,
        points,
        paint,
        stop: stroke.kind == StrategyToolKind.lateralStop,
      );
    } else if (_hasEndArrow(stroke.kind) && end != null) {
      _drawArrowHead(canvas, end.position, end.direction, paint);
    }
    if (_hasStartArrow(stroke.kind)) {
      final start = resolveStartArrowAnchor(path, directionSample);
      if (start != null) {
        _drawArrowHead(
          canvas,
          start.position,
          start.direction + math.pi,
          paint,
        );
      }
    }
    if (_hasStopBars(stroke.kind) && end != null) {
      _drawStopBars(canvas, end.position, end.direction, paint);
    }
    canvas.restore();
  }

  Rect _pointsBounds(List<Offset> points) {
    var minX = points.first.dx;
    var maxX = minX;
    var minY = points.first.dy;
    var maxY = minY;
    for (final point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool _followsGesture(StrategyToolKind kind) => switch (kind) {
        StrategyToolKind.freehand ||
        StrategyToolKind.freehandArrow ||
        StrategyToolKind.freehandDashedArrow ||
        StrategyToolKind.freehandStopArrow ||
        StrategyToolKind.lateral ||
        StrategyToolKind.lateralStop ||
        StrategyToolKind.backwards ||
        StrategyToolKind.wave ||
        StrategyToolKind.doubleArrow ||
        StrategyToolKind.dashedDoubleArrow =>
          true,
        _ => false,
      };

  bool _usesFreehandDashes(StrategyToolKind kind) =>
      kind == StrategyToolKind.freehandDashedArrow ||
      kind == StrategyToolKind.dashedDoubleArrow;

  bool _usesStraightDashes(StrategyToolKind kind) =>
      kind == StrategyToolKind.dashedLine ||
      kind == StrategyToolKind.dashedArrow ||
      kind == StrategyToolKind.dashedStopArrow;

  bool _hasEndArrow(StrategyToolKind kind) => switch (kind) {
        StrategyToolKind.arrow ||
        StrategyToolKind.stopArrow ||
        StrategyToolKind.dashedArrow ||
        StrategyToolKind.dashedStopArrow ||
        StrategyToolKind.doubleArrow ||
        StrategyToolKind.dashedDoubleArrow ||
        StrategyToolKind.freehandArrow ||
        StrategyToolKind.freehandDashedArrow ||
        StrategyToolKind.freehandStopArrow =>
          true,
        _ => false,
      };

  bool _hasStartArrow(StrategyToolKind kind) =>
      kind == StrategyToolKind.doubleArrow ||
      kind == StrategyToolKind.dashedDoubleArrow;

  bool _hasStopBars(StrategyToolKind kind) => switch (kind) {
        StrategyToolKind.stopArrow ||
        StrategyToolKind.dashedStopArrow ||
        StrategyToolKind.freehandStopArrow =>
          true,
        _ => false,
      };

  Path _wavePath(Path path, double width) {
    final result = Path();
    final amplitude = math.max(2.0, width * 1.5);
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance <= metric.length; distance += 4) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) continue;
        final angle = tangent.angle + math.pi / 2;
        final offset = math.sin(distance / 8) * amplitude;
        final point = tangent.position +
            Offset(offset * math.cos(angle), offset * math.sin(angle));
        if (distance == 0) {
          result.moveTo(point.dx, point.dy);
        } else {
          result.lineTo(point.dx, point.dy);
        }
      }
    }
    return result;
  }

  void _drawLateralPath(Canvas canvas, List<Offset> points, Paint paint) {
    final dash = 22 * paint.strokeWidth / 35;
    final gap = 30 * paint.strokeWidth / 15;
    for (var index = 0; index + 5 < points.length; index += 5) {
      final segment = Path()
        ..moveTo(points[index].dx, points[index].dy)
        ..lineTo(points[index + 5].dx, points[index + 5].dy);
      _drawDashedPath(canvas, segment, paint, dash: dash, gap: gap);
    }
  }

  void _drawLateralEndpoint(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    required bool stop,
  }) {
    final anchor = resolveSampledEndArrowAnchor(points, 5);
    if (anchor == null) return;
    if (stop) {
      _drawLegacyStopHead(canvas, anchor.position, anchor.direction, paint);
    } else {
      _drawLegacyArrowHead(canvas, anchor.position, anchor.direction, paint);
    }
  }

  void _drawLegacyArrowHead(
    Canvas canvas,
    Offset tip,
    double direction,
    Paint paint,
  ) {
    final length = 27 * paint.strokeWidth / 16;
    final halfHeight = 17 * paint.strokeWidth / 16;
    _drawClosedHead(canvas, tip, direction, length, halfHeight, paint);
  }

  void _drawLegacyStopHead(
    Canvas canvas,
    Offset tip,
    double direction,
    Paint paint,
  ) {
    _drawClosedHead(
      canvas,
      tip,
      direction,
      paint.strokeWidth,
      2 * paint.strokeWidth / 3,
      paint,
    );
    final forward = Offset(math.cos(direction), math.sin(direction));
    final normal = Offset(-forward.dy, forward.dx);
    for (final offset in const [2.1, 4.1]) {
      final center = tip + forward * offset;
      canvas.drawLine(center - normal * 3.8, center + normal * 3.8, paint);
    }
  }

  void _drawClosedHead(
    Canvas canvas,
    Offset tip,
    double direction,
    double length,
    double halfHeight,
    Paint paint,
  ) {
    final forward = Offset(math.cos(direction), math.sin(direction));
    final normal = Offset(-forward.dy, forward.dx);
    final base = tip - forward * length;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          (base + normal * halfHeight).dx,
          (base + normal * halfHeight).dy,
        )
        ..lineTo(
          (base - normal * halfHeight).dx,
          (base - normal * halfHeight).dy,
        )
        ..close(),
      paint,
    );
  }

  void _drawBackwardMarks(Canvas canvas, Path path, Paint paint) {
    final markPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    const markLength = 7.0;
    final gap = math.max(7.0, paint.strokeWidth * 3);
    final interval = markLength + gap;
    for (final metric in path.computeMetrics()) {
      for (var distance = markLength / 2;
          distance < metric.length;
          distance += interval) {
        final center = metric.getTangentForOffset(distance);
        final before = metric.getTangentForOffset(
          math.max(0, distance - markLength / 2),
        );
        final after = metric.getTangentForOffset(
          math.min(metric.length, distance + markLength / 2),
        );
        if (center == null || before == null || after == null) continue;
        final directionVector = after.position - before.position;
        final direction = directionVector.distanceSquared > .01
            ? directionVector.direction
            : center.angle;
        canvas.save();
        canvas.translate(center.position.dx, center.position.dy);
        canvas.rotate(direction);
        canvas.scale(markLength / 1120, -markLength / 830);
        canvas.translate(-560, -415);
        canvas.drawPath(_backwardsMark, markPaint);
        canvas.restore();
      }
    }
  }

  static final Path _backwardsMark = Path()
    ..moveTo(398, 784)
    ..relativeCubicTo(-85, -26, -152, -82, -211, -177)
    ..relativeCubicTo(-10, -15, -19, -51, -20, -80)
    ..relativeLineTo(-2, -52)
    ..relativeLineTo(50, 0)
    ..relativeLineTo(49, 0)
    ..relativeLineTo(11, 41)
    ..relativeCubicTo(21, 84, 103, 155, 194, 170)
    ..relativeCubicTo(32, 5, 52, 1, 95, -20)
    ..relativeCubicTo(62, -30, 126, -95, 126, -129)
    ..relativeCubicTo(0, -59, 9, -67, 67, -67)
    ..relativeLineTo(55, 0)
    ..relativeLineTo(-7, 48)
    ..relativeCubicTo(-12, 89, -82, 191, -157, 229)
    ..relativeCubicTo(-56, 28, -139, 53, -175, 52)
    ..relativeCubicTo(-15, 0, -49, -7, -75, -15)
    ..close()
    ..moveTo(447, 354)
    ..relativeCubicTo(-14, -14, -7, -100, 11, -131)
    ..relativeCubicTo(76, -141, 194, -200, 361, -180)
    ..relativeCubicTo(92, 11, 135, 38, 206, 128)
    ..relativeCubicTo(47, 60, 50, 67, 50, 124)
    ..relativeLineTo(0, 60)
    ..relativeLineTo(-38, 3)
    ..relativeCubicTo(-50, 4, -61, -7, -76, -73)
    ..relativeCubicTo(-10, -43, -20, -60, -49, -83)
    ..relativeCubicTo(-59, -47, -97, -62, -154, -62)
    ..relativeCubicTo(-104, 1, -180, 63, -203, 164)
    ..relativeLineTo(-11, 51)
    ..relativeLineTo(-45, 3)
    ..relativeCubicTo(-25, 2, -48, 0, -52, -4)
    ..close();

  void _drawStopBars(Canvas canvas, Offset tip, double direction, Paint paint) {
    final forward = Offset(math.cos(direction), math.sin(direction));
    final normal = Offset(-forward.dy, forward.dx);
    final halfHeight = math.max(6.0, paint.strokeWidth * 2.5);
    final firstOffset = math.max(3.0, paint.strokeWidth * 1.25);
    final barGap = math.max(3.0, paint.strokeWidth * 1.25);
    for (final offset in [firstOffset, firstOffset + barGap]) {
      final center = tip + forward * offset;
      canvas.drawLine(
        center - normal * halfHeight,
        center + normal * halfHeight,
        paint,
      );
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      for (double distance = 0;
          distance < metric.length;
          distance += dash + gap) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint) {
    final length = math.max(10.0, paint.strokeWidth * 4);
    const spread = math.pi / 6;
    final left = tip -
        Offset(
          length * math.cos(angle - spread),
          length * math.sin(angle - spread),
        );
    final right = tip -
        Offset(
          length * math.cos(angle + spread),
          length * math.sin(angle + spread),
        );
    canvas.drawLine(tip, left, paint);
    canvas.drawLine(tip, right, paint);
  }

  void _drawText(Canvas canvas, Size size, StrategyText element) {
    final painter = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: Color(element.color),
          fontSize: element.fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    final origin = Offset(
      element.position.dx * size.width,
      element.position.dy * size.height,
    );
    final center = origin + Offset(painter.width / 2, painter.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(element.rotation);
    canvas.scale(element.scale);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StrategyCanvasPainter oldDelegate) =>
      oldDelegate.elements != elements || oldDelegate.preview != preview;
}

@visibleForTesting
({Offset position, double direction})? resolveStartArrowAnchor(
  Path path,
  double sampleDistance,
) {
  for (final metric in path.computeMetrics()) {
    if (metric.length <= 0) continue;
    final tip = metric.getTangentForOffset(0);
    final ahead = metric.getTangentForOffset(
      math.min(metric.length, sampleDistance),
    );
    if (tip == null || ahead == null) continue;
    final vector = ahead.position - tip.position;
    return (
      position: tip.position,
      direction: vector.distanceSquared > .01 ? vector.direction : tip.angle,
    );
  }
  return null;
}

@visibleForTesting
({Offset position, double direction})? resolveEndArrowAnchor(
  Path path,
  double sampleDistance,
) {
  ({Offset position, double direction})? result;
  for (final metric in path.computeMetrics()) {
    if (metric.length <= 0) continue;
    final tip = metric.getTangentForOffset(metric.length) ??
        metric.getTangentForOffset(math.max(0, metric.length - .001));
    final behind = metric.getTangentForOffset(
      math.max(0, metric.length - sampleDistance),
    );
    if (tip == null || behind == null) continue;
    final vector = tip.position - behind.position;
    result = (
      position: tip.position,
      direction: vector.distanceSquared > .01 ? vector.direction : tip.angle,
    );
  }
  return result;
}

@visibleForTesting
({Offset position, double direction})? resolveSampledEndArrowAnchor(
  List<Offset> points,
  int stride,
) {
  if (stride <= 0) throw ArgumentError.value(stride, 'stride');
  final endIndex = ((points.length - 1) ~/ stride) * stride;
  if (endIndex < stride) return null;
  final tip = points[endIndex];
  for (var index = endIndex - stride; index >= 0; index -= stride) {
    final vector = tip - points[index];
    if (vector.distanceSquared > .01) {
      return (position: tip, direction: vector.direction);
    }
  }
  return null;
}
