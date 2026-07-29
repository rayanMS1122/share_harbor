import 'package:meta/meta.dart';

@immutable
class ShareCleanupResult {
  final int deletedDeliveriesCount;
  final int reclaimedBytes;

  const ShareCleanupResult({
    required this.deletedDeliveriesCount,
    required this.reclaimedBytes,
  });
}
