package dev.rayan.share_harbor.core

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

data class SpoolItem(
    val itemId: String,
    val kind: String,
    val originalName: String?,
    val internalName: String,
    val declaredMimeType: String?,
    val resolvedMimeType: String?,
    val byteLength: Long
)

data class SpoolDelivery(
    val deliveryId: String,
    val receivedAtUtc: String,
    val platform: String,
    val state: String,
    val attempt: Int,
    val items: List<SpoolItem>,
    val text: String?,
    val subject: String?,
    val source: String?
)

data class SpoolClaim(
    val claimId: String,
    val deliveryId: String,
    val delivery: SpoolDelivery,
    val claimedAtUtc: String,
    val expiresAtUtc: String
)

class FileSpool(private val rootDir: File) {

    private val spoolVersionDir = File(rootDir, "share_harbor/v1")
    private val deliveriesDir = File(spoolVersionDir, "deliveries")
    private val lockFile = File(spoolVersionDir, "locks/spool.lock")
    private val lockManager = FileLockManager(lockFile)

    init {
        if (!deliveriesDir.exists()) {
            deliveriesDir.mkdirs()
        }
        performStartupCleanup()
    }

    private fun getIsoUtcTimestamp(date: Date = Date()): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(date)
    }

    fun commitDelivery(
        items: List<Pair<SpoolItem, InputStream>>,
        text: String?,
        subject: String?,
        source: String?,
        maxItemSizeBytes: Long? = null,
        maxDeliverySizeBytes: Long? = null
    ): SpoolDelivery {
        return lockManager.withLock {
            val deliveryId = UUID.randomUUID().toString()
            val deliveryFolder = File(deliveriesDir, deliveryId)
            val itemsFolder = File(deliveryFolder, "items")
            itemsFolder.mkdirs()

            var totalDeliveryBytes = 0L
            val committedItems = mutableListOf<SpoolItem>()

            for ((itemMeta, inputStream) in items) {
                if (maxItemSizeBytes != null && itemMeta.byteLength > maxItemSizeBytes) {
                    deliveryFolder.deleteRecursively()
                    throw IllegalArgumentException("Item size ${itemMeta.byteLength} exceeds max allowed $maxItemSizeBytes")
                }

                val partialFile = File(itemsFolder, "${itemMeta.itemId}.partial")
                val payloadFile = File(itemsFolder, "${itemMeta.itemId}.payload")

                val outputStream = FileOutputStream(partialFile)
                val buffer = ByteArray(8192)
                var bytesRead: Int
                var itemBytesWritten = 0L

                try {
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        outputStream.write(buffer, 0, bytesRead)
                        itemBytesWritten += bytesRead
                        totalDeliveryBytes += bytesRead

                        if (maxItemSizeBytes != null && itemBytesWritten > maxItemSizeBytes) {
                            throw IllegalArgumentException("Item streaming exceeded quota $maxItemSizeBytes")
                        }
                        if (maxDeliverySizeBytes != null && totalDeliveryBytes > maxDeliverySizeBytes) {
                            throw IllegalArgumentException("Delivery streaming exceeded quota $maxDeliverySizeBytes")
                        }
                    }
                    outputStream.flush()
                    try {
                        outputStream.fd.sync()
                    } catch (_: Exception) {}
                } finally {
                    outputStream.close()
                    inputStream.close()
                }

                if (payloadFile.exists()) payloadFile.delete()
                if (!partialFile.renameTo(payloadFile)) {
                    partialFile.copyTo(payloadFile, overwrite = true)
                    partialFile.delete()
                }

                committedItems.add(itemMeta.copy(byteLength = itemBytesWritten))
            }

            val delivery = SpoolDelivery(
                deliveryId = deliveryId,
                receivedAtUtc = getIsoUtcTimestamp(),
                platform = "android",
                state = "ready",
                attempt = 0,
                items = committedItems,
                text = text,
                subject = subject,
                source = source
            )

            val manifestTmp = File(deliveryFolder, "manifest.tmp")
            val manifestJson = File(deliveryFolder, "manifest.json")
            manifestTmp.writeText(serializeDelivery(delivery))
            if (manifestJson.exists()) manifestJson.delete()
            if (!manifestTmp.renameTo(manifestJson)) {
                manifestTmp.copyTo(manifestJson, overwrite = true)
                manifestTmp.delete()
            }

            val readyMarker = File(deliveryFolder, "ready.marker")
            readyMarker.createNewFile()

            delivery
        }
    }

    fun getPendingDeliveries(): List<SpoolDelivery> {
        return lockManager.withLock {
            performStartupCleanup()
            val result = mutableListOf<SpoolDelivery>()

            deliveriesDir.listFiles()?.forEach { folder ->
                if (folder.isDirectory) {
                    val readyMarker = File(folder, "ready.marker")
                    val ackMarker = File(folder, "ack.marker")
                    val manifestJson = File(folder, "manifest.json")

                    if (readyMarker.exists() && !ackMarker.exists() && manifestJson.exists()) {
                        val claimJson = File(folder, "claim.json")
                        var isClaimed = false
                        if (claimJson.exists()) {
                            try {
                                val claimObj = JSONObject(claimJson.readText())
                                val expiresAt = claimObj.getString("expiresAtUtc")
                                val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
                                sdf.timeZone = TimeZone.getTimeZone("UTC")
                                val expireDate = sdf.parse(expiresAt)
                                if (expireDate != null && Date().before(expireDate)) {
                                    isClaimed = true
                                } else {
                                    claimJson.delete()
                                }
                            } catch (_: Exception) {
                                claimJson.delete()
                            }
                        }

                        if (!isClaimed) {
                            try {
                                val delivery = parseDelivery(manifestJson.readText())
                                result.add(delivery)
                            } catch (_: Exception) {}
                        }
                    }
                }
            }

            result.sortedBy { it.receivedAtUtc }
        }
    }

    fun claimDelivery(deliveryId: String, leaseDurationSeconds: Long): SpoolClaim {
        return lockManager.withLock {
            val folder = File(deliveriesDir, deliveryId)
            val readyMarker = File(folder, "ready.marker")
            val ackMarker = File(folder, "ack.marker")
            val manifestJson = File(folder, "manifest.json")

            if (!folder.exists() || !readyMarker.exists() || ackMarker.exists() || !manifestJson.exists()) {
                throw IllegalArgumentException("Delivery $deliveryId not found or not available for claim")
            }

            val claimJsonFile = File(folder, "claim.json")
            if (claimJsonFile.exists()) {
                val claimObj = JSONObject(claimJsonFile.readText())
                val expiresAt = claimObj.getString("expiresAtUtc")
                val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
                sdf.timeZone = TimeZone.getTimeZone("UTC")
                val expireDate = sdf.parse(expiresAt)
                if (expireDate != null && Date().before(expireDate)) {
                    throw IllegalStateException("Delivery $deliveryId is already claimed")
                }
            }

            val delivery = parseDelivery(manifestJson.readText())
            val claimId = UUID.randomUUID().toString()
            val claimedAt = Date()
            val expiresAt = Date(claimedAt.time + leaseDurationSeconds * 1000)

            val claim = SpoolClaim(
                claimId = claimId,
                deliveryId = deliveryId,
                delivery = delivery.copy(state = "claimed"),
                claimedAtUtc = getIsoUtcTimestamp(claimedAt),
                expiresAtUtc = getIsoUtcTimestamp(expiresAt)
            )

            val claimObj = JSONObject().apply {
                put("claimId", claim.claimId)
                put("deliveryId", claim.deliveryId)
                put("claimedAtUtc", claim.claimedAtUtc)
                put("expiresAtUtc", claim.expiresAtUtc)
            }

            claimJsonFile.writeText(claimObj.toString())
            claim
        }
    }

    fun acknowledgeClaim(claimId: String, deliveryId: String) {
        lockManager.withLock {
            val folder = File(deliveriesDir, deliveryId)
            if (folder.exists()) {
                val ackMarker = File(folder, "ack.marker")
                ackMarker.createNewFile()
                folder.deleteRecursively()
            }
        }
    }

    fun releaseClaim(claimId: String, deliveryId: String, reason: String?) {
        lockManager.withLock {
            val folder = File(deliveriesDir, deliveryId)
            if (folder.exists()) {
                val claimJsonFile = File(folder, "claim.json")
                if (claimJsonFile.exists()) {
                    claimJsonFile.delete()
                }
            }
        }
    }

    fun getPayloadFile(deliveryId: String, itemId: String): File {
        val payloadFile = File(deliveriesDir, "$deliveryId/items/$itemId.payload")
        if (!payloadFile.exists()) {
            throw IllegalArgumentException("Payload file not found for item $itemId in delivery $deliveryId")
        }
        return payloadFile
    }

    fun cleanup(maxAgeSeconds: Long): Pair<Int, Long> {
        return lockManager.withLock {
            var deletedCount = 0
            var reclaimedBytes = 0L
            val cutoff = System.currentTimeMillis() - maxAgeSeconds * 1000

            deliveriesDir.listFiles()?.forEach { folder ->
                if (folder.isDirectory && folder.lastModified() < cutoff) {
                    reclaimedBytes += folder.walkTopDown().sumOf { it.length() }
                    folder.deleteRecursively()
                    deletedCount++
                }
            }
            Pair(deletedCount, reclaimedBytes)
        }
    }

    private fun performStartupCleanup() {
        deliveriesDir.listFiles()?.forEach { folder ->
            if (folder.isDirectory) {
                val readyMarker = File(folder, "ready.marker")
                val ackMarker = File(folder, "ack.marker")
                if (ackMarker.exists() || !readyMarker.exists()) {
                    folder.deleteRecursively()
                }
            }
        }
    }

    private fun serializeDelivery(d: SpoolDelivery): String {
        val obj = JSONObject()
        obj.put("deliveryId", d.deliveryId)
        obj.put("receivedAtUtc", d.receivedAtUtc)
        obj.put("platform", d.platform)
        obj.put("state", d.state)
        obj.put("attempt", d.attempt)
        obj.put("text", d.text)
        obj.put("subject", d.subject)
        obj.put("source", d.source)

        val itemsArr = JSONArray()
        d.items.forEach { item ->
            val itemObj = JSONObject()
            itemObj.put("itemId", item.itemId)
            itemObj.put("kind", item.kind)
            itemObj.put("originalName", item.originalName)
            itemObj.put("internalName", item.internalName)
            itemObj.put("declaredMimeType", item.declaredMimeType)
            itemObj.put("resolvedMimeType", item.resolvedMimeType)
            itemObj.put("byteLength", item.byteLength)
            itemsArr.put(itemObj)
        }
        obj.put("items", itemsArr)
        return obj.toString()
    }

    private fun parseDelivery(jsonStr: String): SpoolDelivery {
        val obj = JSONObject(jsonStr)
        val itemsArr = obj.getJSONArray("items")
        val items = mutableListOf<SpoolItem>()

        for (i in 0 until itemsArr.length()) {
            val itemObj = itemsArr.getJSONObject(i)
            items.add(
                SpoolItem(
                    itemId = itemObj.getString("itemId"),
                    kind = itemObj.getString("kind"),
                    originalName = if (itemObj.has("originalName") && !itemObj.isNull("originalName")) itemObj.getString("originalName") else null,
                    internalName = itemObj.getString("internalName"),
                    declaredMimeType = if (itemObj.has("declaredMimeType") && !itemObj.isNull("declaredMimeType")) itemObj.getString("declaredMimeType") else null,
                    resolvedMimeType = if (itemObj.has("resolvedMimeType") && !itemObj.isNull("resolvedMimeType")) itemObj.getString("resolvedMimeType") else null,
                    byteLength = itemObj.getLong("byteLength")
                )
            )
        }

        return SpoolDelivery(
            deliveryId = obj.getString("deliveryId"),
            receivedAtUtc = obj.getString("receivedAtUtc"),
            platform = obj.getString("platform"),
            state = obj.getString("state"),
            attempt = obj.getInt("attempt"),
            items = items,
            text = if (obj.has("text") && !obj.isNull("text")) obj.getString("text") else null,
            subject = if (obj.has("subject") && !obj.isNull("subject")) obj.getString("subject") else null,
            source = if (obj.has("source") && !obj.isNull("source")) obj.getString("source") else null
        )
    }
}
