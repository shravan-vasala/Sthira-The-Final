# Sthira

Welcome to the Sthira project repository. This codebase provides a clean, private, local-first functional tracking interface. 

## Requirements
- Flutter with a Dart SDK compatible with `^3.12.2` (see `pubspec.yaml`)

## Repository Initialization
Upon first clone, execute the following to retrieve the verified functional baseline:
```bash
flutter pub get
```

## Running Local Tests
A functional Isar test database core is required for testing. 
On Windows, you must download the pre-compiled `isar.dll`:
```bash
dart run test/helpers/download_isar.dart
```
All maintained tests and test utilities are grouped under [`test/`](test/README.md). Following setup, run the Flutter suite with:
```bash
flutter test test
```

## Disclaimer
Sthira utilizes `health` and `screentime` permission tracking on native targets. For iOS execution or distribution, ensure the respective usage strings are properly mapped in your `Info.plist`.
