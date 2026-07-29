# ADR-002: Native Sole Ownership of Storage Mutations

## Status
Accepted

## Context
Having Dart, Swift, and Kotlin independently mutate shared disk files risks state divergence, race conditions, and incomplete lock implementations across platforms.

## Decision
Swift (`ShareHarborCore` on iOS) and Kotlin (`ShareHarborCore` on Android) strictly own all storage mutations on their respective platforms.

1. **Native Core Monopoly**: Native code executes all `commit`, `claim`, `ack`, `release`, `retry`, `recovery`, `lock`, and `cleanup` operations directly against the file spool.
2. **Dart Boundary**: Dart code never touches disk spool files directly. Dart interacts with the native storage engine exclusively via typed Pigeon IPC methods (`pending`, `claim`, `ack`, etc.).
3. **Payload Streaming**: Payloads stay in disk storage. Binaries are never sent through Pigeon or platform channels.
