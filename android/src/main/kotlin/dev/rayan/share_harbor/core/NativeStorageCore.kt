package dev.rayan.share_harbor.core

import android.content.Context
import dev.rayan.share_harbor.generated.NativeClaim
import dev.rayan.share_harbor.generated.NativeCleanupResult
import dev.rayan.share_harbor.generated.NativeDelivery
import dev.rayan.share_harbor.generated.NativeHealth
import dev.rayan.share_harbor.generated.NativeItem
import java.io.File

class NativeStorageCore(context: Context) {

    val spool = FileSpool(context.filesDir)

    fun getPendingDeliveries(): List<NativeDelivery> {
        val pending = spool.getPendingDeliveries()
        return pending.map { toNativeDelivery(it) }
    }

    fun claimDelivery(deliveryId: String, leaseDurationSeconds: Long): NativeClaim {
        val claim = spool.claimDelivery(deliveryId, leaseDurationSeconds)
        return NativeClaim(
            claimId = claim.claimId,
            deliveryId = claim.deliveryId,
            delivery = toNativeDelivery(claim.delivery),
            claimedAtUtc = claim.claimedAtUtc,
            expiresAtUtc = claim.expiresAtUtc
        )
    }

    fun claimNextDelivery(leaseDurationSeconds: Long): NativeClaim? {
        val pending = spool.getPendingDeliveries()
        if (pending.isEmpty()) return null
        return claimDelivery(pending.first().deliveryId, leaseDurationSeconds)
    }

    fun acknowledgeClaim(claimId: String, deliveryId: String) {
        spool.acknowledgeClaim(claimId, deliveryId)
    }

    fun releaseClaim(claimId: String, deliveryId: String, reason: String?) {
        spool.releaseClaim(claimId, deliveryId, reason)
    }

    fun retryDelivery(deliveryId: String) {
    }

    fun inspectInbox(): NativeHealth {
        val pending = spool.getPendingDeliveries()
        val spoolDir = File(contextFilesDir(spool), "share_harbor/v1/deliveries")
        var totalBytes = 0L

        if (spoolDir.exists()) {
            totalBytes = spoolDir.walkTopDown().sumOf { it.length() }
        }

        return NativeHealth(
            pendingCount = pending.size.toLong(),
            claimedCount = 0L,
            quarantinedCount = 0L,
            totalStorageBytes = totalBytes,
            issues = emptyList()
        )
    }

    fun cleanupInbox(maxAgeSeconds: Long): NativeCleanupResult {
        val (deletedCount, reclaimedBytes) = spool.cleanup(maxAgeSeconds)
        return NativeCleanupResult(
            deletedDeliveriesCount = deletedCount.toLong(),
            reclaimedBytes = reclaimedBytes
        )
    }

    fun getPayloadPath(deliveryId: String, itemId: String): String {
        return spool.getPayloadFile(deliveryId, itemId).absolutePath
    }

    private fun contextFilesDir(spool: FileSpool): File {
        return spool.getPendingDeliveries().let {
            File(System.getProperty("user.dir") ?: "/")
        }
    }

    private fun toNativeDelivery(d: SpoolDelivery): NativeDelivery {
        return NativeDelivery(
            deliveryId = d.deliveryId,
            receivedAtUtc = d.receivedAtUtc,
            platform = d.platform,
            state = d.state,
            attempt = d.attempt.toLong(),
            items = d.items.map { toNativeItem(it) },
            text = d.text,
            subject = d.subject,
            source = d.source
        )
    }

    private fun toNativeItem(i: SpoolItem): NativeItem {
        return NativeItem(
            itemId = i.itemId,
            kind = i.kind,
            originalName = i.originalName,
            internalName = i.internalName,
            declaredMimeType = i.declaredMimeType,
            resolvedMimeType = i.resolvedMimeType,
            byteLength = i.byteLength
        )
    }
}
