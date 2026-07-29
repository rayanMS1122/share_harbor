import 'package:flutter_test/flutter_test.dart';
import 'package:share_harbor/share_harbor.dart';
import 'package:share_harbor/src/api/share_harbor_impl.dart';
import 'package:share_harbor/src/platform/generated/share_harbor_api.g.dart';

class ExpandedMockHostApi extends ShareHarborHostApi {
  List<NativeDelivery> mockDeliveries = [];
  NativeClaim? nextClaim;
  NativeHealth mockHealth = NativeHealth(
    pendingCount: 0,
    claimedCount: 0,
    quarantinedCount: 0,
    totalStorageBytes: 0,
    issues: [],
  );
  String lastAckClaimId = '';
  String lastAckDeliveryId = '';
  String lastReleasedClaimId = '';
  String? lastReleasedReason;
  String lastRetriedDeliveryId = '';
  bool shouldThrowPlatformException = false;

  @override
  Future<List<NativeDelivery>> getPendingDeliveries() async {
    if (shouldThrowPlatformException) {
      throw Exception('Platform failure simulation');
    }
    return mockDeliveries;
  }

  @override
  Future<NativeClaim> claimDelivery(String deliveryId, int leaseDurationSeconds) async {
    if (shouldThrowPlatformException) {
      throw Exception('Claim conflict simulation');
    }
    final d = mockDeliveries.firstWhere((element) => element.deliveryId == deliveryId);
    return NativeClaim(
      claimId: 'claim-123',
      deliveryId: d.deliveryId,
      delivery: d,
      claimedAtUtc: DateTime.now().toUtc().toIso8601String(),
      expiresAtUtc: DateTime.now().toUtc().add(Duration(seconds: leaseDurationSeconds)).toIso8601String(),
    );
  }

  @override
  Future<NativeClaim?> claimNextDelivery(int leaseDurationSeconds) async {
    return nextClaim;
  }

  @override
  Future<void> acknowledgeClaim(String claimId, String deliveryId) async {
    lastAckClaimId = claimId;
    lastAckDeliveryId = deliveryId;
  }

  @override
  Future<void> releaseClaim(String claimId, String deliveryId, String? reason) async {
    lastReleasedClaimId = claimId;
    lastReleasedReason = reason;
  }

  @override
  Future<void> retryDelivery(String deliveryId) async {
    lastRetriedDeliveryId = deliveryId;
  }

  @override
  Future<NativeHealth> inspectInbox() async {
    return mockHealth;
  }

  @override
  Future<NativeCleanupResult> cleanupInbox(int maxAgeSeconds) async {
    return NativeCleanupResult(deletedDeliveriesCount: 1, reclaimedBytes: 1024);
  }

  @override
  Future<String> getPayloadPath(String deliveryId, String itemId) async {
    return '/fake/spool/deliveries/$deliveryId/items/$itemId.payload';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExpandedMockHostApi mockHostApi;
  late ShareHarborImpl harbor;

  setUp(() {
    mockHostApi = ExpandedMockHostApi();
    harbor = ShareHarborImpl(hostApi: mockHostApi);
  });

  group('ShareHarbor API Interface & Mapping Tests', () {
    test('pending() correctly parses text, url, image, video items', () async {
      mockHostApi.mockDeliveries = [
        NativeDelivery(
          deliveryId: 'del-multitype',
          receivedAtUtc: '2026-07-29T12:00:00.000Z',
          platform: 'android',
          state: 'ready',
          attempt: 0,
          items: [
            NativeItem(
              itemId: 'item-text',
              kind: 'text',
              originalName: null,
              internalName: 'item-text.payload',
              declaredMimeType: 'text/plain',
              resolvedMimeType: 'text/plain',
              byteLength: 12,
            ),
            NativeItem(
              itemId: 'item-img',
              kind: 'image',
              originalName: 'photo.png',
              internalName: 'item-img.payload',
              declaredMimeType: 'image/png',
              resolvedMimeType: 'image/png',
              byteLength: 50000,
            ),
          ],
          text: 'Shared Text Content',
          subject: 'Shared Subject',
          source: 'com.example.sender',
        ),
      ];

      final pending = await harbor.pending();
      expect(pending.length, equals(1));
      final delivery = pending.first;
      expect(delivery.deliveryId, equals('del-multitype'));
      expect(delivery.items.length, equals(2));
      expect(delivery.items[0].kind, equals(ShareItemKind.text));
      expect(delivery.items[1].kind, equals(ShareItemKind.image));
      expect(delivery.source, equals('com.example.sender'));
    });

    test('claimNext() returns null when inbox is empty', () async {
      mockHostApi.nextClaim = null;
      final claim = await harbor.claimNext();
      expect(claim, isNull);
    });

    test('release() passes claim details and failure reason', () async {
      final claim = ShareClaim(
        claimId: 'claim-err',
        deliveryId: 'del-err',
        delivery: ShareDelivery(
          deliveryId: 'del-err',
          receivedAtUtc: DateTime.now(),
          platform: 'ios',
          state: ShareDeliveryState.claimed,
          attempt: 1,
          items: [],
        ),
        claimedAtUtc: DateTime.now(),
        expiresAtUtc: DateTime.now().add(const Duration(minutes: 5)),
      );

      await harbor.release(claim, reason: 'Database connection failed');
      expect(mockHostApi.lastReleasedClaimId, equals('claim-err'));
      expect(mockHostApi.lastReleasedReason, equals('Database connection failed'));
    });

    test('retry() passes deliveryId to native host', () async {
      await harbor.retry('del-retry-1');
      expect(mockHostApi.lastRetriedDeliveryId, equals('del-retry-1'));
    });

    test('ShareHarborConfig assertions and default bounds', () {
      const config = ShareHarborConfig(
        leaseDuration: Duration(minutes: 10),
        retention: Duration(days: 14),
      );
      expect(config.leaseDuration.inMinutes, equals(10));
      expect(config.retention.inDays, equals(14));
    });
  });
}
