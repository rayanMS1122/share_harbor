import 'package:meta/meta.dart';

@immutable
class ShareHarborConfig {
  final Duration leaseDuration;
  final Duration retention;
  final int? maxItemSizeBytes;
  final int? maxDeliverySizeBytes;
  final int? maxInboxSizeBytes;

  const ShareHarborConfig({
    this.leaseDuration = const Duration(minutes: 5),
    this.retention = const Duration(days: 7),
    this.maxItemSizeBytes,
    this.maxDeliverySizeBytes,
    this.maxInboxSizeBytes,
  });
}
