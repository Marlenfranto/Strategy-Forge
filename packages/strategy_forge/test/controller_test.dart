import 'dart:convert';
import 'package:strategy_forge/strategy_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StrategyEditorConfig testConfig() => StrategyEditorConfig(
      id: 'custom_view',
      name: 'Custom View',
      layouts: [
        StrategyLayout(
            id: 'full', label: 'Full', builder: (_) => const SizedBox()),
        StrategyLayout(
            id: 'half', label: 'Half', builder: (_) => const SizedBox()),
      ],
      tools: const [
        StrategyTool(
          id: 'line',
          label: 'Line',
          kind: StrategyToolKind.line,
          icon: Icons.horizontal_rule,
        ),
      ],
    );

void main() {
  test('color selection can return to tool defaults', () {
    final controller = StrategyEditorController(config: testConfig());
    addTearDown(controller.dispose);

    expect(controller.selectedColor, Colors.black);
    controller.selectColor(Colors.red);
    expect(controller.selectedColor, Colors.red);
    expect(controller.color, Colors.red);

    controller.clearColor();
    expect(controller.selectedColor, isNull);
    expect(controller.color, Colors.black);
  });

  test('document changes, undo, redo, and JSON round-trip', () {
    final controller = StrategyEditorController(config: testConfig());
    addTearDown(controller.dispose);

    controller.addElement(
      StrategyStroke(
        kind: StrategyToolKind.line,
        points: const [Offset(0.1, 0.2), Offset(0.8, 0.7)],
        color: Colors.red.toARGB32(),
        width: 4,
      ),
    );
    controller.selectLayout('half');
    expect(controller.document.elements, hasLength(1));
    expect(controller.document.layoutId, 'half');

    final json = controller.exportJson();
    final restored = StrategyDocument.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
    expect(restored.toJson(), controller.document.toJson());

    controller.undo();
    expect(controller.document.layoutId, 'full');
    controller.undo();
    expect(controller.document.elements, isEmpty);
    controller.redo();
    expect(controller.document.elements, hasLength(1));
    controller.addElement(
      const StrategyText(
        position: Offset(0.5, 0.5),
        text: 'Press',
        color: 0xff000000,
        fontSize: 18,
      ),
    );
    expect(controller.canRedo, isFalse);

    controller.loadJson(json);
    expect(controller.document.toJson(), restored.toJson());
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isFalse);
  });

  test('document rejects an unrelated editor configuration', () {
    expect(
      () => StrategyEditorController(
        config: testConfig(),
        document: StrategyDocument(configId: 'another', layoutId: 'full'),
      ),
      throwsArgumentError,
    );
  });

  test('marker colors round-trip while older markers keep default artwork', () {
    const colored = StrategyMarker(
      position: Offset(0.25, 0.75),
      toolId: 'pin',
      color: 0xfff44336,
      rotation: 0.5,
      scale: 1.4,
    );
    final restored = StrategyElement.fromJson(colored.toJson());
    expect(restored, isA<StrategyMarker>());
    expect((restored as StrategyMarker).color, 0xfff44336);
    expect(restored.rotation, 0.5);
    expect(restored.scale, 1.4);

    final legacy = StrategyElement.fromJson({
      'type': 'marker',
      'position': [0.25, 0.75],
      'toolId': 'pin',
    });
    expect((legacy as StrategyMarker).color, isNull);
    expect(legacy.rotation, 0);
    expect(legacy.scale, 1);
  });

  test('editor instances keep their histories separate', () {
    final config = testConfig();
    final first = StrategyEditorController(config: config);
    final second = StrategyEditorController(config: config);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    first.addElement(
      StrategyStroke(
        kind: StrategyToolKind.line,
        points: const [Offset(0, 0), Offset(1, 1)],
        color: Colors.black.toARGB32(),
        width: 2,
      ),
    );

    expect(first.document.elements, hasLength(1));
    expect(second.document.elements, isEmpty);
    expect(second.canUndo, isFalse);
  });
}
