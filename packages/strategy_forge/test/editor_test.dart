import 'dart:math' as math;

import 'package:strategy_forge/strategy_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom tools draw, place markers, and export the layout', (
    tester,
  ) async {
    final config = StrategyEditorConfig(
      id: 'custom_view',
      name: 'Custom View',
      layouts: [
        StrategyLayout(
          id: 'field',
          label: 'Field',
          builder: (_) => const ColoredBox(color: Colors.green),
        ),
      ],
      tools: [
        const StrategyTool(
          id: 'line',
          label: 'Line',
          kind: StrategyToolKind.line,
          icon: Icons.horizontal_rule,
        ),
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          icon: Icons.person,
          markerBuilder: (_) => const Icon(Icons.person),
        ),
      ],
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );

    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    await tester.timedDrag(
      canvas,
      const Offset(80, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pump();
    expect(controller.document.elements, hasLength(1));
    expect(controller.document.elements.first, isA<StrategyStroke>());

    controller.selectTool('pin');
    await tester.pump();
    await tester.tap(canvas);
    await tester.pump();
    expect(controller.document.elements, hasLength(2));
    expect(controller.document.elements.last, isA<StrategyMarker>());

    final export = controller.exportPng();
    await tester.pump();
    final png = await tester.runAsync(() => export);
    expect(png, isNotNull);
    expect(png!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  testWidgets('existing markers remain visible when their tool is hidden', (
    tester,
  ) async {
    final marker = StrategyTool(
      id: 'pin',
      label: 'Pin',
      kind: StrategyToolKind.marker,
      icon: Icons.person,
      markerBuilder: (_) => const Text('Existing pin'),
    );
    final config = StrategyEditorConfig(
      id: 'view_1',
      name: 'View',
      layouts: [
        StrategyLayout(
          id: 'field',
          label: 'Field',
          builder: (_) => const ColoredBox(color: Colors.green),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'line',
          label: 'Line',
          kind: StrategyToolKind.line,
          icon: Icons.horizontal_rule,
        ),
      ],
      markerRenderers: [marker],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'field',
        elements: const [
          StrategyMarker(position: Offset(0.5, 0.5), toolId: 'pin'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );

    expect(find.text('Existing pin'), findsOneWidget);
    expect(find.byKey(const ValueKey('strategy-tool-pin')), findsNothing);
    expect(find.byKey(const ValueKey('strategy-tool-group-add')), findsNothing);
  });

  testWidgets('clear action asks for confirmation', (tester) async {
    final config = StrategyEditorConfig(
      id: 'clear_view',
      name: 'Clear View',
      layouts: [
        StrategyLayout(
          id: 'field',
          label: 'Field',
          builder: (_) => const ColoredBox(color: Colors.green),
        ),
      ],
      tools: const [
        StrategyTool(id: 'line', label: 'Line', kind: StrategyToolKind.line),
      ],
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('strategy-canvas')),
      const Offset(80, 0),
    );
    await tester.pump();
    expect(controller.document.elements, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('strategy-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Clear the canvas?'), findsOneWidget);
    expect(controller.document.elements, hasLength(1));

    await tester.tap(find.text('Clear canvas'));
    await tester.pumpAndSettle();
    expect(controller.document.elements, isEmpty);
  });

  testWidgets('marker color is captured and Default restores its artwork', (
    tester,
  ) async {
    final config = StrategyEditorConfig(
      id: 'marker_color',
      name: 'Marker color',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: [
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          markerBuilder: (_) => const Icon(Icons.place),
        ),
      ],
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);
    controller.selectColor(Colors.red);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    await tester.tap(canvas);
    await tester.pump();

    expect(
      (controller.document.elements.single as StrategyMarker).color,
      Colors.red.toARGB32(),
    );
    expect(find.byType(ColorFiltered), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('strategy-color')));
    await tester.pumpAndSettle();
    expect(find.text('Default / Clear'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('strategy-color-default')));
    await tester.pumpAndSettle();

    expect(controller.selectedColor, isNull);
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(canvas);
    await tester.pump();

    expect(controller.document.elements, hasLength(2));
    expect((controller.document.elements.last as StrategyMarker).color, isNull);
    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  testWidgets('Add text dialog guides input and requires a label', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = StrategyEditorConfig(
      id: 'add_text_dialog',
      name: 'Add text dialog',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(id: 'text', label: 'Text', kind: StrategyToolKind.text),
      ],
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    await tester.tapAt(tester.getRect(canvas).center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('strategy-add-text-dialog')),
      findsOneWidget,
    );
    expect(
      find.text('Create a multiline label on the canvas.'),
      findsOneWidget,
    );
    expect(
      find.text('You can move, rotate, and resize it after adding.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('strategy-add-text-submit')),
          )
          .onPressed,
      isNull,
    );
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('strategy-add-text-input')),
    );
    expect(input.minLines, 3);
    expect(input.maxLines, 6);
    expect(input.keyboardType, TextInputType.multiline);
    expect(input.textInputAction, TextInputAction.newline);

    await tester.enterText(
      find.byKey(const ValueKey('strategy-add-text-input')),
      '  Power\nplay  ',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('strategy-add-text-submit')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('strategy-add-text-submit')));
    await tester.pumpAndSettle();

    final text = controller.document.elements.single as StrategyText;
    expect(text.text, 'Power\nplay');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Selected multiline text can be edited without losing transform',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final config = StrategyEditorConfig(
        id: 'edit_text',
        name: 'Edit text',
        layouts: [
          StrategyLayout(
            id: 'background',
            label: 'Background',
            builder: (_) => const ColoredBox(color: Colors.white),
          ),
        ],
        tools: const [
          StrategyTool(
            id: 'select',
            label: 'Select',
            kind: StrategyToolKind.select,
          ),
        ],
      );
      const original = StrategyText(
        position: Offset(.3, .4),
        text: 'First line',
        color: 0xFF123456,
        fontSize: 18,
        rotation: .2,
        scale: 1.3,
      );
      final controller = StrategyEditorController(
        config: config,
        document: StrategyDocument(
          configId: config.id,
          layoutId: 'background',
          elements: const [original],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StrategyEditor(controller: controller)),
        ),
      );
      final canvas = find.byKey(const ValueKey('strategy-canvas'));
      final rect = tester.getRect(canvas);
      await tester.tapAt(
        Offset(
          rect.left + rect.width * .3 + 8,
          rect.top + rect.height * .4 + 8,
        ),
      );
      await tester.pump();

      final editButton = find.byKey(
        const ValueKey('strategy-selection-edit-text'),
      );
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit text'), findsOneWidget);
      expect(find.text('Update this canvas label.'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      final input = find.byKey(const ValueKey('strategy-add-text-input'));
      expect(tester.widget<TextField>(input).controller?.text, 'First line');

      await tester.enterText(input, 'First line\nSecond line');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('strategy-add-text-submit')));
      await tester.pumpAndSettle();

      final edited = controller.document.elements.single as StrategyText;
      expect(edited.text, 'First line\nSecond line');
      expect(edited.position, original.position);
      expect(edited.color, original.color);
      expect(edited.fontSize, original.fontSize);
      expect(edited.rotation, original.rotation);
      expect(edited.scale, original.scale);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Select rotates, scales, and repositions an item', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = StrategyEditorConfig(
      id: 'selection',
      name: 'Selection',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'select',
          label: 'Select',
          kind: StrategyToolKind.select,
        ),
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          icon: Icons.place,
        ),
      ],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'background',
        elements: const [
          StrategyMarker(position: Offset(.5, .5), toolId: 'pin'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    final canvasRect = tester.getRect(canvas);
    await tester.tapAt(canvasRect.center);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('strategy-selection-rotate-right')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('strategy-selection-rotate-right')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('strategy-selection-scale-up')));
    await tester.pump();

    var marker = controller.document.elements.single as StrategyMarker;
    expect(marker.rotation, closeTo(math.pi / 12, .0001));
    expect(marker.scale, closeTo(1.1, .0001));

    await tester.dragFrom(canvasRect.center, const Offset(80, 30));
    await tester.pump();
    marker = controller.document.elements.single as StrategyMarker;
    expect(marker.position.dx, closeTo(.5 + 80 / canvasRect.width, .01));
    expect(marker.position.dy, closeTo(.5 + 30 / canvasRect.height, .01));
    expect(controller.canUndo, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Select corner handles scale without rotating an item', (
    tester,
  ) async {
    final config = StrategyEditorConfig(
      id: 'selection_handle',
      name: 'Selection handle',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'select',
          label: 'Select',
          kind: StrategyToolKind.select,
        ),
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          icon: Icons.place,
        ),
      ],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'background',
        elements: const [
          StrategyMarker(position: Offset(.5, .5), toolId: 'pin'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    final center = tester.getRect(canvas).center;
    await tester.tapAt(center);
    await tester.pump();

    // A default 32px marker has a selection handle 24px from its center.
    await tester.dragFrom(center + const Offset(24, -24), const Offset(30, 15));
    await tester.pump();

    final marker = controller.document.elements.single as StrategyMarker;
    expect(marker.position, const Offset(.5, .5));
    expect(marker.scale, greaterThan(1.5));
    expect(marker.rotation, closeTo(0, .0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Select rotation handle rotates without scaling an item', (
    tester,
  ) async {
    final config = StrategyEditorConfig(
      id: 'selection_rotation_handle',
      name: 'Selection rotation handle',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'select',
          label: 'Select',
          kind: StrategyToolKind.select,
        ),
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          icon: Icons.place,
        ),
      ],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'background',
        elements: const [
          StrategyMarker(position: Offset(.5, .5), toolId: 'pin'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    final center = tester.getRect(canvas).center;
    await tester.tapAt(center);
    await tester.pump();

    // The rotation handle sits 28px beyond the 24px selection box.
    await tester.dragFrom(center + const Offset(0, -52), const Offset(40, 25));
    await tester.pump();

    var marker = controller.document.elements.single as StrategyMarker;
    expect(marker.position, const Offset(.5, .5));
    expect(marker.rotation, greaterThan(.5));
    expect(marker.scale, closeTo(1, .0001));

    final rotation = marker.rotation;
    final rotatedCorner = Offset(
      24 * math.cos(rotation) + 24 * math.sin(rotation),
      24 * math.sin(rotation) - 24 * math.cos(rotation),
    );
    await tester.dragFrom(center + rotatedCorner, rotatedCorner);
    await tester.pump();

    marker = controller.document.elements.single as StrategyMarker;
    expect(marker.rotation, closeTo(rotation, .0001));
    expect(marker.scale, greaterThan(1.8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Select uses operation-specific mouse cursors', (tester) async {
    final config = StrategyEditorConfig(
      id: 'selection_cursors',
      name: 'Selection cursors',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'select',
          label: 'Select',
          kind: StrategyToolKind.select,
        ),
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          icon: Icons.place,
        ),
      ],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'background',
        elements: const [
          StrategyMarker(position: Offset(.5, .5), toolId: 'pin'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    final center = tester.getRect(canvas).center;
    await tester.tapAt(center);
    await tester.pump();

    const pointer = 1;
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: pointer,
    );
    await mouse.addPointer(location: center);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(pointer),
      SystemMouseCursors.move,
    );

    await mouse.moveTo(center + const Offset(24, -24));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(pointer),
      SystemMouseCursors.resizeUpRightDownLeft,
    );

    final rotationHandle = center + const Offset(0, -52);
    await mouse.moveTo(rotationHandle);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(pointer),
      SystemMouseCursors.grab,
    );

    await mouse.down(rotationHandle);
    await mouse.moveTo(rotationHandle + const Offset(20, 4));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(pointer),
      SystemMouseCursors.grabbing,
    );
    await mouse.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Select supports pinch scaling without rotation', (tester) async {
    final config = StrategyEditorConfig(
      id: 'selection_multitouch',
      name: 'Selection multitouch',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'select',
          label: 'Select',
          kind: StrategyToolKind.select,
        ),
        StrategyTool(
          id: 'pin',
          label: 'Pin',
          kind: StrategyToolKind.marker,
          icon: Icons.place,
        ),
      ],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'background',
        elements: const [
          StrategyMarker(position: Offset(.5, .5), toolId: 'pin'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    final center = tester.getRect(canvas).center;
    await tester.tapAt(center);
    await tester.pump();

    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(center + const Offset(-15, 0));
    await second.down(center + const Offset(15, 0));
    await first.moveTo(center + const Offset(-30, -15));
    await second.moveTo(center + const Offset(30, 15));
    await first.up();
    await second.up();
    await tester.pump();

    final marker = controller.document.elements.single as StrategyMarker;
    expect(marker.scale, greaterThan(1.3));
    expect(marker.rotation, closeTo(0, .0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Select also transforms drawn paths and text', (tester) async {
    final config = StrategyEditorConfig(
      id: 'selection_types',
      name: 'Selection types',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: const [
        StrategyTool(
          id: 'select',
          label: 'Select',
          kind: StrategyToolKind.select,
        ),
      ],
    );
    final controller = StrategyEditorController(
      config: config,
      document: StrategyDocument(
        configId: config.id,
        layoutId: 'background',
        elements: [
          StrategyStroke(
            kind: StrategyToolKind.line,
            points: const [Offset(.2, .25), Offset(.8, .25)],
            color: Colors.black.toARGB32(),
            width: 4,
          ),
          StrategyText(
            position: const Offset(.2, .65),
            text: 'Label',
            color: Colors.black.toARGB32(),
            fontSize: 18,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));
    final rect = tester.getRect(canvas);
    await tester.tapAt(Offset(rect.center.dx, rect.top + rect.height * .25));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('strategy-selection-scale-down')),
    );
    await tester.pump();
    expect(
      (controller.document.elements.first as StrategyStroke).scale,
      closeTo(.9, .0001),
    );

    await tester.tapAt(
      Offset(rect.left + rect.width * .2 + 8, rect.top + rect.height * .65 + 8),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('strategy-selection-rotate-left')),
    );
    await tester.pump();
    expect(
      (controller.document.elements.last as StrategyText).rotation,
      closeTo(-math.pi / 12, .0001),
    );
  });

  testWidgets('tool menu keeps wide icons separate from aligned labels', (
    tester,
  ) async {
    final config = StrategyEditorConfig(
      id: 'tool_menu_spacing',
      name: 'Tool menu spacing',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: StrategyToolCatalog.core,
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-draw')));
    await tester.pumpAndSettle();

    const drawToolIds = [
      'freehand',
      'freehand_arrow',
      'freehand_dashed_arrow',
      'freehand_stop_arrow',
      'lateral',
      'lateral_stop',
      'backwards',
      'wave',
      'double_arrow',
      'dashed_double_arrow',
    ];
    double? labelLeft;
    for (final id in drawToolIds) {
      final tool = StrategyToolCatalog.toolById(id);
      final item = find.byKey(ValueKey('strategy-tool-$id'));
      final icon = find.descendant(
        of: item,
        matching: find.byKey(ValueKey('strategy-tool-icon-$id')),
      );
      final label = find.descendant(of: item, matching: find.text(tool.label));
      final iconRect = tester.getRect(icon);
      final labelRect = tester.getRect(label);

      expect(labelRect.left - iconRect.right, greaterThanOrEqualTo(12));
      labelLeft ??= labelRect.left;
      expect(labelRect.left, moreOrLessEquals(labelLeft, epsilon: .01));
    }

    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-lines')));
    await tester.pumpAndSettle();

    const lineToolIds = [
      'line',
      'arrow',
      'stop_arrow',
      'dashed_line',
      'dashed_arrow',
      'dashed_stop_arrow',
    ];
    labelLeft = null;
    for (final id in lineToolIds) {
      final tool = StrategyToolCatalog.toolById(id);
      final item = find.byKey(ValueKey('strategy-tool-$id'));
      final icon = find.descendant(
        of: item,
        matching: find.byKey(ValueKey('strategy-tool-icon-$id')),
      );
      final label = find.descendant(of: item, matching: find.text(tool.label));
      final iconRect = tester.getRect(icon);
      final labelRect = tester.getRect(label);

      expect(labelRect.left - iconRect.right, greaterThanOrEqualTo(12));
      labelLeft ??= labelRect.left;
      expect(labelRect.left, moreOrLessEquals(labelLeft, epsilon: .01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact editor keeps controls usable with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = StrategyEditorConfig(
      id: 'responsive_editor',
      name: 'Responsive editor',
      layouts: [
        StrategyLayout(
          id: 'layout',
          label: 'Full layout with a long name',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: StrategyToolCatalog.all,
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(body: StrategyEditor(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final activeTool = tester.widget<Semantics>(
      find.byKey(const ValueKey('strategy-active-tool')),
    );
    expect(activeTool.properties.label, startsWith('Active tool: Select.'));
    expect(
      tester.getSize(find.byKey(const ValueKey('strategy-layout'))).height,
      greaterThanOrEqualTo(48),
    );
    final drawGroup = find.byKey(const ValueKey('strategy-tool-group-draw'));
    await tester.ensureVisible(drawGroup);
    expect(tester.getSize(drawGroup).height, greaterThanOrEqualTo(64));
    expect(tester.getSize(drawGroup).width, greaterThanOrEqualTo(72));
    expect(find.byKey(const ValueKey('strategy-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'short tablet layout keeps canvas and selection controls usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(864, 337));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final config = StrategyEditorConfig(
        id: 'tablet_landscape',
        name: 'Tablet landscape',
        layouts: [
          StrategyLayout(
            id: 'layout',
            label: 'Full layout',
            builder: (_) => const ColoredBox(color: Colors.white),
          ),
        ],
        tools: const [
          StrategyTool(
            id: 'select',
            label: 'Select',
            kind: StrategyToolKind.select,
          ),
          StrategyTool(
            id: 'pin',
            label: 'Pin',
            kind: StrategyToolKind.marker,
            icon: Icons.place,
          ),
        ],
      );
      final controller = StrategyEditorController(
        config: config,
        document: StrategyDocument(
          configId: config.id,
          layoutId: 'layout',
          elements: const [
            StrategyMarker(position: Offset(.5, .5), toolId: 'pin'),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StrategyEditor(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      final layoutControl = tester.getRect(
        find.byKey(const ValueKey('strategy-layout')),
      );
      expect(layoutControl.left, lessThan(40));

      final canvas = find.byKey(const ValueKey('strategy-canvas'));
      var canvasRect = tester.getRect(canvas);
      expect(canvasRect.width, greaterThanOrEqualTo(320));
      await tester.tapAt(canvasRect.center);
      await tester.pump();

      canvasRect = tester.getRect(canvas);
      final selectionControls = tester.getRect(
        find.byKey(const ValueKey('strategy-selection-controls')),
      );
      expect(selectionControls.left, greaterThanOrEqualTo(canvasRect.left));
      expect(selectionControls.right, lessThanOrEqualTo(canvasRect.right));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restored original tools draw and export', (tester) async {
    const restoredKinds = [
      StrategyToolKind.freehandDashedArrow,
      StrategyToolKind.stopArrow,
      StrategyToolKind.dashedStopArrow,
      StrategyToolKind.filledRectangle,
      StrategyToolKind.filledEllipse,
    ];
    final config = StrategyEditorConfig(
      id: 'restored_tools',
      name: 'Restored Tools',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.white),
        ),
      ],
      tools: StrategyToolCatalog.select(restoredKinds),
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );
    final canvas = find.byKey(const ValueKey('strategy-canvas'));

    for (final kind in restoredKinds) {
      controller.selectTool(StrategyToolCatalog.tool(kind).id);
      await tester.pump();
      await tester.timedDrag(
        canvas,
        const Offset(60, 30),
        const Duration(milliseconds: 100),
      );
      await tester.pump();
      expect((controller.document.elements.last as StrategyStroke).kind, kind);
    }

    final export = controller.exportPng();
    await tester.pump();
    final png = await tester.runAsync(() => export);
    expect(png, isNotNull);
    expect(png!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
