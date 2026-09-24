# Pub.dev publishing checklist

This checklist prepares `packages/strategy_forge` for a public release. It does not publish the package.

## Current release candidate

- Package: `strategy_forge`
- Version: `0.1.0`
- License: MIT
- Minimum SDKs: Dart 3.6 and Flutter 3.27
- Supported platforms: Android, iOS, Linux, macOS, web, and Windows
- Repository: <https://github.com/Marlenfranto/Strategy-Forge>
- Pub.dev name search on 24 September 2026: no matching package was returned. Availability is not reserved until the first publication, so check again immediately before publishing.

## Account preparation

1. Sign in to pub.dev with the Google Account that will own the first release.
2. Prefer a [verified publisher](https://dart.dev/tools/pub/publishing#advantages-of-using-a-verified-publisher) when an organization domain is available.
3. Add at least one additional publisher administrator so package access does not depend on one account.
4. Confirm that the publishing account has permission to release the source, SVG artwork, fonts, and every other packaged asset.

The first version must be uploaded by a Google Account and can then be transferred to a verified publisher. Do not store pub.dev credentials or access tokens in this repository.

## Release preparation

1. Confirm that the version in `pubspec.yaml` has never been published. Published versions are immutable.
2. Move all user-visible changes into the matching version section in `CHANGELOG.md`.
3. Confirm that `README.md`, `LICENSE`, repository links, issue tracker, topics, SDK constraints, and platform declarations remain accurate.
4. Keep `pubspec.lock`, `.dart_tool`, `build`, generated API documentation, coverage output, and local credentials outside the package archive.
5. Run all checks from the package directory:

   ```sh
   flutter pub get
   dart format --output=none --set-exit-if-changed lib test example
   flutter analyze
   flutter test
   dart doc
   pana --no-warning
   dart pub publish --dry-run
   ```

6. Review every file listed by the dry run. Confirm that the archive contains only the package source, example, tests, documentation, license, and declared assets.
7. Confirm that the compressed and uncompressed package sizes remain below pub.dev limits.
8. Commit and push the exact release candidate, then create a `v0.1.0` tag only when the owner has approved publication.

## Publication

Publishing is intentionally excluded from automated project setup. When the owner explicitly approves the release, run the following from `packages/strategy_forge` and review the prompt before confirming:

```sh
dart pub publish
```

The official requirements and behavior are documented in [Publishing packages](https://dart.dev/tools/pub/publishing), [The pubspec file](https://dart.dev/tools/pub/pubspec), and [Package layout conventions](https://dart.dev/tools/pub/package-layout).
