import 'package:meta/meta.dart';

@immutable
class ShareHarborHealth {
  final int pendingCount;
  final int claimedCount;
  final int quarantinedCount;
  final int totalStorageBytes;
  final List<String> issues;

  const ShareHarborHealth({
    required this.pendingCount,
    required this.claimedCount,
    required this.quarantinedCount,
    required this.totalStorageBytes,
    required this.issues,
  });

  bool get isHealthy => issues.isEmpty;
}
