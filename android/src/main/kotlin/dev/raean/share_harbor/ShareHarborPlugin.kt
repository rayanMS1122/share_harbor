package dev.raean.share_harbor

import dev.raean.share_harbor.core.NativeStorageCore
import dev.raean.share_harbor.generated.NativeClaim
import dev.raean.share_harbor.generated.NativeCleanupResult
import dev.raean.share_harbor.generated.NativeDelivery
import dev.raean.share_harbor.generated.NativeHealth
import dev.raean.share_harbor.generated.ShareHarborHostApi
import io.flutter.embedding.engine.plugins.FlutterPlugin

class ShareHarborPlugin : FlutterPlugin, ShareHarborHostApi {

    private var storageCore: NativeStorageCore? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        storageCore = NativeStorageCore(context)
        ShareHarborHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ShareHarborHostApi.setUp(binding.binaryMessenger, null)
        storageCore = null
    }

    override fun getPendingDeliveries(): List<NativeDelivery> {
        return storageCore?.getPendingDeliveries() ?: emptyList()
    }

    override fun claimDelivery(deliveryId: String, leaseDurationSeconds: Long): NativeClaim {
        return storageCore?.claimDelivery(deliveryId, leaseDurationSeconds)
            ?: throw IllegalStateException("Storage core not initialized")
    }

    override fun claimNextDelivery(leaseDurationSeconds: Long): NativeClaim? {
        return storageCore?.claimNextDelivery(leaseDurationSeconds)
    }

    override fun acknowledgeClaim(claimId: String, deliveryId: String) {
        storageCore?.acknowledgeClaim(claimId, deliveryId)
    }

    override fun releaseClaim(claimId: String, deliveryId: String, reason: String?) {
        storageCore?.releaseClaim(claimId, deliveryId, reason)
    }

    override fun retryDelivery(deliveryId: String) {
        storageCore?.retryDelivery(deliveryId)
    }

    override fun inspectInbox(): NativeHealth {
        return storageCore?.inspectInbox()
            ?: NativeHealth(0, 0, 0, 0, listOf("Not initialized"))
    }

    override fun cleanupInbox(maxAgeSeconds: Long): NativeCleanupResult {
        return storageCore?.cleanupInbox(maxAgeSeconds)
            ?: NativeCleanupResult(0, 0)
    }

    override fun getPayloadPath(deliveryId: String, itemId: String): String {
        return storageCore?.getPayloadPath(deliveryId, itemId) ?: ""
    }
}
