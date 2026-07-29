/// A durable inbound share inbox for Flutter on Android and iOS.
///
/// Shared content is committed natively to a durable file spool before Flutter engine processes it.
library share_harbor;

export 'src/api/share_harbor_api_interface.dart';
export 'src/errors/share_harbor_exception.dart';
export 'src/model/share_cleanup_result.dart';
export 'src/model/share_config.dart';
export 'src/model/share_delivery.dart';
export 'src/model/share_claim.dart';
export 'src/model/share_health.dart';
export 'src/model/share_item.dart';

import 'src/api/share_harbor_api_interface.dart';
import 'src/api/share_harbor_impl.dart';
import 'src/model/share_config.dart';

/// Entry point for accessing the ShareHarbor inbound share inbox.
abstract final class ShareHarbor {
  /// Opens a ShareHarbor instance with optional [config].
  static Future<ShareHarborApi> open({
    ShareHarborConfig config = const ShareHarborConfig(),
  }) async {
    return ShareHarborImpl(config: config);
  }
}
