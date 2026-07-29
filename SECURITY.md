# Security Policy

## Security Model
`share_harbor` treats all incoming share payload contents, names, and headers as untrusted.

1. **Path Traversal Protection**: Payloads are stored strictly using internally generated random UUID file names. Original file names are retained only as display metadata in `manifest.json`.
2. **Path Containment Verification**: All reader and payload access APIs enforce path containment checks.
3. **Log Redaction**: Sensitve shared text content and full external URIs are never printed in production logs.
4. **App Sandbox Boundary**: Data stored in App Group containers or app internal files directories rely on OS kernel isolation.
