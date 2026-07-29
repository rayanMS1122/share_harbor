import Foundation

public class NativeStorageCore {
    public let spool: FileSpool

    public init(appGroupId: String? = nil) {
        let containerUrl: URL
        if let appGroupId = appGroupId, let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            containerUrl = groupUrl
        } else {
            containerUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        self.spool = FileSpool(containerUrl: containerUrl)
    }

    public func getPendingDeliveries() -> [NativeDelivery] {
        return spool.getPendingDeliveries().map { toNativeDelivery($0) }
    }

    public func claimDelivery(deliveryId: String, leaseDurationSeconds: Int64) throws -> NativeClaim {
        let claim = try spool.claimDelivery(deliveryId: deliveryId, leaseDurationSeconds: Double(leaseDurationSeconds))
        return NativeClaim(
            claimId: claim.claimId,
            deliveryId: claim.deliveryId,
            delivery: toNativeDelivery(claim.delivery),
            claimedAtUtc: claim.claimedAtUtc,
            expiresAtUtc: claim.expiresAtUtc
        )
    }

    public func claimNextDelivery(leaseDurationSeconds: Int64) throws -> NativeClaim? {
        let pending = spool.getPendingDeliveries()
        guard let first = pending.first else { return nil }
        return try claimDelivery(deliveryId: first.deliveryId, leaseDurationSeconds: leaseDurationSeconds)
    }

    public func acknowledgeClaim(claimId: String, deliveryId: String) throws {
        try spool.acknowledgeClaim(claimId: claimId, deliveryId: deliveryId)
    }

    public func releaseClaim(claimId: String, deliveryId: String, reason: String?) throws {
        try spool.releaseClaim(claimId: claimId, deliveryId: deliveryId, reason: reason)
    }

    public func retryDelivery(deliveryId: String) {
        // Automatically retried when lease expires
    }

    public func inspectInbox() -> NativeHealth {
        let pending = spool.getPendingDeliveries()
        return NativeHealth(
            pendingCount: Int64(pending.count),
            claimedCount: 0,
            quarantinedCount: 0,
            totalStorageBytes: 0,
            issues: []
        )
    }

    public func cleanupInbox(maxAgeSeconds: Int64) -> NativeCleanupResult {
        let (count, bytes) = spool.cleanup(maxAgeSeconds: Double(maxAgeSeconds))
        return NativeCleanupResult(
            deletedDeliveriesCount: Int64(count),
            reclaimedBytes: bytes
        )
    }

    public func getPayloadPath(deliveryId: String, itemId: String) throws -> String {
        return try spool.getPayloadUrl(deliveryId: deliveryId, itemId: itemId).path
    }

    private func toNativeDelivery(_ d: SpoolDelivery) -> NativeDelivery {
        return NativeDelivery(
            deliveryId: d.deliveryId,
            receivedAtUtc: d.receivedAtUtc,
            platform: d.platform,
            state: d.state,
            attempt: Int64(d.attempt),
            items: d.items.map { toNativeItem($0) },
            text: d.text,
            subject: d.subject,
            source: d.source
        )
    }

    private func toNativeItem(_ i: SpoolItem) -> NativeItem {
        return NativeItem(
            itemId: i.itemId,
            kind: i.kind,
            originalName: i.originalName,
            internalName: i.internalName,
            declaredMimeType: i.declaredMimeType,
            resolvedMimeType: i.resolvedMimeType,
            byteLength: i.byteLength
        )
    }
}
