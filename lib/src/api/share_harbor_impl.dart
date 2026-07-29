import 'dart:async';
import 'package:flutter/services.dart';
import '../errors/share_harbor_exception.dart';
import '../model/share_cleanup_result.dart';
import '../model/share_config.dart';
import '../model/share_delivery.dart';
import '../model/share_claim.dart';
import '../model/share_health.dart';
import '../model/share_item.dart';
import '../platform/generated/share_harbor_api.g.dart';
import 'share_harbor_api_interface.dart';

class ShareHarborImpl implements ShareHarborApi, ShareHarborFlutterApi {
  final ShareHarborHostApi _hostApi;
  final ShareHarborConfig config;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  ShareHarborImpl({
    ShareHarborHostApi? hostApi,
    this.config = const ShareHarborConfig(),
  }) : _hostApi = hostApi ?? ShareHarborHostApi() {
    ShareHarborFlutterApi.setUp(this);
  }

  @override
  Stream<void> get changes => _changesController.stream;

  @override
  void onInboxChanged() {
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
  }

  @override
  Future<List<ShareDelivery>> pending() async {
    try {
      final nativeDeliveries = await _hostApi.getPendingDeliveries();
      return nativeDeliveries.map(_mapDelivery).toList();
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<ShareClaim> claim(String deliveryId) async {
    try {
      final nativeClaim = await _hostApi.claimDelivery(
        deliveryId,
        config.leaseDuration.inSeconds,
      );
      return _mapClaim(nativeClaim);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<ShareClaim?> claimNext() async {
    try {
      final nativeClaim = await _hostApi.claimNextDelivery(
        config.leaseDuration.inSeconds,
      );
      return nativeClaim != null ? _mapClaim(nativeClaim) : null;
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> ack(ShareClaim claim) async {
    try {
      await _hostApi.acknowledgeClaim(claim.claimId, claim.deliveryId);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> release(ShareClaim claim, {String? reason}) async {
    try {
      await _hostApi.releaseClaim(claim.claimId, claim.deliveryId, reason);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> retry(String deliveryId) async {
    try {
      await _hostApi.retryDelivery(deliveryId);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<ShareHarborHealth> inspect() async {
    try {
      final nativeHealth = await _hostApi.inspectInbox();
      return ShareHarborHealth(
        pendingCount: nativeHealth.pendingCount,
        claimedCount: nativeHealth.claimedCount,
        quarantinedCount: nativeHealth.quarantinedCount,
        totalStorageBytes: nativeHealth.totalStorageBytes,
        issues: nativeHealth.issues.whereType<String>().toList(),
      );
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<ShareCleanupResult> cleanup() async {
    try {
      final nativeCleanup = await _hostApi.cleanupInbox(
        config.retention.inSeconds,
      );
      return ShareCleanupResult(
        deletedDeliveriesCount: nativeCleanup.deletedDeliveriesCount,
        reclaimedBytes: nativeCleanup.reclaimedBytes,
      );
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<String> getPayloadPath(ShareItem item,
      {required String deliveryId}) async {
    try {
      return await _hostApi.getPayloadPath(deliveryId, item.itemId);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  ShareDelivery _mapDelivery(NativeDelivery n) {
    return ShareDelivery(
      deliveryId: n.deliveryId,
      receivedAtUtc: DateTime.parse(n.receivedAtUtc),
      platform: n.platform,
      state: _parseDeliveryState(n.state),
      attempt: n.attempt,
      items: n.items.whereType<NativeItem>().map(_mapItem).toList(),
      text: n.text,
      subject: n.subject,
      source: n.source,
    );
  }

  ShareItem _mapItem(NativeItem i) {
    return ShareItem(
      itemId: i.itemId,
      kind: _parseItemKind(i.kind),
      originalName: i.originalName,
      internalName: i.internalName,
      declaredMimeType: i.declaredMimeType,
      resolvedMimeType: i.resolvedMimeType,
      byteLength: i.byteLength,
    );
  }

  ShareClaim _mapClaim(NativeClaim c) {
    return ShareClaim(
      claimId: c.claimId,
      deliveryId: c.deliveryId,
      delivery: _mapDelivery(c.delivery),
      claimedAtUtc: DateTime.parse(c.claimedAtUtc),
      expiresAtUtc: DateTime.parse(c.expiresAtUtc),
    );
  }

  ShareDeliveryState _parseDeliveryState(String s) {
    switch (s) {
      case 'receiving':
        return ShareDeliveryState.receiving;
      case 'ready':
        return ShareDeliveryState.ready;
      case 'claimed':
        return ShareDeliveryState.claimed;
      case 'acknowledged':
        return ShareDeliveryState.acknowledged;
      case 'cleaned':
        return ShareDeliveryState.cleaned;
      case 'rejected':
        return ShareDeliveryState.rejected;
      case 'failed':
        return ShareDeliveryState.failed;
      case 'quarantined':
        return ShareDeliveryState.quarantined;
      default:
        return ShareDeliveryState.unknown;
    }
  }

  ShareItemKind _parseItemKind(String k) {
    switch (k) {
      case 'text':
        return ShareItemKind.text;
      case 'url':
        return ShareItemKind.url;
      case 'html':
        return ShareItemKind.html;
      case 'image':
        return ShareItemKind.image;
      case 'video':
        return ShareItemKind.video;
      case 'file':
        return ShareItemKind.file;
      default:
        return ShareItemKind.unknown;
    }
  }

  ShareHarborException _mapException(PlatformException e) {
    ShareHarborErrorCode code;
    switch (e.code) {
      case 'configurationInvalid':
        code = ShareHarborErrorCode.configurationInvalid;
        break;
      case 'appGroupUnavailable':
        code = ShareHarborErrorCode.appGroupUnavailable;
        break;
      case 'unsupportedType':
        code = ShareHarborErrorCode.unsupportedType;
        break;
      case 'unsupportedSchema':
        code = ShareHarborErrorCode.unsupportedSchema;
        break;
      case 'sourcePermissionDenied':
        code = ShareHarborErrorCode.sourcePermissionDenied;
        break;
      case 'sourceUnavailable':
        code = ShareHarborErrorCode.sourceUnavailable;
        break;
      case 'itemTooLarge':
        code = ShareHarborErrorCode.itemTooLarge;
        break;
      case 'deliveryTooLarge':
        code = ShareHarborErrorCode.deliveryTooLarge;
        break;
      case 'tooManyItems':
        code = ShareHarborErrorCode.tooManyItems;
        break;
      case 'inboxQuotaExceeded':
        code = ShareHarborErrorCode.inboxQuotaExceeded;
        break;
      case 'cancelled':
        code = ShareHarborErrorCode.cancelled;
        break;
      case 'ioFailure':
        code = ShareHarborErrorCode.ioFailure;
        break;
      case 'corruptManifest':
        code = ShareHarborErrorCode.corruptManifest;
        break;
      case 'unsafeMetadata':
        code = ShareHarborErrorCode.unsafeMetadata;
        break;
      case 'lockTimeout':
        code = ShareHarborErrorCode.lockTimeout;
        break;
      case 'deliveryNotFound':
        code = ShareHarborErrorCode.deliveryNotFound;
        break;
      case 'claimConflict':
        code = ShareHarborErrorCode.claimConflict;
        break;
      case 'claimExpired':
        code = ShareHarborErrorCode.claimExpired;
        break;
      case 'alreadyAcknowledged':
        code = ShareHarborErrorCode.alreadyAcknowledged;
        break;
      case 'platformFailure':
        code = ShareHarborErrorCode.platformFailure;
        break;
      default:
        code = ShareHarborErrorCode.unknown;
    }
    return ShareHarborException(
      code: code,
      message: e.message ?? 'Unknown platform error',
      details: e.details,
    );
  }
}
