import 'package:strategy_forge/strategy_forge.dart';
import 'package:flutter/widgets.dart';

import 'demo_layouts.dart';

/// The embedding app supplies layouts and may override any package tool icon.
class DemoConfigurations {
  DemoConfigurations._();

  static const _hiddenDefaultGroups = {'nets'};

  static StrategyEditorConfig sample({
    Map<StrategyToolKind, WidgetBuilder> iconOverrides = const {},
    Map<String, WidgetBuilder> iconOverridesById = const {},
    Iterable<String>? enabledToolIds,
  }) {
    final canonicalIconOverrides = {
      for (final entry in iconOverridesById.entries)
        StrategyToolCatalog.canonicalIdFor(entry.key): entry.value,
    };
    final selectedTools = enabledToolIds == null
        ? StrategyToolCatalog.all.where(
            (tool) => !_hiddenDefaultGroups.contains(tool.group?.id),
          )
        : StrategyToolCatalog.selectByIds(enabledToolIds);
    return StrategyEditorConfig(
      id: 'demo_strategy',
      name: 'Strategy Board',
      layouts: DemoLayouts.sample(),
      tools: [
        for (final tool in selectedTools)
          if (canonicalIconOverrides[tool.id] case final builder?)
            tool.withIconBuilder(builder)
          else if (iconOverrides[tool.kind] case final builder?)
            tool.withIconBuilder(builder)
          else
            tool,
      ],
    );
  }
}
