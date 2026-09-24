# Strategy Forge demo

[Live web demo](https://marlenfranto.github.io/Strategy-Forge/) · [Reusable package](packages/strategy_forge) · [GitHub repository](https://github.com/Marlenfranto/Strategy-Forge)

This repository contains two Flutter projects:

- **Demo app** — the application at the repository root shows how a host app configures, embeds, persists, and exports a strategy editor.
- **Reusable package** — [`packages/strategy_forge`](packages/strategy_forge) contains the generic editor, tool catalog, bundled icons, document model, and export APIs.

Strategy Forge does not contain a sport selector or runtime layout upload flow. The host app defines its layouts in code, chooses the tools for each strategy view, and owns all storage and sharing behavior.

## What the demo covers

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
| [`lib/main.dart`](lib/main.dart) | Demo shell, `DemoHome` integration contract, callbacks, and PNG saving. |
| [`lib/demo_layouts.dart`](lib/demo_layouts.dart) | Host-owned sample layouts passed to the package. |
| [`lib/demo_configurations.dart`](lib/demo_configurations.dart) | Enabled tools, icon overrides, colors, widths, and editor configuration. |
| [`lib/demo_strategy_tool_kits.dart`](lib/demo_strategy_tool_kits.dart) | Optional host-side tool ID lists for 60 sports and variants. |
| [`assets/rinks`](assets/rinks) | Demo-only background images. These do not belong to the package. |
| [`packages/strategy_forge`](packages/strategy_forge) | Reusable Flutter package. |
| [`docs/sports-strategy-tool-audit.md`](docs/sports-strategy-tool-audit.md) | Research notes and the strategy-tool capability audit. |
| [`test`](test) | Demo widget and integration-contract tests. |

## Requirements

- Flutter with a Dart SDK compatible with `^3.5.2`.
- A Flutter target configured by this repository: Android, iOS, web, Windows, macOS, or Linux.

Check your local setup:

```sh
flutter doctor
flutter devices
```

## Run the demo

From the repository root:

```sh
flutter pub get
flutter run
```

Choose a particular target when needed:

```sh
flutter run -d chrome
flutter run -d macos
```

## Demo configuration

### Layouts

The demo owns every layout and passes them to `StrategyEditorConfig`. Add or remove layouts in [`lib/demo_layouts.dart`](lib/demo_layouts.dart):

```dart
StrategyLayout.asset(
  id: 'full',
  label: 'Full Rink',
  assetPath: 'assets/rinks/full_rink.png',
  aspectRatio: 1240 / 620,
)
```

Layout IDs are persisted in JSON. Keep an ID stable after saved documents exist. Declare any new demo assets under `flutter.assets` in [`pubspec.yaml`](pubspec.yaml).

The demo intentionally has no file picker or layout upload control. Developers decide the available layouts while implementing the host app.

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

The demo currently uses the package defaults. Supply custom values when creating `StrategyEditorConfig` to change them:

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

`DemoHome` is a working reference wrapper around `StrategyEditorController`. It exposes the following host-facing properties:

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

When `savePng` is omitted, the demo uses `public_file_saver`: a browser download on web and a platform save dialog on native targets. The generated image contains the selected background layout and strategy elements, without the editor controls.

## JSON and image data ownership

The package does not write strategy documents to disk, call a backend, or choose a state-management library. The host app owns:

- when and where JSON is persisted;
- authentication and remote synchronization;
- conflict handling and document naming;
- PNG download, upload, sharing, and retention;
- migration policy if host-defined IDs change.

This keeps the reusable editor independent of product infrastructure.

## Dependencies

### Demo app

| Dependency | Use |
| --- | --- |
| Flutter SDK | UI, rendering, gestures, and platform targets. |
| Local `strategy_forge` package | Strategy editor and document APIs. |
| `public_file_saver` | Default PNG download/save behavior in the demo. |
| `flutter_lints` | Development lint rules. |
| `flutter_test` | Demo widget tests. |

The demo's production dependency versions are defined in [`pubspec.yaml`](pubspec.yaml). The reusable package has its own dependency list in [`packages/strategy_forge/pubspec.yaml`](packages/strategy_forge/pubspec.yaml).

`public_file_saver` currently depends on browser APIs that prevent a Flutter WASM build. A normal Flutter web JavaScript build is supported by the demo. Applications that require WASM can replace the demo saver through `savePng` and select a WASM-compatible storage implementation.

## Validation

Run demo checks from the repository root:

```sh
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

Package maintainers should follow the [pub.dev publishing checklist](docs/pub-dev-publishing.md). The checklist covers account ownership, verified publishers, release validation, archive review, and the manual publication step. Preparing or pushing this repository does not publish the package.

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
