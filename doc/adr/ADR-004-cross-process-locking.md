# ADR-004: Cross-Process Kernel Locking

## Status
Accepted

## Context
Multiple processes (e.g. iOS Share Extension vs Flutter App Runner, or multiple engine instances) access the shared storage concurrently. In-memory locks (Dart Mutex, Swift Serial Queue, Kotlin Synchronized) do not protect against inter-process data corruption.

## Decision
1. **iOS**: Explicit POSIX File Locking (`fcntl` with `F_SETLK`/`F_SETLKW` or `flock`) or `NSFileCoordinator` operating on `locks/spool.lock` inside the shared App Group directory.
2. **Android**: `FileChannel.lock()` operating on `locks/spool.lock` inside the application shared internal storage directory.
3. Lock acquire timeouts are configured (default: 5 seconds) to prevent infinite deadlocks.
