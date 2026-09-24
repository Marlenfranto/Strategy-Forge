import 'package:strategy_forge/strategy_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog covers every generic editing behavior', () {
    expect(
      StrategyToolCatalog.all.map((tool) => tool.kind).toSet(),
      StrategyToolKind.values.toSet(),
    );
    expect(
      StrategyToolCatalog.select(const [
        StrategyToolKind.line,
        StrategyToolKind.marker,
      ]).map((tool) => tool.id),
      ['line', 'marker'],
    );
    expect(
      StrategyToolCatalog.all.map((tool) => tool.id),
      containsAll(const [
        'freehand_dashed_arrow',
        'stop_arrow',
        'dashed_stop_arrow',
        'filled_rectangle',
        'filled_ellipse',
      ]),
    );
    expect(StrategyToolCatalog.core, hasLength(23));
    expect(StrategyToolCatalog.svgTools, hasLength(34));
    expect(StrategyToolCatalog.universalMarkerTools, hasLength(29));
    expect(StrategyToolCatalog.universalTools, hasLength(29));
    expect(StrategyToolCatalog.all, hasLength(86));
    expect(
      StrategyToolCatalog.all.map((tool) => tool.id).toSet(),
      hasLength(86),
    );
    expect(
      StrategyToolCatalog.selectByIds(const [
        'puck',
        'equipment_cone',
        'number_9',
      ]).map((tool) => tool.id),
      ['puck', 'equipment_cone', 'number_9'],
    );
    expect(
      () => StrategyToolCatalog.selectByIds(const ['missing_tool']),
      throwsArgumentError,
    );
  });

  test('duplicate behavior and artwork aliases resolve to canonical tools', () {
    expect(
      StrategyToolCatalog.all
          .where((tool) => tool.kind != StrategyToolKind.marker)
          .map((tool) => tool.kind)
          .toSet(),
      hasLength(22),
    );
    final markerAssets = StrategyToolCatalog.all
        .where((tool) => tool.svgAssetPath != null)
        .map((tool) => tool.svgAssetPath)
        .toList();
    expect(markerAssets.toSet(), hasLength(markerAssets.length));

    expect(StrategyToolCatalog.toolById('action_move').id, 'freehand_arrow');
    expect(StrategyToolCatalog.toolById('object_puck').id, 'puck');
    expect(
      StrategyToolCatalog.toolById('position_goalie').id,
      'role_goalkeeper',
    );
    expect(
      StrategyToolCatalog.selectByIds(const [
        'freehand_arrow',
        'action_move',
        'action_carry',
      ]).map((tool) => tool.id),
      ['freehand_arrow'],
    );
  });

  test('original SVG palettes retain their complete group structure', () {
    final counts = <String, int>{};
    for (final tool in StrategyToolCatalog.svgTools) {
      counts.update(tool.group!.id, (count) => count + 1, ifAbsent: () => 1);
      expect(tool.svgAssetPackage, StrategyToolAssets.packageName);
      expect(tool.primarySvgColor, isNotNull);
    }
    expect(counts, {
      'pucks': 2,
      'equipment': 7,
      'nets': 5,
      'players': 6,
      'positions': 5,
      'numbers': 9,
    });
  });

  test('multicolor marker groups declare their editable primary colors', () {
    const expected = <String, Color>{
      'equipment_tire': Colors.black,
      'net_up': Color(0xffd00000),
      'player_forward': Color(0xff247ba0),
      'position_center': Colors.black,
      'team_home': Color(0xff2774ae),
      'object_oval_ball': Color(0xffa85d32),
      'target_hoop': Color(0xffd94b4b),
      'training_zone': Color(0xff5fb3d9),
    };
    for (final entry in expected.entries) {
      expect(
        StrategyToolCatalog.toolById(entry.key).primarySvgColor,
        entry.value,
        reason: entry.key,
      );
    }
  });

  testWidgets('all bundled SVGs and custom fonts are packaged', (tester) async {
    expect(StrategyToolAssets.all, hasLength(77));
    expect(StrategyToolAssets.all.toSet(), hasLength(77));
    for (final asset in StrategyToolAssets.all) {
      final data = await rootBundle.load(
        'packages/${StrategyToolAssets.packageName}/$asset',
      );
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
    for (final font in const ['CustomIcon.ttf', 'MyFlutterApp.ttf']) {
      final data = await rootBundle.load(
        'packages/${StrategyToolAssets.packageName}/assets/fonts/$font',
      );
      expect(data.lengthInBytes, greaterThan(0), reason: font);
    }
  });

  testWidgets('selected tools and optional custom icon appear in editor', (
    tester,
  ) async {
    final config = StrategyEditorConfig(
      id: 'view',
      name: 'View',
      layouts: [
        StrategyLayout(
          id: 'background',
          label: 'Background',
          builder: (_) => const ColoredBox(color: Colors.blue),
        ),
      ],
      tools: [
        StrategyToolCatalog.tool(StrategyToolKind.line).withIconBuilder(
          (_) => const Icon(Icons.star, key: ValueKey('custom-line-icon')),
        ),
        StrategyToolCatalog.tool(StrategyToolKind.marker),
      ],
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );

    expect(find.byKey(const ValueKey('custom-line-icon')), findsWidgets);
    expect(
      find.byKey(const ValueKey('strategy-tool-group-lines')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategy-tool-group-add')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('strategy-tool-marker')), findsOneWidget);
    expect(find.byKey(const ValueKey('strategy-tool-arrow')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('strategy-tool-marker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('strategy-canvas')));
    await tester.pump();
    expect(controller.document.elements.single, isA<StrategyMarker>());
    expect(find.byIcon(Icons.place), findsOneWidget);
  });

  testWidgets('package icon is used when no override is provided', (
    tester,
  ) async {
    final tool = StrategyToolCatalog.tool(StrategyToolKind.ellipse);
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: (context) => tool.buildIcon(context))),
    );
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('legacy font glyphs and SVG markers render from the package', (
    tester,
  ) async {
    final line = StrategyToolCatalog.tool(StrategyToolKind.line);
    final puck = StrategyToolCatalog.toolById('puck');
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Builder(builder: line.buildIcon),
            SizedBox.square(
              dimension: puck.markerSize,
              child: Builder(builder: puck.buildMarker),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(MyFlutterApp.straight_lines), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('packaged SVG markers recolor only their primary color', (
    tester,
  ) async {
    final tire = StrategyToolCatalog.toolById('equipment_tire');
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox.square(
              key: const ValueKey('colored-marker'),
              dimension: tire.markerSize,
              child: Builder(
                builder: (context) =>
                    tire.buildMarkerWithColor(context, color: Colors.red),
              ),
            ),
            SizedBox.square(
              key: const ValueKey('default-marker'),
              dimension: tire.markerSize,
              child: Builder(builder: tire.buildMarker),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final colored = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(const ValueKey('colored-marker')),
        matching: find.byType(SvgPicture),
      ),
    );
    final original = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(const ValueKey('default-marker')),
        matching: find.byType(SvgPicture),
      ),
    );
    final mapper = (colored.bytesLoader as SvgAssetLoader).colorMapper;
    expect(mapper, isNotNull);
    expect(
      mapper!.substitute(null, 'svg', 'fill', tire.primarySvgColor!),
      Colors.red,
    );
    expect(mapper.substitute(null, 'path', 'fill', Colors.white), Colors.white);
    expect(colored.colorFilter, isNull);
    expect((original.bytesLoader as SvgAssetLoader).colorMapper, isNull);
    expect(original.colorFilter, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all catalog tool icons render', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Wrap(
            children: [
              for (final tool in StrategyToolCatalog.all)
                Builder(builder: tool.buildIcon),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
