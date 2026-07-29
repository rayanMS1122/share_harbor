# Changelog

## 0.1.0

- **Initial Stable Release** by **Rayan** (`rayanMS1122`).
- Native-first file spooling for inbound shares on Android and iOS.
- Transactional `claim()`, `ack()`, and `release()` protocol for durable at-least-once delivery.
- Comprehensive fault tolerance: crash-safe recovery, file lock synchronization, and storage quota management.
- Diagnostic CLI doctor (`dart run share_harbor:doctor`).
- Material 3 inbox showcase example app (`example/lib/main.dart`).
