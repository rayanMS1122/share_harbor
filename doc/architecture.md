# ShareHarbor Architecture & Core Design

```text
iOS Extension ──────┐
                    ├─ Swift Native Core ───── File Spool Storage (`ready.marker`, `ack.marker`, Locks)
Flutter / Pigeon ───┘

Android Activity ───┐
                    ├─ Kotlin Native Core ──── File Spool Storage (`ready.marker`, `ack.marker`, Locks)
Flutter / Pigeon ───┘
```

## Key Principles
1. **Sole Native Storage Ownership**: Native code (Swift/Kotlin) strictly owns file spool operations. Dart does not mutate spool files directly.
2. **Pigeon IPC Boundary**: Platform channels only transfer typed metadata and commands. Binary streams stay on disk.
3. **Atomic Spool Protocol**: Uses `.partial` streaming, atomic rename to `.payload`, `manifest.tmp` -> `manifest.json` replacement, and `ready.marker` creation.
4. **ACK Precedence**: `ack.marker` creation precedes payload deletion to prevent re-delivery if process termination happens mid-cleanup.
