import 'dart:async';
import '../model/share_delivery.dart';
import '../model/share_claim.dart';
import '../model/share_item.dart';
import '../model/share_health.dart';
import '../model/share_cleanup_result.dart';

abstract interface class ShareHarborApi {
  /// Returns all current pending (ready) deliveries in the inbox.
  Future<List<ShareDelivery>> pending();

  /// Claims a specific delivery by ID, locking it with a lease.
  Future<ShareClaim> claim(String deliveryId);

  /// Claims the next available pending delivery, if any.
  Future<ShareClaim?> claimNext();

  /// Acknowledges successful processing of a claimed delivery and cleans up disk files.
  Future<void> ack(ShareClaim claim);

  /// Releases a claimed delivery back to ready state (e.g. on soft error).
  Future<void> release(ShareClaim claim, {String? reason});

  /// Retries a failed or quarantined delivery.
  Future<void> retry(String deliveryId);

  /// Inspects inbox health and returns diagnostic statistics.
  Future<ShareHarborHealth> inspect();

  /// Executes retention cleanup of expired or old deliveries.
  Future<ShareCleanupResult> cleanup();

  /// Gets local filesystem absolute path for reading payload items.
  Future<String> getPayloadPath(ShareItem item, {required String deliveryId});

  /// Event stream notifying when inbox state changes natively.
  Stream<void> get changes;
}
