# Contributing to ShareHarbor

We welcome contributions to `share_harbor`! Please follow these guidelines:

## Code Quality Standards
- Ensure all Dart code is formatted with `dart format .`.
- Ensure analyzer passes cleanly: `flutter analyze`.
- Ensure all tests pass: `flutter test`.
- Verify pigeon code generation if updating IPC interfaces: `dart run pigeon --input pigeon/share_harbor_api.dart`.
- Run doctor: `dart run share_harbor:doctor`.
