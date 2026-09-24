import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'document.dart';

/// Own this controller in the host app and dispose it with its screen.
class StrategyEditorController extends ChangeNotifier {
  /// Creates a controller for [config] with an optional initial [document].
  StrategyEditorController({required this.config, StrategyDocument? document})
      : _document = document ??
            StrategyDocument(
              configId: config.id,
              layoutId: config.layouts.first.id,
            ),
        _toolId = config.tools.first.id,
        _selectedColor = config.colors.first,
        _strokeWidth = config.strokeWidths.first {
    _validateDocument(_document);
  }

  /// The immutable configuration used by this controller.
  final StrategyEditorConfig config;
  StrategyDocument _document;
  final List<StrategyDocument> _undo = [];
  final List<StrategyDocument> _redo = [];
  String _toolId;
  Color? _selectedColor;
  double _strokeWidth;
  Future<Uint8List> Function(double pixelRatio)? _exporter;

  /// The current strategy document.
  StrategyDocument get document => _document;

  /// The identifier of the active tool.
  String get toolId => _toolId;

  /// The active tool definition.
  StrategyTool get tool => config.tool(_toolId);

  /// The explicitly selected color, or `null` when tool defaults are active.
  Color? get selectedColor => _selectedColor;

  /// The effective drawing color. Drawing tools use the first configured
  /// palette color while tool defaults are active.
  Color get color => _selectedColor ?? config.colors.first;

  /// The effective width used by newly drawn strokes.
  double get strokeWidth => _strokeWidth;

  /// Whether an earlier document state can be restored.
  bool get canUndo => _undo.isNotEmpty;

  /// Whether a previously undone document state can be restored.
  bool get canRedo => _redo.isNotEmpty;

  /// Activates the configured tool with [id].
  void selectTool(String id) {
    config.tool(id);
    if (_toolId == id) return;
    _toolId = id;
    notifyListeners();
  }

  /// Selects [color] for newly created elements.
  void selectColor(Color color) {
    if (!config.colors.contains(color)) {
      throw ArgumentError.value(color, 'color', 'Color is not in the palette.');
    }
    if (_selectedColor == color) return;
    _selectedColor = color;
    notifyListeners();
  }

  /// Clears the explicit color so marker tools use their original artwork.
  void clearColor() {
    if (_selectedColor == null) return;
    _selectedColor = null;
    notifyListeners();
  }

  /// Selects [width] for newly drawn strokes.
  void selectStrokeWidth(double width) {
    if (!config.strokeWidths.contains(width)) {
      throw ArgumentError.value(width, 'width', 'Width is not configured.');
    }
    _strokeWidth = width;
    notifyListeners();
  }

  /// Changes to the configured layout with [id] and records history.
  void selectLayout(String id) {
    config.layout(id);
    if (_document.layoutId == id) return;
    _commit(_document.copyWith(layoutId: id));
  }

  /// Appends [element] to the document and records history.
  void addElement(StrategyElement element) {
    _commit(_document.copyWith(elements: [..._document.elements, element]));
  }

  /// Replaces the element at [index] and records history.
  void replaceElement(int index, StrategyElement element) {
    if (index < 0 || index >= _document.elements.length) {
      throw RangeError.index(index, _document.elements);
    }
    final next = [..._document.elements];
    next[index] = element;
    _commit(_document.copyWith(elements: next));
  }

  /// Removes every element and records history.
  void clear() {
    if (_document.elements.isEmpty) return;
    _commit(_document.copyWith(elements: []));
  }

  /// Restores the most recent earlier document state when available.
  void undo() {
    if (!canUndo) return;
    _redo.add(_document);
    _document = _undo.removeLast();
    notifyListeners();
  }

  /// Restores the most recently undone document state when available.
  void redo() {
    if (!canRedo) return;
    _undo.add(_document);
    _document = _redo.removeLast();
    notifyListeners();
  }

  /// Replaces the document and starts a fresh undo history.
  void loadDocument(StrategyDocument document) {
    _validateDocument(document);
    _document = document;
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }

  /// Encodes the current document as a portable JSON string.
  String exportJson() => jsonEncode(_document.toJson());

  /// Restores a document previously returned by [exportJson].
  ///
  /// Loading validates the configuration and layout IDs and starts a fresh
  /// undo history.
  void loadJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Strategy document must be a JSON object.');
    }
    loadDocument(StrategyDocument.fromJson(Map<String, dynamic>.from(decoded)));
  }

  /// Captures the current layout, strokes, text, and markers as PNG bytes.
  Future<Uint8List> exportPng({double pixelRatio = 2}) {
    if (pixelRatio <= 0) throw ArgumentError.value(pixelRatio, 'pixelRatio');
    final exporter = _exporter;
    if (exporter == null) {
      throw StateError('Mount a StrategyEditor before exporting.');
    }
    return exporter(pixelRatio);
  }

  /// Used by [StrategyEditor] to connect its repaint boundary.
  void bindExporter(Future<Uint8List> Function(double pixelRatio)? exporter) {
    _exporter = exporter;
  }

  void _commit(StrategyDocument next) {
    _undo.add(_document);
    _document = next;
    _redo.clear();
    notifyListeners();
  }

  void _validateDocument(StrategyDocument document) {
    if (document.configId != config.id) {
      throw ArgumentError('Document belongs to another editor configuration.');
    }
    config.layout(document.layoutId);
  }
}
