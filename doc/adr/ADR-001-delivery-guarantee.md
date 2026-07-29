# ADR-001: Durable At-Least-Once Delivery Semantics

## Status
Accepted

## Context
Standard Flutter share plugins rely on volatile in-memory stream callbacks or single-read initial share getters (`getInitialShare()`). If an application is not running, crashes during processing, or is killed by the OS before Dart code handles the incoming share, the shared payload is silently lost.

## Decision
`share_harbor` implements a **durable at-least-once delivery contract after successful commit**.

1. **Pre-Commit Boundary**: Before `ready.marker` is created in the file spool, the OS process (iOS Extension or Android Activity) is responsible for handling early termination or errors. If pre-commit fails or is killed, no delivery is created.
2. **Post-Commit Guarantee**: Once `ready.marker` is written to disk, the delivery is guaranteed to persist across app crashes, system reboots, and process kills until explicit application acknowledgement (`ack()`).
3. **ACK Precedence**: Acknowledgement writes an `ack.marker` before removing payload files. Once `ack.marker` is present, the item is permanently acknowledged and will never be re-delivered, even if process termination occurs mid-cleanup.
4. **Idempotency**: Clients use the stable `deliveryId` to enforce idempotent processing in business logic.
