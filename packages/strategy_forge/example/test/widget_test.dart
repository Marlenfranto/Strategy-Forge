import 'dart:async';
import 'dart:convert';

import 'package:strategy_forge_example/demo_configurations.dart';
import 'package:strategy_forge_example/demo_strategy_tool_kits.dart';
import 'package:strategy_forge_example/main.dart';
import 'package:strategy_forge/strategy_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo shell stays usable at compact width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const StrategyForgeDemo());
    await tester.pumpAndSettle();

    expect(find.text('Strategy Forge'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('demo-download'))),
      const Size(48, 48),
    );
    expect(find.byKey(const ValueKey('strategy-active-tool')), findsOneWidget);
    expect(find.byKey(const ValueKey('strategy-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo uses the short tablet landscape layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(864, 405));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const StrategyForgeDemo());
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Scaffold)), const Size(864, 405));
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 56);
    expect(find.text('Strategy editor demo'), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('strategy-layout'))).left,
      lessThan(40),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('strategy-canvas'))).width,
      greaterThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo shows one configured view without sport selection', (
    tester,
  ) async {
    final rink = await rootBundle.load('assets/rinks/full_rink.png');
    expect(rink.lengthInBytes, greaterThan(0));

    final config = DemoConfigurations.sample();
    expect(config.layouts.first.label, 'Full Rink');
    expect(
      config.tools.map((tool) => tool.kind).toSet(),
      StrategyToolKind.values.toSet(),
    );
    expect(config.tools.where((tool) => tool.group?.id == 'nets'), isEmpty);

    await tester.pumpWidget(const StrategyForgeDemo());
    expect(find.byKey(const ValueKey('demo-sport')), findsNothing);
    expect(find.text('Football'), findsNothing);
    expect(find.text('Basketball'), findsNothing);
    expect(find.byKey(const ValueKey('demo-download-settings')), findsNothing);
    expect(find.text('Full Rink'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('strategy-tool-group-draw')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategy-tool-group-lines')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategy-tool-group-shapes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategy-tool-group-add')),
      findsOneWidget,
    );
    for (final group in const [
      'pucks',
      'equipment',
      'players',
      'positions',
      'numbers',
      'teams',
      'objects',
      'targets',
      'training',
    ]) {
      expect(
        find.byKey(ValueKey('strategy-tool-group-$group')),
        findsOneWidget,
      );
    }
    for (final removedDuplicateGroup in const [
      'actions',
      'forwards',
      'defense',
      'nets',
    ]) {
      expect(
        find.byKey(ValueKey('strategy-tool-group-$removedDuplicateGroup')),
        findsNothing,
      );
    }

    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-draw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('strategy-tool-wave')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('strategy-tool-freehand_dashed_arrow')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('strategy-tool-lateral')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('strategy-tool-wave')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-lines')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('strategy-tool-line')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('strategy-tool-stop_arrow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategy-tool-dashed_stop_arrow')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('strategy-tool-line')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-shapes')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('strategy-tool-filled_rectangle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('strategy-tool-filled_ellipse')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('strategy-tool-ellipse')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('strategy-layout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Half Rink').last);
    await tester.pumpAndSettle();
    expect(find.text('Half Rink'), findsOneWidget);
  });

  testWidgets('custom icon overrides one default toolbar icon', (tester) async {
    final config = DemoConfigurations.sample(
      iconOverrides: {
        StrategyToolKind.arrow: (_) =>
            const Icon(Icons.star, key: ValueKey('custom-arrow-icon')),
      },
      iconOverridesById: {
        'puck': (_) =>
            const Icon(Icons.ac_unit, key: ValueKey('custom-puck-icon')),
      },
    );
    final controller = StrategyEditorController(config: config);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StrategyEditor(controller: controller)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('strategy-tool-group-lines')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('custom-arrow-icon')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('strategy-tool-line')),
        matching: find.byIcon(MyFlutterApp.straight_lines),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('strategy-tool-arrow')));
    await tester.pumpAndSettle();

    final pucksGroup = find.byKey(const ValueKey('strategy-tool-group-pucks'));
    await tester.ensureVisible(pucksGroup);
    await tester.pumpAndSettle();
    await tester.tap(pucksGroup);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('custom-puck-icon')), findsOneWidget);
  });

  test('every researched demo kit references packaged tools', () {
    expect(DemoStrategyToolKits.bySport, hasLength(60));
    final catalogIds = StrategyToolCatalog.all.map((tool) => tool.id).toSet();
    for (final entry in DemoStrategyToolKits.bySport.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
      expect(
        entry.value.toSet(),
        hasLength(entry.value.length),
        reason: entry.key,
      );
      expect(entry.value.every(catalogIds.contains), isTrue, reason: entry.key);
    }

    final config = DemoConfigurations.sample(
      enabledToolIds: DemoStrategyToolKits.toolIdsFor('cricket'),
    );
    expect(config.tools.map((tool) => tool.id), contains('target_wicket'));
    expect(config.tools.map((tool) => tool.id), isNot(contains('object_puck')));

    final compatibleConfig = DemoConfigurations.sample(
      enabledToolIds: const ['action_move', 'action_carry'],
      iconOverridesById: {
        'action_move': (_) => const Icon(Icons.directions_run),
      },
    );
    expect(compatibleConfig.tools.single.id, 'freehand_arrow');
    expect(compatibleConfig.tools.single.iconBuilder, isNotNull);
  });

  testWidgets('demo can start with PNG export disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DemoHome(initialDownloadEnabled: false)),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('demo-download')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('demo restores supplied JSON and returns current JSON', (
    tester,
  ) async {
    String? receivedJson;
    final halfRinkJson = jsonEncode(
      StrategyDocument(
        configId: 'demo_strategy',
        layoutId: 'half',
        elements: const [
          StrategyText(
            position: Offset(.25, .3),
            text: 'Saved play',
            color: 0xff123456,
            fontSize: 18,
          ),
        ],
      ).toJson(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DemoHome(
          strategyJson: halfRinkJson,
          onStrategyJsonChanged: (json) => receivedJson = json,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Half Rink'), findsOneWidget);
    expect(receivedJson, isNotNull);
    expect(
      (jsonDecode(receivedJson!) as Map<String, dynamic>)['layoutId'],
      'half',
    );

    final fullRinkJson = jsonEncode(
      StrategyDocument(configId: 'demo_strategy', layoutId: 'full').toJson(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHome(
          strategyJson: fullRinkJson,
          onStrategyJsonChanged: (json) => receivedJson = json,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Full Rink'), findsOneWidget);
    expect(
      (jsonDecode(receivedJson!) as Map<String, dynamic>)['layoutId'],
      'full',
    );
  });

  testWidgets('enabled download passes a PNG to the saver', (tester) async {
    var saves = 0;
    Uint8List? generatedImage;
    final saved = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: DemoHome(
          onStrategyImageGenerated: (bytes) => generatedImage = bytes,
          savePng: (bytes) async {
            saves++;
            expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
            saved.complete();
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('demo-download')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.runAsync(
      () => saved.future.timeout(const Duration(seconds: 5)),
    );
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(generatedImage?.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(find.text('PNG saved'), findsOneWidget);
  });
}
