import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'config.dart';
import 'controller.dart';
import 'document.dart';
import 'strategy_painter.dart';

const _editGroup = StrategyToolGroup(
  id: 'edit',
  label: 'Edit',
  icon: Icons.ads_click_outlined,
);
const _drawGroup = StrategyToolGroup(
  id: 'draw',
  label: 'Draw',
  icon: Icons.gesture_rounded,
);
const _linesGroup = StrategyToolGroup(
  id: 'lines',
  label: 'Lines',
  icon: Icons.arrow_outward_rounded,
);
const _shapesGroup = StrategyToolGroup(
  id: 'shapes',
  label: 'Shapes',
  icon: Icons.category_outlined,
);
const _addGroup = StrategyToolGroup(
  id: 'add',
  label: 'Add',
  icon: Icons.add_circle_outline_rounded,
);

class _ToolGroup {
  const _ToolGroup(this.definition, this.tools);

  final StrategyToolGroup definition;
  final List<StrategyTool> tools;
}

enum _SelectionTransformMode { move, scale, rotate }

const _rotationHandleGap = 28.0;

class _SelectionGeometry {
  const _SelectionGeometry({
    required this.center,
    required this.corners,
    required this.rotationHandle,
    required this.rotationAnchor,
    required this.rotation,
  });

  final Offset center;
  final List<Offset> corners;
  final Offset rotationHandle;
  final Offset rotationAnchor;
  final double rotation;

  Path get path => Path()
    ..moveTo(corners.first.dx, corners.first.dy)
    ..lineTo(corners[1].dx, corners[1].dy)
    ..lineTo(corners[2].dx, corners[2].dy)
    ..lineTo(corners[3].dx, corners[3].dy)
    ..close();
}

/// Embeddable strategy canvas with optional built-in editing controls.
class StrategyEditor extends StatefulWidget {
  /// Creates an editor bound to [controller].
  const StrategyEditor({
    super.key,
    required this.controller,
    this.showControls = true,
  });

  /// The controller that owns configuration, state, and export behavior.
  final StrategyEditorController controller;

  /// Whether the package-provided controls are visible.
  final bool showControls;

  @override
  State<StrategyEditor> createState() => _StrategyEditorState();
}

class _StrategyEditorState extends State<StrategyEditor> {
  final _repaintKey = GlobalKey();
  final _topControlsScrollController = ScrollController();
  final _toolControlsScrollController = ScrollController();
  List<Offset> _pendingPoints = [];
  int? _selectedIndex;
  Offset? _selectionPointerDown;
  Offset? _selectionDragStart;
  Offset? _selectionGestureFocalStart;
  Offset? _selectionTransformCenter;
  Offset? _selectionHandleStartVector;
  StrategyElement? _selectionDragOrigin;
  StrategyElement? _selectionPreview;
  _SelectionTransformMode? _selectionTransformMode;
  MouseCursor _selectionMouseCursor = SystemMouseCursors.click;

  @override
  void initState() {
    super.initState();
    widget.controller.bindExporter(_exportPng);
  }

  @override
  void didUpdateWidget(covariant StrategyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.bindExporter(null);
      widget.controller.bindExporter(_exportPng);
      _pendingPoints = [];
      _selectedIndex = null;
      _selectionPointerDown = null;
      _selectionDragStart = null;
      _selectionGestureFocalStart = null;
      _selectionTransformCenter = null;
      _selectionHandleStartVector = null;
      _selectionDragOrigin = null;
      _selectionPreview = null;
      _selectionTransformMode = null;
      _selectionMouseCursor = SystemMouseCursors.click;
    }
  }

  @override
  void dispose() {
    widget.controller.bindExporter(null);
    _topControlsScrollController.dispose();
    _toolControlsScrollController.dispose();
    super.dispose();
  }

  Future<Uint8List> _exportPng(double pixelRatio) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) throw StateError('StrategyEditor is no longer mounted.');
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode strategy PNG.');
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  bool get _isDrawingTool {
    final kind = widget.controller.tool.kind;
    return kind != StrategyToolKind.select &&
        kind != StrategyToolKind.text &&
        kind != StrategyToolKind.marker;
  }

  bool get _isSelecting =>
      widget.controller.tool.kind == StrategyToolKind.select;

  Offset _normalized(Offset point, Size size) => Offset(
        (point.dx / size.width).clamp(0.0, 1.0),
        (point.dy / size.height).clamp(0.0, 1.0),
      );

  void _onPanStart(DragStartDetails details, Size size) {
    if (!_isDrawingTool) return;
    setState(() => _pendingPoints = [_normalized(details.localPosition, size)]);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_pendingPoints.isEmpty) return;
    setState(
      () => _pendingPoints = [
        ..._pendingPoints,
        _normalized(details.localPosition, size),
      ],
    );
  }

  void _onPanEnd(DragEndDetails details) {
    if (_pendingPoints.isEmpty) return;
    final controller = widget.controller;
    final points = _pendingPoints;
    setState(() => _pendingPoints = []);
    controller.addElement(
      StrategyStroke(
        kind: controller.tool.kind,
        points: points,
        color: controller.color.toARGB32(),
        width: controller.strokeWidth,
      ),
    );
  }

  void _onSelectionScaleStart(ScaleStartDetails details, Size size) {
    final startPosition = _selectionPointerDown ?? details.localFocalPoint;
    final current = _selectedElement;
    final currentGeometry =
        current == null ? null : _selectionGeometry(current, size);
    final startsOnRotationHandle = currentGeometry != null &&
        (startPosition - currentGeometry.rotationHandle).distance <= 18;
    final startsOnScaleHandle = currentGeometry != null &&
        currentGeometry.corners.any(
          (handle) => (startPosition - handle).distance <= 18,
        );
    final index = startsOnRotationHandle || startsOnScaleHandle
        ? _selectedIndex
        : _hitTestElement(startPosition, size);
    final origin =
        index == null ? null : widget.controller.document.elements[index];
    final geometry = origin == null ? null : _selectionGeometry(origin, size);
    final usesRotationHandle = geometry != null &&
        (startPosition - geometry.rotationHandle).distance <= 18;
    final usesScaleHandle = geometry != null &&
        geometry.corners.any(
          (handle) => (startPosition - handle).distance <= 18,
        );
    final transformMode = origin == null
        ? null
        : usesRotationHandle
            ? _SelectionTransformMode.rotate
            : usesScaleHandle
                ? _SelectionTransformMode.scale
                : _SelectionTransformMode.move;
    setState(() {
      _selectedIndex = index;
      _selectionDragStart =
          index == null ? null : _normalized(startPosition, size);
      _selectionGestureFocalStart = details.localFocalPoint;
      _selectionDragOrigin = origin;
      _selectionPreview = null;
      _selectionTransformMode = transformMode;
      _selectionTransformCenter =
          usesRotationHandle || usesScaleHandle ? geometry.center : null;
      _selectionHandleStartVector = usesRotationHandle || usesScaleHandle
          ? startPosition - geometry.center
          : null;
      _selectionMouseCursor = switch (transformMode) {
        _SelectionTransformMode.rotate => SystemMouseCursors.grabbing,
        _SelectionTransformMode.scale => _scaleCursor(
            startPosition - geometry!.center,
          ),
        _SelectionTransformMode.move => SystemMouseCursors.move,
        null => SystemMouseCursors.click,
      };
    });
  }

  void _onSelectionScaleUpdate(ScaleUpdateDetails details, Size size) {
    final origin = _selectionDragOrigin;
    final dragStart = _selectionDragStart;
    if (origin == null || dragStart == null) return;

    StrategyElement transformed;
    if (_selectionTransformMode == _SelectionTransformMode.scale) {
      final center = _selectionTransformCenter;
      final startVector = _selectionHandleStartVector;
      if (center == null || startVector == null || startVector.distance == 0) {
        return;
      }
      final currentVector = details.localFocalPoint - center;
      final scale = (_elementScale(origin) *
              currentVector.distance /
              startVector.distance)
          .clamp(.25, 4.0);
      transformed = _withTransform(
        origin,
        rotation: _elementRotation(origin),
        scale: scale,
      );
    } else if (_selectionTransformMode == _SelectionTransformMode.rotate) {
      final center = _selectionTransformCenter;
      final startVector = _selectionHandleStartVector;
      if (center == null || startVector == null || startVector.distance == 0) {
        return;
      }
      final currentVector = details.localFocalPoint - center;
      final rotation = _elementRotation(origin) +
          math.atan2(currentVector.dy, currentVector.dx) -
          math.atan2(startVector.dy, startVector.dx);
      transformed = _withTransform(
        origin,
        rotation: rotation,
        scale: _elementScale(origin),
      );
    } else if (details.pointerCount > 1) {
      final focalStart = _selectionGestureFocalStart ?? details.localFocalPoint;
      final delta = Offset(
        (details.localFocalPoint.dx - focalStart.dx) / size.width,
        (details.localFocalPoint.dy - focalStart.dy) / size.height,
      );
      transformed = _withTransform(
        _translateElement(origin, delta),
        rotation: _elementRotation(origin),
        scale: (_elementScale(origin) * details.scale).clamp(.25, 4.0),
      );
    } else {
      final delta = _normalized(details.localFocalPoint, size) - dragStart;
      transformed = _translateElement(origin, delta);
    }
    setState(() => _selectionPreview = transformed);
  }

  void _onSelectionScaleEnd(ScaleEndDetails details) {
    final index = _selectedIndex;
    final preview = _selectionPreview;
    _clearSelectionGesture();
    if (index != null && preview != null) {
      widget.controller.replaceElement(index, preview);
    }
  }

  void _clearSelectionGesture() {
    setState(() {
      _selectionPointerDown = null;
      _selectionDragStart = null;
      _selectionGestureFocalStart = null;
      _selectionTransformCenter = null;
      _selectionHandleStartVector = null;
      _selectionDragOrigin = null;
      _selectionPreview = null;
      _selectionTransformMode = null;
      _selectionMouseCursor = SystemMouseCursors.click;
    });
  }

  Future<void> _onTap(TapUpDetails details, Size size) async {
    _selectionPointerDown = null;
    final controller = widget.controller;
    final point = _normalized(details.localPosition, size);
    if (controller.tool.kind == StrategyToolKind.select) {
      setState(
        () => _selectedIndex = _hitTestElement(details.localPosition, size),
      );
    } else if (controller.tool.kind == StrategyToolKind.marker) {
      controller.addElement(
        StrategyMarker(
          position: point,
          toolId: controller.toolId,
          color: controller.selectedColor?.toARGB32(),
        ),
      );
    } else if (controller.tool.kind == StrategyToolKind.text) {
      final text = await showDialog<String>(
        context: context,
        builder: (context) => const _TextEditorDialog(),
      );
      if (!mounted || text == null || text.trim().isEmpty) return;
      controller.addElement(
        StrategyText(
          position: point,
          text: text.trim(),
          color: controller.color.toARGB32(),
          fontSize: math.max(14, controller.strokeWidth * 4),
        ),
      );
    }
  }

  Future<void> _editSelectedText() async {
    final index = _selectedIndex;
    final selected = _selectedElement;
    if (index == null || selected is! StrategyText) return;

    final text = await showDialog<String>(
      context: context,
      builder: (context) =>
          _TextEditorDialog(initialText: selected.text, isEditing: true),
    );
    if (!mounted || text == null || text.trim().isEmpty) return;

    final elements = widget.controller.document.elements;
    if (index >= elements.length || elements[index] is! StrategyText) return;
    widget.controller.replaceElement(
      index,
      selected.copyWith(text: text.trim()),
    );
  }

  List<StrategyElement> _renderedElements() {
    final elements = [...widget.controller.document.elements];
    final index = _selectedIndex;
    final preview = _selectionPreview;
    if (index != null && preview != null && index < elements.length) {
      elements[index] = preview;
    }
    return elements;
  }

  StrategyElement _translateElement(StrategyElement element, Offset delta) =>
      switch (element) {
        StrategyStroke() => _translateStroke(element, delta),
        StrategyText() => element.copyWith(
            position: _clampPosition(element.position + delta),
          ),
        StrategyMarker() => element.copyWith(
            position: _clampPosition(element.position + delta),
          ),
      };

  StrategyStroke _translateStroke(StrategyStroke stroke, Offset delta) {
    if (stroke.points.isEmpty) return stroke;
    var minX = stroke.points.first.dx;
    var maxX = minX;
    var minY = stroke.points.first.dy;
    var maxY = minY;
    for (final point in stroke.points.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    final dx = delta.dx.clamp(-minX, 1 - maxX);
    final dy = delta.dy.clamp(-minY, 1 - maxY);
    return stroke.copyWith(
      points: [for (final point in stroke.points) point + Offset(dx, dy)],
    );
  }

  Offset _clampPosition(Offset position) =>
      Offset(position.dx.clamp(0.0, 1.0), position.dy.clamp(0.0, 1.0));

  void _rotateSelected(double radians) {
    final selected = _selectedElement;
    final index = _selectedIndex;
    if (selected == null || index == null) return;
    final transformed = switch (selected) {
      StrategyStroke() => selected.copyWith(
          rotation: selected.rotation + radians,
        ),
      StrategyText() => selected.copyWith(
          rotation: selected.rotation + radians,
        ),
      StrategyMarker() => selected.copyWith(
          rotation: selected.rotation + radians,
        ),
    };
    widget.controller.replaceElement(index, transformed);
  }

  void _scaleSelected(double delta) {
    final selected = _selectedElement;
    final index = _selectedIndex;
    if (selected == null || index == null) return;
    final nextScale = (_elementScale(selected) + delta).clamp(.25, 4.0);
    final transformed = switch (selected) {
      StrategyStroke() => selected.copyWith(scale: nextScale),
      StrategyText() => selected.copyWith(scale: nextScale),
      StrategyMarker() => selected.copyWith(scale: nextScale),
    };
    widget.controller.replaceElement(index, transformed);
  }

  StrategyElement _withTransform(
    StrategyElement element, {
    required double rotation,
    required double scale,
  }) =>
      switch (element) {
        StrategyStroke() => element.copyWith(rotation: rotation, scale: scale),
        StrategyText() => element.copyWith(rotation: rotation, scale: scale),
        StrategyMarker() => element.copyWith(rotation: rotation, scale: scale),
      };

  StrategyElement? get _selectedElement {
    final index = _selectedIndex;
    if (index == null) return null;
    final elements = widget.controller.document.elements;
    if (index >= elements.length) return null;
    return elements[index];
  }

  double _elementRotation(StrategyElement element) => switch (element) {
        StrategyStroke() => element.rotation,
        StrategyText() => element.rotation,
        StrategyMarker() => element.rotation,
      };

  double _elementScale(StrategyElement element) => switch (element) {
        StrategyStroke() => element.scale,
        StrategyText() => element.scale,
        StrategyMarker() => element.scale,
      };

  int? _hitTestElement(Offset position, Size size) {
    final elements = widget.controller.document.elements;
    for (var index = elements.length - 1; index >= 0; index--) {
      if (_hitTest(elements[index], position, size)) return index;
    }
    return null;
  }

  bool _hitTest(StrategyElement element, Offset position, Size size) {
    final baseBounds = _baseBounds(element, size);
    if (baseBounds == null) return false;
    final local = _inverseTransformPoint(
      position,
      baseBounds.center,
      _elementRotation(element),
      _elementScale(element),
    );
    final tolerance = 10 / _elementScale(element);
    if (element is! StrategyStroke) {
      return baseBounds.inflate(tolerance).contains(local);
    }
    if (element.kind == StrategyToolKind.rectangle ||
        element.kind == StrategyToolKind.filledRectangle ||
        element.kind == StrategyToolKind.ellipse ||
        element.kind == StrategyToolKind.filledEllipse) {
      return baseBounds.inflate(tolerance).contains(local);
    }
    final points = element.points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList();
    if (points.length == 1) {
      return (local - points.first).distance <= tolerance + element.width / 2;
    }
    final renderedPoints =
        _followsGesture(element.kind) ? points : [points.first, points.last];
    for (var index = 0; index + 1 < renderedPoints.length; index++) {
      if (_distanceToSegment(
            local,
            renderedPoints[index],
            renderedPoints[index + 1],
          ) <=
          tolerance + element.width / 2) {
        return true;
      }
    }
    return false;
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

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    if (segment.distanceSquared == 0) return (point - start).distance;
    final projection =
        ((point - start).dx * segment.dx + (point - start).dy * segment.dy) /
            segment.distanceSquared;
    final closest = start + segment * projection.clamp(0.0, 1.0);
    return (point - closest).distance;
  }

  Offset _inverseTransformPoint(
    Offset point,
    Offset center,
    double rotation,
    double scale,
  ) {
    final delta = point - center;
    final cosine = math.cos(-rotation);
    final sine = math.sin(-rotation);
    return center +
        Offset(
          (delta.dx * cosine - delta.dy * sine) / scale,
          (delta.dx * sine + delta.dy * cosine) / scale,
        );
  }

  Rect? _baseBounds(StrategyElement element, Size size) {
    switch (element) {
      case StrategyStroke():
        if (element.points.isEmpty) return null;
        final points = element.points
            .map(
              (point) => Offset(point.dx * size.width, point.dy * size.height),
            )
            .toList();
        return _pointsBounds(points).inflate(element.width / 2);
      case StrategyText():
        final painter = _textPainter(element)..layout(maxWidth: size.width);
        final origin = Offset(
          element.position.dx * size.width,
          element.position.dy * size.height,
        );
        return origin & painter.size;
      case StrategyMarker():
        final markerSize = _markerTool(element)?.markerSize ?? 32;
        final center = Offset(
          element.position.dx * size.width,
          element.position.dy * size.height,
        );
        return Rect.fromCenter(
          center: center,
          width: markerSize,
          height: markerSize,
        );
    }
  }

  TextPainter _textPainter(StrategyText element) => TextPainter(
        text: TextSpan(
          text: element.text,
          style: TextStyle(
            color: Color(element.color),
            fontSize: element.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

  StrategyTool? _markerTool(StrategyMarker element) {
    for (final tool in widget.controller.config.markerRenderers) {
      if (tool.id == element.toolId) return tool;
    }
    return null;
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

  _SelectionGeometry? _selectionGeometry(StrategyElement element, Size size) {
    final base = _baseBounds(element, size);
    if (base == null) return null;
    final rotation = _elementRotation(element);
    final halfWidth = base.width * _elementScale(element) / 2 + 8;
    final halfHeight = base.height * _elementScale(element) / 2 + 8;
    final corners = [
      const Offset(-1, -1),
      const Offset(1, -1),
      const Offset(1, 1),
      const Offset(-1, 1),
    ].map((direction) {
      final local = Offset(
        direction.dx * halfWidth,
        direction.dy * halfHeight,
      );
      return base.center + _rotateVector(local, rotation);
    }).toList();
    final topDirection = _rotateVector(const Offset(0, -1), rotation);
    final bottomDirection = -topDirection;
    final topAnchor = base.center + topDirection * halfHeight;
    final bottomAnchor = base.center + bottomDirection * halfHeight;
    final topHandle = topAnchor + topDirection * _rotationHandleGap;
    final bottomHandle = bottomAnchor + bottomDirection * _rotationHandleGap;
    final canvasBounds = (Offset.zero & size).deflate(8);
    final useTop = canvasBounds.contains(topHandle) ||
        !canvasBounds.contains(bottomHandle);
    return _SelectionGeometry(
      center: base.center,
      corners: corners,
      rotationHandle: useTop ? topHandle : bottomHandle,
      rotationAnchor: useTop ? topAnchor : bottomAnchor,
      rotation: rotation,
    );
  }

  Offset _rotateVector(Offset vector, double rotation) {
    final cosine = math.cos(rotation);
    final sine = math.sin(rotation);
    return Offset(
      vector.dx * cosine - vector.dy * sine,
      vector.dx * sine + vector.dy * cosine,
    );
  }

  MouseCursor _scaleCursor(Offset vector) {
    final angle = math.atan2(vector.dy, vector.dx);
    final sector = ((angle / (math.pi / 4)).round() % 4 + 4) % 4;
    return switch (sector) {
      0 => SystemMouseCursors.resizeLeftRight,
      1 => SystemMouseCursors.resizeUpLeftDownRight,
      2 => SystemMouseCursors.resizeUpDown,
      _ => SystemMouseCursors.resizeUpRightDownLeft,
    };
  }

  MouseCursor _cursorForSelection(
    Offset position,
    StrategyElement? selected,
    Size size,
  ) {
    if (selected == null) return SystemMouseCursors.click;
    final geometry = _selectionGeometry(selected, size);
    if (geometry == null) return SystemMouseCursors.click;
    if ((position - geometry.rotationHandle).distance <= 18) {
      return SystemMouseCursors.grab;
    }
    for (final handle in geometry.corners) {
      if ((position - handle).distance <= 18) {
        return _scaleCursor(handle - geometry.center);
      }
    }
    return _hitTest(selected, position, size)
        ? SystemMouseCursors.move
        : SystemMouseCursors.click;
  }

  void _updateSelectionCursor(
    Offset position,
    StrategyElement? selected,
    Size size,
  ) {
    if (_selectionTransformMode != null) return;
    final cursor = _cursorForSelection(position, selected, size);
    if (cursor == _selectionMouseCursor) return;
    setState(() => _selectionMouseCursor = cursor);
  }

  Widget _buildSelectionControls(
    StrategyElement selected, {
    required double maxWidth,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (_elementScale(selected) * 100).round();
    final showPercent = maxWidth >= 250;
    final controls = Semantics(
      key: const ValueKey('strategy-selection-controls'),
      container: true,
      label: 'Transform selected item',
      child: Material(
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: .22),
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected is StrategyText) ...[
              IconButton(
                key: const ValueKey('strategy-selection-edit-text'),
                tooltip: 'Edit text',
                onPressed: _editSelectedText,
                icon: const Icon(Icons.edit_outlined),
              ),
              SizedBox(
                height: 28,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant,
                ),
              ),
            ],
            IconButton(
              key: const ValueKey('strategy-selection-rotate-left'),
              tooltip: 'Rotate left 15 degrees',
              onPressed: () => _rotateSelected(-math.pi / 12),
              icon: const Icon(Icons.rotate_left_rounded),
            ),
            IconButton(
              key: const ValueKey('strategy-selection-rotate-right'),
              tooltip: 'Rotate right 15 degrees',
              onPressed: () => _rotateSelected(math.pi / 12),
              icon: const Icon(Icons.rotate_right_rounded),
            ),
            SizedBox(
              height: 28,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
            IconButton(
              key: const ValueKey('strategy-selection-scale-down'),
              tooltip: 'Scale down',
              onPressed: () => _scaleSelected(-.1),
              icon: const Icon(Icons.remove_rounded),
            ),
            if (showPercent)
              Semantics(
                label: 'Scale $percent percent',
                child: SizedBox(
                  width: 48,
                  child: Text(
                    '$percent%',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            IconButton(
              key: const ValueKey('strategy-selection-scale-up'),
              tooltip: 'Scale up',
              onPressed: () => _scaleSelected(.1),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: controls,
      ),
    );
  }

  Widget _buildCanvas(BoxConstraints constraints) {
    final controller = widget.controller;
    final layout = controller.config.layout(controller.document.layoutId);
    final ratio = layout.aspectRatio;
    final width = math.min(constraints.maxWidth, constraints.maxHeight * ratio);
    final height = width / ratio;
    final size = Size(width, height);
    final preview = _pendingPoints.isEmpty
        ? null
        : StrategyStroke(
            kind: controller.tool.kind,
            points: _pendingPoints,
            color: controller.color.toARGB32(),
            width: controller.strokeWidth,
          );
    final elements = _renderedElements();
    final selectedIndex = _selectedIndex;
    final selected =
        _isSelecting && selectedIndex != null && selectedIndex < elements.length
            ? elements[selectedIndex]
            : null;
    final selectionGeometry =
        selected == null ? null : _selectionGeometry(selected, size);

    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Stack(
                      children: [
                        Positioned.fill(child: layout.builder(context)),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: StrategyCanvasPainter(
                              elements: elements,
                              preview: preview,
                            ),
                          ),
                        ),
                        for (final element in elements)
                          if (element is StrategyMarker)
                            _buildMarker(element, size),
                      ],
                    ),
                  ),
                ),
                if (selectionGeometry != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SelectionPainter(
                          geometry: selectionGeometry,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Semantics(
                    label: 'Strategy canvas',
                    hint: _isSelecting
                        ? 'Select an item, then drag to move it, drag a corner '
                            'to resize it, or drag the round handle to rotate it'
                        : 'Use the selected editing tool on this canvas',
                    child: MouseRegion(
                      cursor: _isSelecting
                          ? _selectionMouseCursor
                          : _isDrawingTool
                              ? SystemMouseCursors.precise
                              : SystemMouseCursors.click,
                      onHover: _isSelecting
                          ? (event) => _updateSelectionCursor(
                                event.localPosition,
                                selected,
                                size,
                              )
                          : null,
                      onEnter: _isSelecting
                          ? (event) => _updateSelectionCursor(
                                event.localPosition,
                                selected,
                                size,
                              )
                          : null,
                      onExit: _isSelecting
                          ? (_) {
                              if (_selectionMouseCursor !=
                                  SystemMouseCursors.click) {
                                setState(
                                  () => _selectionMouseCursor =
                                      SystemMouseCursors.click,
                                );
                              }
                            }
                          : null,
                      child: Listener(
                        onPointerDown: (event) {
                          if (_isSelecting && _selectionDragOrigin == null) {
                            _selectionPointerDown = event.localPosition;
                          }
                        },
                        child: GestureDetector(
                          key: const ValueKey('strategy-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) => _onTap(details, size),
                          onPanStart: _isSelecting
                              ? null
                              : (details) => _onPanStart(details, size),
                          onPanUpdate: _isSelecting
                              ? null
                              : (details) => _onPanUpdate(details, size),
                          onPanEnd: _isSelecting ? null : _onPanEnd,
                          onPanCancel: _isSelecting ? null : _cancelPan,
                          onScaleStart: _isSelecting
                              ? (details) =>
                                  _onSelectionScaleStart(details, size)
                              : null,
                          onScaleUpdate: _isSelecting
                              ? (details) =>
                                  _onSelectionScaleUpdate(details, size)
                              : null,
                          onScaleEnd:
                              _isSelecting ? _onSelectionScaleEnd : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (selected != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Center(
                      child: _buildSelectionControls(
                        selected,
                        maxWidth: math.max(0.0, width - 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cancelPan() {
    if (_pendingPoints.isEmpty &&
        _selectionPointerDown == null &&
        _selectionDragStart == null) {
      return;
    }
    setState(() {
      _pendingPoints = [];
      _selectionPointerDown = null;
      _selectionDragStart = null;
      _selectionGestureFocalStart = null;
      _selectionTransformCenter = null;
      _selectionHandleStartVector = null;
      _selectionDragOrigin = null;
      _selectionPreview = null;
      _selectionTransformMode = null;
      _selectionMouseCursor = SystemMouseCursors.click;
    });
  }

  Widget _buildMarker(StrategyMarker element, Size size) {
    final tool = _markerTool(element);
    if (tool == null) return const SizedBox.shrink();
    return Positioned(
      left: element.position.dx * size.width - tool.markerSize / 2,
      top: element.position.dy * size.height - tool.markerSize / 2,
      width: tool.markerSize,
      height: tool.markerSize,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: element.rotation,
          child: Transform.scale(
            scale: element.scale,
            child: tool.buildMarkerWithColor(
              context,
              color: element.color == null ? null : Color(element.color!),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    if (widget.controller.document.elements.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('Clear the canvas?'),
        content: const Text(
          'This removes every drawing, label, and marker from the current layout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear canvas'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _selectedIndex = null);
      widget.controller.clear();
    }
  }

  String _colorLabel(Color color) => switch (color.toARGB32()) {
        0xff000000 => 'Black',
        0xfff44336 => 'Red',
        0xffff9800 => 'Orange',
        0xff4caf50 => 'Green',
        0xff2196f3 => 'Blue',
        0xffffffff => 'White',
        final value =>
          '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      };

  Widget _controlButton({
    required Widget icon,
    required String label,
    bool compact = false,
    bool showCompactLabel = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final showLabel = !compact || showCompactLabel;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (showLabel) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 112 : 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(bool compact, {required bool dense}) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Scrollbar(
        controller: _topControlsScrollController,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _topControlsScrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(12, dense ? 2 : 8, 12, dense ? 3 : 9),
          child: Row(
            children: [
              PopupMenuButton<String>(
                key: const ValueKey('strategy-layout'),
                tooltip: 'Choose layout',
                position: PopupMenuPosition.under,
                constraints: const BoxConstraints(
                  minWidth: 280,
                  maxWidth: 340,
                  maxHeight: 440,
                ),
                initialValue: controller.document.layoutId,
                onSelected: controller.selectLayout,
                itemBuilder: (context) => [
                  for (final layout in controller.config.layouts)
                    PopupMenuItem(
                      value: layout.id,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 32,
                            child: layout.thumbnailBuilder?.call(context) ??
                                const Icon(Icons.dashboard_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(layout.label)),
                          if (layout.id == controller.document.layoutId)
                            Icon(Icons.check_rounded, color: scheme.primary),
                        ],
                      ),
                    ),
                ],
                child: _controlButton(
                  compact: compact,
                  showCompactLabel: true,
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: controller.config
                      .layout(controller.document.layoutId)
                      .label,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<({Color? color})>(
                key: const ValueKey('strategy-color'),
                tooltip: 'Choose drawing color',
                position: PopupMenuPosition.under,
                constraints: const BoxConstraints(
                  minWidth: 240,
                  maxWidth: 300,
                  maxHeight: 440,
                ),
                initialValue: (color: controller.selectedColor),
                onSelected: (choice) {
                  final color = choice.color;
                  if (color == null) {
                    controller.clearColor();
                  } else {
                    controller.selectColor(color);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    key: const ValueKey('strategy-color-default'),
                    value: (color: null),
                    child: Row(
                      children: [
                        const _DefaultColorSwatch(),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Default / Clear')),
                        if (controller.selectedColor == null)
                          Icon(Icons.check_rounded, color: scheme.primary),
                      ],
                    ),
                  ),
                  for (final color in controller.config.colors)
                    PopupMenuItem(
                      value: (color: color),
                      child: Row(
                        children: [
                          _ColorSwatch(color: color),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_colorLabel(color))),
                          if (color == controller.selectedColor)
                            Icon(Icons.check_rounded, color: scheme.primary),
                        ],
                      ),
                    ),
                ],
                child: _controlButton(
                  compact: compact,
                  icon: controller.selectedColor == null
                      ? const _DefaultColorSwatch()
                      : _ColorSwatch(color: controller.selectedColor!),
                  label: controller.selectedColor == null
                      ? 'Default'
                      : _colorLabel(controller.selectedColor!),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<double>(
                tooltip: 'Choose line weight',
                position: PopupMenuPosition.under,
                constraints: const BoxConstraints(
                  minWidth: 220,
                  maxWidth: 280,
                  maxHeight: 360,
                ),
                initialValue: controller.strokeWidth,
                onSelected: controller.selectStrokeWidth,
                itemBuilder: (context) => [
                  for (final width in controller.config.strokeWidths)
                    PopupMenuItem(
                      value: width,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Divider(
                              thickness: width.clamp(1, 8),
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('${width.toStringAsFixed(0)} px'),
                          ),
                          if (width == controller.strokeWidth)
                            Icon(Icons.check_rounded, color: scheme.primary),
                        ],
                      ),
                    ),
                ],
                child: _controlButton(
                  compact: compact,
                  icon: const Icon(Icons.line_weight_rounded),
                  label: '${controller.strokeWidth.toStringAsFixed(0)} px',
                ),
              ),
              _ToolbarDivider(color: scheme.outlineVariant, height: 32),
              IconButton(
                tooltip: 'Undo last change',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              IconButton(
                tooltip: 'Redo last change',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo_rounded),
              ),
              IconButton(
                key: const ValueKey('strategy-clear'),
                tooltip: 'Clear canvas',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed:
                    controller.document.elements.isEmpty ? null : _confirmClear,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _toolHint(StrategyToolKind kind) => switch (kind) {
        StrategyToolKind.select =>
          'Select an item to move, resize, rotate, or edit text',
        StrategyToolKind.text => 'Tap the canvas to add multiline text',
        StrategyToolKind.marker => 'Tap the canvas to place this item',
        _ => 'Drag on the canvas to draw with this tool',
      };

  Widget _buildActiveToolBar(bool compact, {required bool dense}) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final tool = controller.tool;
    final group = tool.group ?? _defaultGroupFor(tool.kind);
    final elementCount = controller.document.elements.length;
    final elementLabel = elementCount == 1 ? 'item' : 'items';
    return Semantics(
      key: const ValueKey('strategy-active-tool'),
      container: true,
      label: 'Active tool: ${tool.label}. ${_toolHint(tool.kind)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 20,
            vertical: dense ? 2 : 7,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: scheme.onPrimaryContainer,
                    size: 20,
                  ),
                  child: _ToolIconSlot(
                    width: 30,
                    color: scheme.onPrimaryContainer,
                    child: tool.buildIcon(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: compact ? 1 : 2,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    key: ValueKey(tool.id),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                      if (!dense)
                        Text(
                          group.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
              if (!compact && !dense) ...[
                const SizedBox(width: 18),
                Container(width: 1, height: 28, color: scheme.outlineVariant),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: Text(
                    _toolHint(tool.kind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ] else
                const Spacer(),
              Tooltip(
                message: '$elementCount $elementLabel on canvas',
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$elementCount',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StrategyToolGroup _defaultGroupFor(StrategyToolKind kind) => switch (kind) {
        StrategyToolKind.select => _editGroup,
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
          _drawGroup,
        StrategyToolKind.line ||
        StrategyToolKind.arrow ||
        StrategyToolKind.stopArrow ||
        StrategyToolKind.dashedLine ||
        StrategyToolKind.dashedArrow ||
        StrategyToolKind.dashedStopArrow =>
          _linesGroup,
        StrategyToolKind.rectangle ||
        StrategyToolKind.filledRectangle ||
        StrategyToolKind.ellipse ||
        StrategyToolKind.filledEllipse =>
          _shapesGroup,
        StrategyToolKind.text || StrategyToolKind.marker => _addGroup,
      };

  List<_ToolGroup> _toolGroups(List<StrategyTool> tools) {
    final groups = <String, _ToolGroup>{};
    for (final tool in tools) {
      final definition = tool.group ?? _defaultGroupFor(tool.kind);
      final existing = groups[definition.id];
      if (existing == null) {
        groups[definition.id] = _ToolGroup(definition, [tool]);
      } else {
        existing.tools.add(tool);
      }
    }
    return groups.values.toList(growable: false);
  }

  Widget _buildToolControls(bool compact, {required bool dense}) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final groups = _toolGroups(controller.config.tools);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Scrollbar(
          controller: _toolControlsScrollController,
          scrollbarOrientation: ScrollbarOrientation.top,
          child: SingleChildScrollView(
            controller: _toolControlsScrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 16,
              dense ? 2 : (compact ? 8 : 10),
              compact ? 10 : 16,
              dense ? 3 : (compact ? 9 : 11),
            ),
            child: Row(
              children: [
                if (!compact) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'TOOLS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  _ToolbarDivider(color: scheme.outlineVariant, height: 32),
                ],
                for (final group in groups) ...[
                  _buildToolGroup(group, compact, dense: dense),
                  SizedBox(width: compact ? 6 : 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolGroup(
    _ToolGroup group,
    bool compact, {
    required bool dense,
  }) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final selected = group.tools.any((tool) => tool.id == controller.toolId);
    final visibleTool = selected ? controller.tool : group.tools.first;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return PopupMenuButton<String>(
      key: ValueKey('strategy-tool-group-${group.definition.id}'),
      tooltip: '${group.definition.label} tools',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 340,
        maxHeight: 480,
      ),
      initialValue: selected ? controller.toolId : null,
      onSelected: controller.selectTool,
      itemBuilder: (context) => [
        for (final tool in group.tools)
          PopupMenuItem(
            key: ValueKey('strategy-tool-${tool.id}'),
            value: tool.id,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ToolIconSlot(
                  key: ValueKey('strategy-tool-icon-${tool.id}'),
                  width: 40,
                  color: scheme.onSurfaceVariant,
                  child: tool.buildIcon(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tool.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: controller.toolId == tool.id
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                ),
              ],
            ),
          ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(
          minHeight: compact ? (dense ? 56 : 64) : 48,
          minWidth: compact ? 72 : 48,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 14,
          vertical: compact ? (dense ? 3 : 6) : 0,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: IconTheme(
          data: IconThemeData(color: foreground),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      child: selected
                          ? _ToolIconSlot(
                              width: 36,
                              color: foreground,
                              child: visibleTool.buildIcon(context),
                            )
                          : Icon(group.definition.icon, size: 21),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 64,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              group.definition.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 13,
                            color: foreground,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected)
                      _ToolIconSlot(
                        width: 36,
                        color: foreground,
                        child: visibleTool.buildIcon(context),
                      )
                    else
                      Icon(group.definition.icon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      selected ? visibleTool.label : group.definition.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: foreground,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: foreground,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, outerConstraints) {
          final compact = outerConstraints.maxWidth < 640;
          final dense = outerConstraints.maxHeight < 520;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showControls) _buildTopControls(compact, dense: dense),
              if (widget.showControls)
                _buildActiveToolBar(compact, dense: dense),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainerLowest,
                        Theme.of(context).colorScheme.surfaceContainerLow,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(dense ? 8 : (compact ? 12 : 24)),
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          _buildCanvas(constraints),
                    ),
                  ),
                ),
              ),
              if (widget.showControls)
                _buildToolControls(compact, dense: dense),
            ],
          );
        },
      ),
    );
  }
}

class _TextEditorDialog extends StatefulWidget {
  const _TextEditorDialog({this.initialText = '', this.isEditing = false});

  final String initialText;
  final bool isEditing;

  @override
  State<_TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<_TextEditorDialog> {
  late final TextEditingController _controller;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const ValueKey('strategy-add-text-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 440),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isEditing
                  ? Icons.edit_note_rounded
                  : Icons.text_fields_rounded,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit text' : 'Add text',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing
                      ? 'Update this canvas label.'
                      : 'Create a multiline label on the canvas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: TextField(
        key: const ValueKey('strategy-add-text-input'),
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        maxLength: 240,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Text',
          hintText: 'Enter text. Use Enter for a new line.',
          helperText: widget.isEditing
              ? 'Save your changes when you are finished.'
              : 'You can move, rotate, and resize it after adding.',
          helperMaxLines: 2,
          alignLabelWithHint: true,
          prefixIcon: const Icon(Icons.title_rounded),
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('strategy-add-text-cancel'),
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('strategy-add-text-submit'),
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(widget.isEditing ? 144 : 112, 48),
          ),
          icon: Icon(
            widget.isEditing ? Icons.check_rounded : Icons.add_rounded,
            size: 20,
          ),
          label: Text(widget.isEditing ? 'Save changes' : 'Add text'),
        ),
      ],
    );
  }
}

class _ToolIconSlot extends StatelessWidget {
  const _ToolIconSlot({
    super.key,
    required this.width,
    required this.color,
    required this.child,
  });

  final double width;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 24,
        child: ClipRect(
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: color),
              child: child,
            ),
          ),
        ),
      );
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.color, this.height = 28});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: VerticalDivider(width: 17, thickness: 1, color: color),
      );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
      );
}

class _DefaultColorSwatch extends StatelessWidget {
  const _DefaultColorSwatch();

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 20,
        child: Icon(
          Icons.format_color_reset_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({required this.geometry, required this.color});

  final _SelectionGeometry geometry;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = geometry.path;
    if (!path.getBounds().overlaps(Offset.zero & size)) return;
    final fill = Paint()
      ..color = color.withValues(alpha: .08)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
    canvas.drawLine(geometry.rotationAnchor, geometry.rotationHandle, outline);
    final handle = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final point in geometry.corners) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(geometry.rotation);
      canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), handle);
      canvas.restore();
    }
    canvas.drawCircle(geometry.rotationHandle, 7, handle);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) =>
      oldDelegate.geometry.center != geometry.center ||
      oldDelegate.geometry.rotation != geometry.rotation ||
      oldDelegate.geometry.corners.first != geometry.corners.first ||
      oldDelegate.geometry.rotationHandle != geometry.rotationHandle ||
      oldDelegate.color != color;
}
