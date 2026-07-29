# Changelog

## 0.1.0-beta.1 (2026-07-29)

- Initial release of `share_harbor`.
- Durable at-least-once delivery contract after commit.
- Sole native storage ownership for Swift (`ShareHarborCore`) and Kotlin (`ShareHarborCore`).
- Atomic file spooling with `ready.marker` and `ack.marker` protocol.
- Visible Android import activity with progress UI and cancellation option.
- iOS App Extension safe file ingestion pipeline via `NSItemProviderIngestor`.
- Cross-process POSIX and `FileChannel.lock()` file locking.
- Diagnostic CLI doctor (`dart run share_harbor:doctor`).
