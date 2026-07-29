# share_harbor

A durable inbound share inbox for Flutter on Android and iOS with transactional delivery guarantees.

[![pub package](https://img.shields.io/pub/v/share_harbor.svg)](https://pub.dev/packages/share_harbor)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)

![ShareHarbor Demo](untitled.gif)

`share_harbor` receives text, URLs, images, videos, and files shared from other mobile apps via the native Share Sheet. Shared content is safely committed to a durable file spool **before** the Flutter engine processes it.

---

## Author & Copyright

Developed by **Rayan** (`rayanMS1122`).  
Licensed under the **BSD-3-Clause License** (Copyright (c) 2026, Rayan).

---

## Guaranteed Delivery Contract

> **Durable at-least-once delivery after successful commit.**

- **Pre-Commit**: The operating system extension or activity handles pre-commit safety.
- **Post-Commit**: Once `ready.marker` is created on disk, shared content persists across process kills, system crashes, and reboots until explicit application acknowledgement (`ack()`).
- **ACK Marker Precedence**: Acknowledgement writes an `ack.marker` atomically before payload removal. An acknowledged delivery is never re-delivered even if a crash occurs mid-cleanup.

---

## Supported Platforms

- **Android**: `minSdk 23` (Android 6.0+)
- **iOS**: iOS 13.0+

---

## Installation

Add `share_harbor` to your `pubspec.yaml`:

```yaml
dependencies:
  share_harbor: ^0.1.0-beta.1
```

---

## Android Setup

Register `ShareHarborReceiverActivity` in `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="dev.rayan.share_harbor.ShareHarborReceiverActivity"
    android:exported="true"
    android:theme="@android:style/Theme.Translucent.NoTitleBar">
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="*/*" />
    </intent-filter>
    <intent-filter>
        <action android:name="android.intent.action.SEND_MULTIPLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="*/*" />
    </intent-filter>
</activity>
```

---

## iOS Setup

1. Add a Share Extension target in Xcode.
2. Configure App Group `group.yourdomain.share_harbor` for both Runner and Extension targets.
3. Use `NSItemProviderIngestor` in `ShareViewController.swift`:

```swift
import ShareHarborCore

class ShareViewController: SLComposeServiceViewController {
    private let appGroupId = "group.yourdomain.share_harbor"

    override func didSelectPost() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem],
              let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        NSItemProviderIngestor.ingestItems(extensionItems: items, containerUrl: groupUrl) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
```

---

## Quick Start Example

```dart
import 'package:flutter/material.dart';
import 'package:share_harbor/share_harbor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final harbor = await ShareHarbor.open();

  // Listen for native inbox changes
  harbor.changes.listen((_) async {
    final pending = await harbor.pending();
    for (final delivery in pending) {
      final claim = await harbor.claim(delivery.deliveryId);
      try {
        // Process getted content safely
        print('Received shared items: ${claim.delivery.items.length}');
        await harbor.ack(claim);
      } catch (error) {
        await harbor.release(claim, reason: error.toString());
      }
    }
  });
}
```

---

## Complete Example Project

A complete production-ready example Flutter app with inbox UI, manual refresh, claim handling, and storage cleanup is included in the `example/` directory.

To see the full example app code, inspect [`example/lib/main.dart`](example/lib/main.dart) or run:

```bash
cd example
flutter run
```

---

## Diagnostics Doctor

Run the read-only diagnostic tool to verify your native setup:

```bash
dart run share_harbor:doctor
```