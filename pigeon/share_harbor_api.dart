import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/platform/generated/share_harbor_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/dev/rayan/share_harbor/generated/ShareHarborApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'dev.rayan.share_harbor.generated',
    ),
    swiftOut: 'ios/Classes/Generated/ShareHarborApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
class NativeItem {
  final String itemId;
  final String kind;
  final String? originalName;
  final String internalName;
  final String? declaredMimeType;
  final String? resolvedMimeType;
  final int byteLength;

  NativeItem({
    required this.itemId,
    required this.kind,
    this.originalName,
    required this.internalName,
    this.declaredMimeType,
    this.resolvedMimeType,
    required this.byteLength,
  });
}

class NativeDelivery {
  final String deliveryId;
  final String receivedAtUtc;
  final String platform;
  final String state;
  final int attempt;
  final List<NativeItem?> items;
  final String? text;
  final String? subject;
  final String? source;

  NativeDelivery({
    required this.deliveryId,
    required this.receivedAtUtc,
    required this.platform,
    required this.state,
    required this.attempt,
    required this.items,
    this.text,
    this.subject,
    this.source,
  });
}

class NativeClaim {
  final String claimId;
  final String deliveryId;
  final NativeDelivery delivery;
  final String claimedAtUtc;
  final String expiresAtUtc;

  NativeClaim({
    required this.claimId,
    required this.deliveryId,
    required this.delivery,
    required this.claimedAtUtc,
    required this.expiresAtUtc,
  });
}

class NativeHealth {
  final int pendingCount;
  final int claimedCount;
  final int quarantinedCount;
  final int totalStorageBytes;
  final List<String?> issues;

  NativeHealth({
    required this.pendingCount,
    required this.claimedCount,
    required this.quarantinedCount,
    required this.totalStorageBytes,
    required this.issues,
  });
}

class NativeCleanupResult {
  final int deletedDeliveriesCount;
  final int reclaimedBytes;

  NativeCleanupResult({
    required this.deletedDeliveriesCount,
    required this.reclaimedBytes,
  });
}

@HostApi()
abstract class ShareHarborHostApi {
  List<NativeDelivery> getPendingDeliveries();
  NativeClaim claimDelivery(String deliveryId, int leaseDurationSeconds);
  NativeClaim? claimNextDelivery(int leaseDurationSeconds);
  void acknowledgeClaim(String claimId, String deliveryId);
  void releaseClaim(String claimId, String deliveryId, String? reason);
  void retryDelivery(String deliveryId);
  NativeHealth inspectInbox();
  NativeCleanupResult cleanupInbox(int maxAgeSeconds);
  String getPayloadPath(String deliveryId, String itemId);
}

@FlutterApi()
abstract class ShareHarborFlutterApi {
  void onInboxChanged();
}
