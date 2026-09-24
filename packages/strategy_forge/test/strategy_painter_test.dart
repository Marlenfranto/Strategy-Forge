import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:strategy_forge/strategy_forge.dart';
import 'package:strategy_forge/src/strategy_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(260, 160);
const _points = [
  ui.Offset(.10, .62),
  ui.Offset(.13, .52),
  ui.Offset(.16, .40),
  ui.Offset(.19, .30),
  ui.Offset(.22, .24),
  ui.Offset(.25, .33),
  ui.Offset(.28, .45),
  ui.Offset(.31, .58),
  ui.Offset(.34, .68),
  ui.Offset(.38, .70),
  ui.Offset(.42, .62),
  ui.Offset(.46, .50),
  ui.Offset(.50, .38),
  ui.Offset(.55, .28),
  ui.Offset(.60, .35),
  ui.Offset(.65, .50),
  ui.Offset(.70, .64),
  ui.Offset(.75, .60),
  ui.Offset(.80, .52),
  ui.Offset(.84, .46),
  ui.Offset(.88, .42),
];

void main() {
  test('arrow anchors use stable path directions and exact endpoints', () {
    final endPath = ui.Path()
      ..moveTo(20, 80)
      ..lineTo(180, 80)
      ..lineTo(180.5, 82);
    final end = resolveEndArrowAnchor(endPath, 16)!;
    expect(end.position.dx, closeTo(180.5, .01));
    expect(end.position.dy, closeTo(82, .01));
    expect(end.direction.abs(), lessThan(.3));

    final startPath = ui.Path()
      ..moveTo(20, 80)
      ..lineTo(20.5, 82)
      ..lineTo(180, 82);
    final start = resolveStartArrowAnchor(startPath, 16)!;
    expect(start.position, const ui.Offset(20, 80));
    expect(start.direction.abs(), lessThan(.3));
  });

  test('lateral arrow anchor uses the final rendered five-point segment', () {
    final points = List.generate(
      18,
      (index) => ui.Offset(index * 10, index.isEven ? 20 : 24),
    );
    final anchor = resolveSampledEndArrowAnchor(points, 5)!;
    final expectedDirection = (points[15] - points[10]).direction;

    expect(anchor.position, points[15]);
    expect(anchor.direction, closeTo(expectedDirection, .0001));
  });

  test(
    'legacy line variants render distinct path and endpoint styles',
    () async {
      const kinds = [
        StrategyToolKind.freehandDashedArrow,
        StrategyToolKind.freehandStopArrow,
        StrategyToolKind.lateralStop,
        StrategyToolKind.backwards,
        StrategyToolKind.stopArrow,
        StrategyToolKind.dashedArrow,
        StrategyToolKind.dashedStopArrow,
        StrategyToolKind.doubleArrow,
        StrategyToolKind.dashedDoubleArrow,
      ];

      final hashes = <int>{};
      for (final kind in kinds) {
        final pixels = await _render(kind);
        expect(_inkCount(pixels), greaterThan(0), reason: kind.name);
        hashes.add(_hash(pixels));
      }

      expect(hashes, hasLength(kinds.length));
    },
  );

  test('stop variants add two bars beyond an arrowhead', () async {
    for (final pair in const [
      (StrategyToolKind.arrow, StrategyToolKind.stopArrow),
      (StrategyToolKind.dashedArrow, StrategyToolKind.dashedStopArrow),
      (StrategyToolKind.freehandArrow, StrategyToolKind.freehandStopArrow),
    ]) {
      final regular = await _render(pair.$1);
      final stopped = await _render(pair.$2);
      final endpointX = (_points.last.dx * _size.width).round();

      expect(
        _inkAfterX(stopped, endpointX + 1),
        greaterThan(_inkAfterX(regular, endpointX + 1)),
        reason: '${pair.$2.name} should extend past its arrowhead',
      );
    }
  });

  test(
    'backwards spacing is independent of gesture sampling density',
    () async {
      final sparse = await _render(
        StrategyToolKind.backwards,
        points: const [ui.Offset(.10, .50), ui.Offset(.90, .50)],
      );
      final dense = await _render(
        StrategyToolKind.backwards,
        points: const [
          ui.Offset(.10, .50),
          ui.Offset(.20, .50),
          ui.Offset(.30, .50),
          ui.Offset(.40, .50),
          ui.Offset(.50, .50),
          ui.Offset(.60, .50),
          ui.Offset(.70, .50),
          ui.Offset(.80, .50),
          ui.Offset(.90, .50),
        ],
      );

      expect(_inkCount(sparse), greaterThan(0));
      expect(_hash(sparse), _hash(dense));
    },
  );
}

Future<Uint8List> _render(
  StrategyToolKind kind, {
  List<ui.Offset> points = _points,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  StrategyCanvasPainter(
    elements: [
      StrategyStroke(kind: kind, points: points, color: 0xff000000, width: 4),
    ],
  ).paint(canvas, _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    _size.width.toInt(),
    _size.height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

int _inkCount(Uint8List pixels) {
  var count = 0;
  for (var index = 3; index < pixels.length; index += 4) {
    if (pixels[index] != 0) count++;
  }
  return count;
}

int _inkAfterX(Uint8List pixels, int minimumX) {
  var count = 0;
  for (var y = 0; y < _size.height; y++) {
    for (var x = minimumX; x < _size.width; x++) {
      final alpha = pixels[((y.toInt() * _size.width.toInt() + x) * 4) + 3];
      if (alpha != 0) count++;
    }
  }
  return count;
}

int _hash(Uint8List bytes) {
  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash;
}
