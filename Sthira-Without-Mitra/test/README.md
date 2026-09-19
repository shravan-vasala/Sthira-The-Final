# Tests

All maintained app tests, fixtures and test utilities live under this one `test/` root. Subfolders keep related tests together. A test **case** is an individual check inside a file; hundreds of passing cases do not mean hundreds of files.

Latest verified checkpoint: **926 Flutter cases passed, one existing native-contract placeholder skipped**, in 133 test files. See [verification and changes](../docs/physique-pictures-review.md).

## Flutter suite

Run from the project root:

```sh
flutter pub get
dart run test/helpers/download_isar.dart
flutter test test
```

The Isar setup downloads the native test library when it is missing; Windows requires `isar.dll` in the project working directory. Individual folders or files can be passed to `flutter test`.

| Folder | Coverage |
|---|---|
| `models/`, `utils/` | Data contracts and calculations |
| `providers/`, `repositories/`, `services/` | State, persistence, account ownership and backend boundaries |
| `screens/`, `widgets/`, `share/`, `social/` | User flows, layout, accessibility and sharing |
| `fixtures/`, `helpers/` | Shared data and setup |
| `native/` | Android resource and widget compatibility checks |
| `firestore/` | Local Firestore security-rule emulator tests |
| `benchmark/` | Opt-in live meal-scan benchmark and its methodology |
| `manual/` | Diagnostic utilities that are not automated assertions |
| `reports/legacy/` | Preserved historical output moved from the project root; not current test results |

## Android resource check

```sh
python test/native/check_android_widget_resources.py
```

This checks local references, supported RemoteViews classes, view IDs and theme inheritance. It does not compile an APK or validate launcher/device rendering.

## Firestore rules

Follow [firestore/README.md](firestore/README.md). Those tests use a local demo emulator and run separately from Flutter. Do not count them as part of Flutter's passing total.

## Live AI benchmark

See [benchmark/BASELINE.md](benchmark/BASELINE.md) and [fixtures/meal_scan/README.md](fixtures/meal_scan/README.md). The benchmark requires an explicit opt-in and your configured API key; it can make paid external requests. It is not part of the ordinary offline Flutter suite.

Temporary generated renders, development probes and SDK/build output under `build/` are not maintained tests. Current verification is recorded in the relevant implementation report under `docs/`; historical report files here are retained only for reference.
