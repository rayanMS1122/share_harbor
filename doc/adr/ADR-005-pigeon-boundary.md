# ADR-005: Pigeon IPC Boundary

## Status
Accepted

## Context
Platform Channels without strict type generation can lead to runtime deserialization bugs and fragile string key mapping. Sending large binaries across Platform Channels causes UI thread jank and RAM spikes.

## Decision
1. Pigeon generates strictly typed Dart, Kotlin, and Swift code from `pigeon/share_harbor_api.dart`.
2. Generated files are committed directly into the repository.
3. Pigeon-generated types are kept strictly internal to `share_harbor` and are NOT exported in the public Dart API.
4. Large payload binaries stay strictly on disk and are accessed via stream APIs or local file references.
