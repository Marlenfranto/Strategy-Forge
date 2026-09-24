import 'dart:ui';

import 'config.dart';

/// Coordinates in a document are fractions of the layout width and height.
sealed class StrategyElement {
  /// Creates a strategy document element.
  const StrategyElement();

  /// Encodes this element as a JSON-compatible map.
  Map<String, Object?> toJson();

  /// Decodes an element from a JSON-compatible [json] map.
  static StrategyElement fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'stroke':
        return StrategyStroke(
          kind: StrategyToolKind.values.byName(json['kind'] as String),
          points: (json['points'] as List)
              .map((point) => _readPoint(point as List))
              .toList(),
          color: json['color'] as int,
          width: (json['width'] as num).toDouble(),
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
          scale: (json['scale'] as num?)?.toDouble() ?? 1,
        );
      case 'text':
        return StrategyText(
          position: _readPoint(json['position'] as List),
          text: json['text'] as String,
          color: json['color'] as int,
          fontSize: (json['fontSize'] as num).toDouble(),
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
          scale: (json['scale'] as num?)?.toDouble() ?? 1,
        );
      case 'marker':
        return StrategyMarker(
          position: _readPoint(json['position'] as List),
          toolId: json['toolId'] as String,
          color: json['color'] as int?,
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
          scale: (json['scale'] as num?)?.toDouble() ?? 1,
        );
      default:
        throw FormatException('Unknown strategy element: ${json['type']}');
    }
  }
}

/// A drawn path or shape stored in normalized layout coordinates.
class StrategyStroke extends StrategyElement {
  /// Creates an immutable strategy stroke.
  StrategyStroke({
    required this.kind,
    required List<Offset> points,
    required this.color,
    required this.width,
    this.rotation = 0,
    this.scale = 1,
  })  : assert(scale > 0),
        points = List.unmodifiable(points);

  /// The rendering behavior used for the stroke.
  final StrategyToolKind kind;

  /// The normalized points that define the stroke.
  final List<Offset> points;

  /// The Flutter ARGB integer color.
  final int color;

  /// The unscaled stroke width in logical pixels.
  final double width;

  /// The clockwise rotation in radians.
  final double rotation;

  /// The scale factor applied around the element center.
  final double scale;

  /// Returns a copy with updated geometry values.
  StrategyStroke copyWith({
    List<Offset>? points,
    double? rotation,
    double? scale,
  }) =>
      StrategyStroke(
        kind: kind,
        points: points ?? this.points,
        color: color,
        width: width,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
      );

  @override
  Map<String, Object?> toJson() => {
        'type': 'stroke',
        'kind': kind.name,
        'points': points.map(_writePoint).toList(),
        'color': color,
        'width': width,
        if (rotation != 0) 'rotation': rotation,
        if (scale != 1) 'scale': scale,
      };
}

/// A multiline text label stored in normalized layout coordinates.
class StrategyText extends StrategyElement {
  /// Creates an immutable strategy text element.
  const StrategyText({
    required this.position,
    required this.text,
    required this.color,
    required this.fontSize,
    this.rotation = 0,
    this.scale = 1,
  }) : assert(scale > 0);

  /// The normalized anchor position.
  final Offset position;

  /// The visible multiline content.
  final String text;

  /// The Flutter ARGB integer color.
  final int color;

  /// The unscaled font size in logical pixels.
  final double fontSize;

  /// The clockwise rotation in radians.
  final double rotation;

  /// The scale factor applied around the element center.
  final double scale;

  /// Returns a copy with updated content or geometry values.
  StrategyText copyWith({
    Offset? position,
    String? text,
    double? rotation,
    double? scale,
  }) =>
      StrategyText(
        position: position ?? this.position,
        text: text ?? this.text,
        color: color,
        fontSize: fontSize,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
      );

  @override
  Map<String, Object?> toJson() => {
        'type': 'text',
        'position': _writePoint(position),
        'text': text,
        'color': color,
        'fontSize': fontSize,
        if (rotation != 0) 'rotation': rotation,
        if (scale != 1) 'scale': scale,
      };
}

/// A tool-defined marker stored at a normalized layout position.
class StrategyMarker extends StrategyElement {
  /// Creates an immutable strategy marker.
  const StrategyMarker({
    required this.position,
    required this.toolId,
    this.color,
    this.rotation = 0,
    this.scale = 1,
  }) : assert(scale > 0);

  /// The normalized center position.
  final Offset position;

  /// The stable identifier of the marker renderer.
  final String toolId;

  /// The optional Flutter ARGB override for the marker's primary color.
  final int? color;

  /// The clockwise rotation in radians.
  final double rotation;

  /// The scale factor applied around the marker center.
  final double scale;

  /// Returns a copy with updated geometry values.
  StrategyMarker copyWith({
    Offset? position,
    double? rotation,
    double? scale,
  }) =>
      StrategyMarker(
        position: position ?? this.position,
        toolId: toolId,
        color: color,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
      );

  @override
  Map<String, Object?> toJson() => {
        'type': 'marker',
        'position': _writePoint(position),
        'toolId': toolId,
        if (color != null) 'color': color,
        if (rotation != 0) 'rotation': rotation,
        if (scale != 1) 'scale': scale,
      };
}

/// A versioned strategy document associated with one editor configuration.
class StrategyDocument {
  /// Creates an immutable strategy document.
  StrategyDocument({
    required this.configId,
    required this.layoutId,
    List<StrategyElement> elements = const [],
  }) : elements = List.unmodifiable(elements);

  /// The identifier of the compatible editor configuration.
  final String configId;

  /// The identifier of the selected host layout.
  final String layoutId;

  /// The ordered elements drawn over the layout.
  final List<StrategyElement> elements;

  /// Returns a copy with an updated layout or element list.
  StrategyDocument copyWith({
    String? layoutId,
    List<StrategyElement>? elements,
  }) =>
      StrategyDocument(
        configId: configId,
        layoutId: layoutId ?? this.layoutId,
        elements: elements ?? this.elements,
      );

  /// Encodes this document using the current schema version.
  Map<String, Object?> toJson() => {
        'version': 1,
        'configId': configId,
        'layoutId': layoutId,
        'elements': elements.map((element) => element.toJson()).toList(),
      };

  /// Decodes and validates a versioned document from [json].
  factory StrategyDocument.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported strategy document version.');
    }
    return StrategyDocument(
      configId: json['configId'] as String,
      layoutId: json['layoutId'] as String,
      elements: (json['elements'] as List)
          .map(
            (element) => StrategyElement.fromJson(
              Map<String, dynamic>.from(element as Map),
            ),
          )
          .toList(),
    );
  }
}

Offset _readPoint(List point) =>
    Offset((point[0] as num).toDouble(), (point[1] as num).toDouble());

List<double> _writePoint(Offset point) => [point.dx, point.dy];
