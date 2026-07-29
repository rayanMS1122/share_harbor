import 'package:meta/meta.dart';
import 'share_item.dart';

/// Possible states of a share delivery in the file spool.
enum ShareDeliveryState {
  receiving,
  ready,
  claimed,
  acknowledged,
  cleaned,
  rejected,
  failed,
  quarantined,
  unknown,
}

/// Represents an inbound share delivery containing one or more items.
@immutable
class ShareDelivery {
  /// Unique delivery ID.
  final String deliveryId;

  /// UTC timestamp when received.
  final DateTime receivedAtUtc;

  /// Platform source ('android' or 'ios').
  final String platform;

  /// Current delivery state.
  final ShareDeliveryState state;

  /// Processing attempt count.
  final int attempt;

  /// Items included in this delivery.
  final List<ShareItem> items;

  /// Shared text content if present.
  final String? text;

  /// Shared subject if present.
  final String? subject;

  /// Shared source package or bundle ID if available.
  final String? source;

  /// Creates a [ShareDelivery].
  const ShareDelivery({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareDelivery &&
          runtimeType == other.runtimeType &&
          deliveryId == other.deliveryId &&
          receivedAtUtc == other.receivedAtUtc &&
          platform == other.platform &&
          state == other.state &&
          attempt == other.attempt &&
          text == other.text &&
          subject == other.subject &&
          source == other.source;

  @override
  int get hashCode =>
      deliveryId.hashCode ^
      receivedAtUtc.hashCode ^
      platform.hashCode ^
      state.hashCode ^
      attempt.hashCode;
}
