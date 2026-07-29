import 'package:flutter_test/flutter_test.dart';
import 'package:share_harbor/share_harbor.dart';

void main() {
  group('File Spool State Machine & Lease Unit Tests', () {
    test('ShareDeliveryState transition validations', () {
      expect(ShareDeliveryState.ready.name, equals('ready'));
      expect(ShareDeliveryState.claimed.name, equals('claimed'));
      expect(ShareDeliveryState.acknowledged.name, equals('acknowledged'));
      expect(ShareDeliveryState.quarantined.name, equals('quarantined'));
    });

    test('ShareClaim expiration check', () {
      final now = DateTime.now().toUtc();
      final validClaim = ShareClaim(
        claimId: 'c1',
        deliveryId: 'd1',
        delivery: ShareDelivery(
          deliveryId: 'd1',
          receivedAtUtc: now,
          platform: 'android',
          state: ShareDeliveryState.claimed,
          attempt: 0,
          items: [],
        ),
        claimedAtUtc: now,
        expiresAtUtc: now.add(const Duration(minutes: 5)),
      );

      final expiredClaim = ShareClaim(
        claimId: 'c2',
        deliveryId: 'd2',
        delivery: ShareDelivery(
          deliveryId: 'd2',
          receivedAtUtc: now.subtract(const Duration(hours: 1)),
          platform: 'ios',
          state: ShareDeliveryState.claimed,
          attempt: 1,
          items: [],
        ),
        claimedAtUtc: now.subtract(const Duration(hours: 1)),
        expiresAtUtc: now.subtract(const Duration(minutes: 10)),
      );

      expect(validClaim.isExpired, isFalse);
      expect(expiredClaim.isExpired, isTrue);
    });

    test('ShareItem equality and hash code', () {
      const item1 = ShareItem(
        itemId: 'id-1',
        kind: ShareItemKind.image,
        internalName: 'id-1.payload',
        byteLength: 1024,
      );
      const item2 = ShareItem(
        itemId: 'id-1',
        kind: ShareItemKind.image,
        internalName: 'id-1.payload',
        byteLength: 1024,
      );
      const item3 = ShareItem(
        itemId: 'id-2',
        kind: ShareItemKind.video,
        internalName: 'id-2.payload',
        byteLength: 2048,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
      expect(item1, isNot(equals(item3)));
    });
  });
}
