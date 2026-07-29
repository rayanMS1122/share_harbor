import 'package:meta/meta.dart';
import 'share_delivery.dart';

/// Represents an active claim/lease on a specific delivery.
@immutable
class ShareClaim {
  /// Unique identifier for this claim instance.
  final String claimId;

  /// Associated delivery ID.
  final String deliveryId;

  /// Full delivery object associated with this claim.
  final ShareDelivery delivery;

  /// UTC timestamp when the claim was acquired.
  final DateTime claimedAtUtc;

  /// UTC timestamp when the lease expires.
  final DateTime expiresAtUtc;

  /// Creates a new [ShareClaim] instance.
  const ShareClaim({
    required this.claimId,
    required this.deliveryId,
    required this.delivery,
    required this.claimedAtUtc,
    required this.expiresAtUtc,
  });

  /// Returns true if the claim lease has expired.
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareClaim &&
          runtimeType == other.runtimeType &&
          claimId == other.claimId &&
          deliveryId == other.deliveryId;

  @override
  int get hashCode => claimId.hashCode ^ deliveryId.hashCode;
}
