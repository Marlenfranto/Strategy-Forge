# Strategy Forge

[Pub.dev package](https://pub.dev/packages/strategy_forge) · [Live example app](https://marlenfranto.github.io/Strategy-Forge/) · [Package source](packages/strategy_forge) · [GitHub repository](https://github.com/Marlenfranto/Strategy-Forge)

**A global strategy board for different sports, layouts, and visual planning workflows.**

Strategy Forge gives Flutter developers control over the available tools, fields and playing surfaces, layouts, colors, icons, editor controls, and data handling for every strategy view. It can power coaching, training, planning, education, and other visual strategy use cases.

This repository contains the reusable Flutter package and its complete example application:

- **Reusable package** — [`packages/strategy_forge`](packages/strategy_forge) contains the generic editor, tool catalog, bundled icons, document model, and export APIs.
- **Example app** — [`packages/strategy_forge/example`](packages/strategy_forge/example) is the package's runnable application and shows how a host configures, embeds, persists, and exports a strategy editor.

The package provides the reusable editing engine while the host application supplies the sport or use-case context. Each integration defines its layouts and tool configuration in code and connects exported JSON and PNG data to its preferred storage and sharing workflow.

[![Strategy Forge editor example](packages/strategy_forge/screenshots/strategy-forge-editor.png)](https://marlenfranto.github.io/Strategy-Forge/)

## What the example app covers

- Responsive phone, tablet, and desktop/web layouts.
- Host-owned image layouts with layout thumbnails and aspect ratios.
- All package tools enabled by default except the Nets palette.
- Code-level tool kits for 60 sports and variants, with no sport-specific logic in the package.
- Default package icons plus optional overrides by tool behavior or stable tool ID.
- Drawing colors, a **Default / Clear** color option, and configurable line widths.
- Freehand, straight, dashed, lateral, stop, backwards, wave, and two-way line notation.
- Outline and filled shapes.
- Multiline text creation and editing.
- SVG markers whose selected color changes only their declared primary color.
- Selection, repositioning, independent scaling, independent rotation, and transform controls.
- Undo, redo, and confirmed canvas clearing.
- JSON change callbacks, JSON restoration, PNG byte callbacks, and optional PNG downloads.

The full package feature and API reference is in the [Strategy Forge package README](packages/strategy_forge/README.md).

## Repository layout

| Path | Purpose |
| --- | --- |
| [`packages/strategy_forge/example/lib/main.dart`](packages/strategy_forge/example/lib/main.dart) | Example shell, `DemoHome` integration contract, callbacks, and PNG saving. |
| [`packages/strategy_forge/example/lib/demo_layouts.dart`](packages/strategy_forge/example/lib/demo_layouts.dart) | Host-owned sample layouts passed to the package. |
| [`packages/strategy_forge/example/lib/demo_configurations.dart`](packages/strategy_forge/example/lib/demo_configurations.dart) | Enabled tools, icon overrides, colors, widths, and editor configuration. |
| [`packages/strategy_forge/example/lib/demo_strategy_tool_kits.dart`](packages/strategy_forge/example/lib/demo_strategy_tool_kits.dart) | Optional host-side tool ID lists for 60 sports and variants. |
| [`packages/strategy_forge/example/assets/rinks`](packages/strategy_forge/example/assets/rinks) | Example-only background images. These do not belong to the package library. |
| [`packages/strategy_forge`](packages/strategy_forge) | Reusable Flutter package. |
| [`packages/strategy_forge/example/test`](packages/strategy_forge/example/test) | Example widget and integration-contract tests. |

## Requirements

- The reusable package requires Flutter 3.27 or later and Dart 3.6 or later.
- The example app requires Flutter 3.41 or later and Dart 3.11 or later.
- A Flutter target configured by this repository: Android, iOS, web, Windows, macOS, or Linux.

Check your local setup:

```sh
flutter doctor
flutter devices
```

## Run the example app

From the package example directory:

```sh
cd packages/strategy_forge/example
flutter pub get
flutter run
```

Choose a particular target when needed:

```sh
flutter run -d chrome
flutter run -d macos
```

## Example app configuration

### Layouts

The example app owns every layout and passes them to `StrategyEditorConfig`. Add or remove layouts in [`demo_layouts.dart`](packages/strategy_forge/example/lib/demo_layouts.dart):

```dart
StrategyLayout.asset(
  id: 'full',
  label: 'Full Rink',
  assetPath: 'assets/rinks/full_rink.png',
  aspectRatio: 1240 / 620,
)
```

Layout IDs are persisted in JSON. Keep an ID stable after saved documents exist. Declare any new example assets under `flutter.assets` in the [example pubspec](packages/strategy_forge/example/pubspec.yaml).

The example app intentionally has no file picker or layout upload control. Developers decide the available layouts while implementing the host app.

### Enabled tools

`DemoConfigurations.sample()` enables all catalog tools by default except tools in the `nets` group. Pass stable IDs to create a smaller editor:

```dart
final config = DemoConfigurations.sample(
  enabledToolIds: const [
    'select',
    'freehand',
    'arrow',
    'dashed_arrow',
    'text',
    'team_home',
    'team_away',
    'equipment_cone',
  ],
);
```

The host-side tool-kit examples can also provide the IDs:

```dart
final config = DemoConfigurations.sample(
  enabledToolIds: DemoStrategyToolKits.toolIdsFor('ice_hockey'),
);
```

These kits are implementation examples. They do not add a sport picker to the demo and are not part of the reusable package.

### Icon overrides

Override every tool with a given drawing behavior, or override one tool by ID. ID-specific overrides take precedence:

```dart
final config = DemoConfigurations.sample(
  iconOverrides: {
    StrategyToolKind.arrow: (_) => const Icon(Icons.trending_flat),
  },
  iconOverridesById: {
    'puck': (_) => const Icon(Icons.circle),
  },
);
```

Tools without an override keep the package icon. See the [package icon and marker documentation](packages/strategy_forge/README.md#icons-markers-and-color-behavior) for custom tools and custom SVG artwork.

### Colors and line widths

The example app currently uses the package defaults. Supply custom values when creating `StrategyEditorConfig` to change them:

```dart
StrategyEditorConfig(
  id: 'demo_strategy',
  name: 'Strategy Board',
  layouts: DemoLayouts.sample(),
  tools: StrategyToolCatalog.all,
  colors: const [Colors.black, Colors.red, Colors.blue, Colors.white],
  strokeWidths: const [2, 4, 8, 12],
)
```

Both lists must be non-empty, and every stroke width must be greater than zero.

## Host callbacks and persistence

`DemoHome` in the example app is a working reference wrapper around `StrategyEditorController`. It exposes the following host-facing properties:

| Property | Type | Behavior |
| --- | --- | --- |
| `strategyJson` | `String?` | Restores a saved document on startup. A later, different value is loaded too. |
| `onStrategyJsonChanged` | `ValueChanged<String>?` | Receives the current document JSON initially and whenever document content or layout changes. Duplicate JSON is suppressed. |
| `onStrategyImageGenerated` | `ValueChanged<Uint8List>?` | Receives PNG bytes after export and before the save operation. |
| `initialDownloadEnabled` | `bool` | Enables the download button when the widget state is created. Defaults to `true`. |
| `savePng` | `Future<bool> Function(Uint8List)?` | Replaces the demo file saver. Return `true` when saving succeeds. |

### Receive JSON and PNG data

```dart
DemoHome(
  strategyJson: previouslySavedJson,
  onStrategyJsonChanged: (json) {
    repository.saveDocument(json);
  },
  onStrategyImageGenerated: (bytes) {
    repository.savePreview(bytes);
  },
)
```

`onStrategyImageGenerated` runs when the user presses Download and PNG generation succeeds. It does not run after every edit.

### Restore a saved strategy

Pass the exact JSON previously returned by `onStrategyJsonChanged`:

```dart
class SavedStrategyView extends StatefulWidget {
  const SavedStrategyView({super.key});

  @override
  State<SavedStrategyView> createState() => _SavedStrategyViewState();
}

class _SavedStrategyViewState extends State<SavedStrategyView> {
  String? savedJson;

  @override
  Widget build(BuildContext context) {
    return DemoHome(
      strategyJson: savedJson,
      onStrategyJsonChanged: (json) {
        savedJson = json;
        // Persist `json` in local storage, a database, or an API.
      },
    );
  }
}
```

The saved document must use the same configuration ID, a layout ID present in the current configuration, and marker IDs that the current configuration can render. See [JSON import and export](packages/strategy_forge/README.md#json-import-and-export) for the schema and compatibility rules.

### Control PNG saving

Disable the demo download action at construction time:

```dart
const DemoHome(initialDownloadEnabled: false)
```

Provide a custom saver to upload, share, or store the generated bytes:

```dart
DemoHome(
  savePng: (bytes) async {
    await previewStorage.put(bytes, contentType: 'image/png');
    return true;
  },
)
```

When `savePng` is omitted, the example app uses `file_saver`: a browser download on web and a platform save dialog on native targets. The generated image contains the selected background layout and strategy elements, without the editor controls.

## JSON and image data ownership

The package does not write strategy documents to disk, call a backend, or choose a state-management library. The host app owns:

- when and where JSON is persisted;
- authentication and remote synchronization;
- conflict handling and document naming;
- PNG download, upload, sharing, and retention;
- migration policy if host-defined IDs change.

This keeps the reusable editor independent of product infrastructure.

## Dependencies

### Example app

| Dependency | Use |
| --- | --- |
| Flutter SDK | UI, rendering, gestures, and platform targets. |
| Local `strategy_forge` package | Strategy editor and document APIs. |
| `file_saver` | Default PNG download/save behavior in the example app. |
| `flutter_lints` | Development lint rules. |
| `flutter_test` | Demo widget tests. |

The example app's production dependency versions are defined in its [`pubspec.yaml`](packages/strategy_forge/example/pubspec.yaml). The reusable package has its own dependency list in [`packages/strategy_forge/pubspec.yaml`](packages/strategy_forge/pubspec.yaml).

The example app uses the normal Flutter web JavaScript build. Applications with different storage requirements can replace the default saver through `savePng`.

## Validation

Run example app checks from its directory:

```sh
cd packages/strategy_forge/example
flutter analyze
flutter test
```

Run package checks separately:

```sh
cd packages/strategy_forge
flutter pub get
flutter analyze
flutter test
```

The tests cover compact and tablet layouts, tool configuration, icon overrides, callbacks, JSON restoration, download behavior, bundled assets, document history, selection transforms, and drawing notation.

## Integration checklist

1. Add `strategy_forge` to the host app.
2. Declare host-owned layout assets.
3. Create layouts with stable IDs and correct aspect ratios.
4. Select tools by stable catalog ID or tool kind.
5. Add any icon or marker overrides.
6. Create and dispose a `StrategyEditorController` with the host screen.
7. Persist `controller.exportJson()` when the document changes.
8. Restore with `controller.loadJson()` after creating a compatible configuration.
9. Route `controller.exportPng()` bytes to the host's download, sharing, or upload flow.
10. Test the intended phone, tablet, desktop, and web constraints.

## Licensing

Strategy Forge is open-source software released under the [MIT License](LICENSE). You may use, copy, modify, merge, publish, distribute, sublicense, and sell copies subject to the license terms, including retaining the copyright and permission notices.

Third-party packages retain their respective licenses. Review their package pages and the license notices generated by Flutter when distributing an application.
