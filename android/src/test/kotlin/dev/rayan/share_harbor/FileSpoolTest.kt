package dev.rayan.share_harbor

import dev.rayan.share_harbor.core.FileSpool
import dev.rayan.share_harbor.core.SpoolItem
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream

class FileSpoolTest {

    @Rule
    @JvmField
    val tempFolder = TemporaryFolder()

    private lateinit var spool: FileSpool

    @Before
    fun setUp() {
        if (tempFolder.root == null || !tempFolder.root.exists()) {
            tempFolder.create()
        }
        spool = FileSpool(tempFolder.root)
    }

    @Test
    fun testCommitAndGetPendingDelivery() {
        val item = SpoolItem(
            itemId = "item-test-1",
            kind = "image",
            originalName = "test.png",
            internalName = "item-test-1.payload",
            declaredMimeType = "image/png",
            resolvedMimeType = "image/png",
            byteLength = 100
        )
        val stream = ByteArrayInputStream("test image content".toByteArray())

        val committed = spool.commitDelivery(
            items = listOf(Pair(item, stream)),
            text = "Shared caption",
            subject = "Subject",
            source = "com.test.app"
        )

        assertNotNull(committed.deliveryId)
        assertEquals("ready", committed.state)

        val pending = spool.getPendingDeliveries()
        assertEquals(1, pending.size)
        assertEquals(committed.deliveryId, pending[0].deliveryId)
        assertEquals("Shared caption", pending[0].text)
    }

    @Test
    fun testClaimAndAcknowledgeDelivery() {
        val item = SpoolItem(
            itemId = "item-test-2",
            kind = "text",
            originalName = null,
            internalName = "item-test-2.payload",
            declaredMimeType = "text/plain",
            resolvedMimeType = "text/plain",
            byteLength = 50
        )
        val stream = ByteArrayInputStream("hello world".toByteArray())

        val committed = spool.commitDelivery(
            items = listOf(Pair(item, stream)),
            text = "hello world",
            subject = null,
            source = null
        )

        val claim = spool.claimDelivery(committed.deliveryId, 300)
        assertNotNull(claim.claimId)
        assertEquals("claimed", claim.delivery.state)

        val pendingAfterClaim = spool.getPendingDeliveries()
        assertTrue(pendingAfterClaim.isEmpty())

        spool.acknowledgeClaim(claim.claimId, claim.deliveryId)
        val pendingAfterAck = spool.getPendingDeliveries()
        assertTrue(pendingAfterAck.isEmpty())
    }
}
