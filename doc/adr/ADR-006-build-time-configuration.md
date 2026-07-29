# ADR-006: Native Build-Time Configuration

## Status
Accepted

## Context
Configuring shared settings (App Group ID, byte quotas, supported categories, UX behavior) exclusively in Dart code fails when the main Flutter app has never been launched or is currently terminated when a share intent arrives.

## Decision
1. **iOS**: Native configuration via `ShareHarborConfig.plist` or Swift defaults inside `ShareHarborCore`.
2. **Android**: Native configuration via `res/xml/share_harbor_config.xml` or Manifest metadata.
3. Runtime Dart configuration can further restrict parameters (e.g. lease duration, sorting, retention) but cannot override native security bounds.
4. `dart run share_harbor:doctor` validates consistency between native build configuration and package expectations.
