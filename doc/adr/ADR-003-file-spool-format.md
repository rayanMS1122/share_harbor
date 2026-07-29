# ADR-003: Append-Oriented File Spool Format & Atomic Commit Protocol

## Status
Accepted

## Context
A centralized mutable index file (e.g. single JSON array) is a single point of failure under unexpected process termination.

## Decision
Use an append-oriented per-delivery folder structure:

```text
share_harbor/v1/
├── deliveries/
│   └── <delivery-id>/
│       ├── items/
│       │   ├── <item-id>.payload
│       │   └── ...
│       ├── manifest.json
│       ├── ready.marker
│       ├── claim.json
│       └── ack.marker
├── failed/
├── quarantine/
└── locks/
    └── spool.lock
```

### Protocol Steps
1. Write payload streams to `<item-id>.partial`. Check byte quotas during streaming.
2. Flush/sync payload files to disk.
3. Rename `<item-id>.partial` -> `<item-id>.payload` atomically.
4. Write `manifest.tmp` containing metadata JSON.
5. Replace `manifest.tmp` -> `manifest.json` atomically.
6. Create `ready.marker` atomically. Only deliveries containing `ready.marker` are visible to readers.
7. To acknowledge, write `ack.marker` atomically before deleting directory contents.
